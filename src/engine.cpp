#include "engine.h"
#include <QDateTime>
#include <QTextStream>
#include <QSettings>
#include "globals.h"
#include "fileworker.h"

Engine::Engine(QObject *parent) :
    QObject(parent),
    m_clipboardCut(true),
    m_progress(0)
{
    m_fileWorker = new FileWorker;

    // update progress property when worker progresses
    connect(m_fileWorker, SIGNAL(progressChanged(int, QString)),
            this, SLOT(setProgress(int, QString)));

    // pass worker end signals to QML
    connect(m_fileWorker, SIGNAL(done()), this, SIGNAL(workerDone()));
    connect(m_fileWorker, SIGNAL(errorOccurred(QString, QString)),
            this, SIGNAL(workerErrorOccurred(QString, QString)));
    connect(m_fileWorker, SIGNAL(fileDeleted(QString)), this, SIGNAL(fileDeleted(QString)));
}

Engine::~Engine()
{
    // is this the way to force stop the worker thread?
    m_fileWorker->cancel(); // stop possibly running background thread
    m_fileWorker->wait();   // wait until thread stops
    delete m_fileWorker;    // delete it
}

void Engine::deleteFiles(QStringList filenames)
{
    setProgress(0, "");
    m_fileWorker->startDeleteFiles(filenames);
}

void Engine::cutFiles(QStringList filenames)
{
    m_clipboardFiles = filenames;
    m_clipboardCut = true;
    emit clipboardCountChanged();
    emit clipboardCutChanged();
}

void Engine::copyFiles(QStringList filenames)
{
    m_clipboardFiles = filenames;
    m_clipboardCut = false;
    emit clipboardCountChanged();
    emit clipboardCutChanged();
}

void Engine::pasteFiles(QString destDirectory)
{
    if (m_clipboardFiles.isEmpty()) {
        emit workerErrorOccurred("No files to paste", "");
        return;
    }

    QStringList files = m_clipboardFiles;
    setProgress(0, "");

    QDir dest(destDirectory);
    if (!dest.exists()) {
        emit workerErrorOccurred(tr("Destination does not exist"), destDirectory);
        return;
    }

    foreach (QString filename, files) {
        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());

        // source and dest filenames are the same?
        if (filename == newname) {
            emit workerErrorOccurred(tr("Can't overwrite itself"), newname);
            return;
        }

        // dest is under source? (directory)
        if (newname.startsWith(filename)) {
            emit workerErrorOccurred(tr("Can't move/copy to itself"), filename);
            return;
        }
    }

    m_clipboardFiles.clear();
    emit clipboardCountChanged();

    if (m_clipboardCut) {
        m_fileWorker->startMoveFiles(files, destDirectory);
        return;
    }

    m_fileWorker->startCopyFiles(files, destDirectory);
}

void Engine::cancel()
{
    m_fileWorker->cancel();
}

bool Engine::exists(QString filename)
{
    return QFile::exists(filename);
}

QStringList Engine::diskSpace(QString path)
{
    // run df to get disk space
    QString blockSize = "--block-size=1024";
    QString result = execute("/bin/df", QStringList() << blockSize << path, false);
    if (result.isEmpty())
        return QStringList();

    // parse result
    QStringList lines = result.split(QRegExp("[\n\r]"));
    if (lines.count() < 2)
        return QStringList();

    QString line = lines.at(1);
    QStringList columns = line.split(QRegExp("\\s+"), QString::SkipEmptyParts);
    if (columns.count() < 5)
        return QStringList();

    QString totalString = columns.at(1);
    QString usedString = columns.at(2);
    QString percentageString = columns.at(4);
    qint64 total = totalString.toLongLong() * 1024LL;
    qint64 used = usedString.toLongLong() * 1024LL;

    return QStringList() << percentageString << filesizeToString(used)+"/"+filesizeToString(total);
}

QStringList Engine::readFile(QString filename)
{
    int maxLines = 1000;
    int maxSize = 10000;
    int maxBinSize = 2048;

    // check permissions
    if (access(filename, R_OK) == -1)
        return stringListify(tr("No permission to read the file\n%1").arg(filename));

    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
        return stringListify(tr("Error reading file\n%1").arg(filename));

    // read start of file
    char buffer[maxSize+1];
    qint64 readSize = file.read(buffer, maxSize);
    if (readSize < 0)
        return stringListify(tr("Error reading file\n%1").arg(filename));

    if (readSize == 0)
        return stringListify(tr("Empty file"));

    bool atEnd = file.atEnd();
    file.close();

    // detect binary or text file, it is binary if it contains zeros
    bool isText = true;
    for (int i = 0; i < readSize; ++i) {
        if (buffer[i] == 0) {
            isText = false;
            break;
        }
    }

    // binary output
    if (!isText) {
        // two different line widths
        if (readSize > maxBinSize) {
            readSize = maxBinSize;
            atEnd = false;
        }
        QString out8 = dumpHex(buffer, readSize, 8);
        QString out16 = dumpHex(buffer, readSize, 16);
        QString msg = "";

        if (!atEnd) {
            msg = tr("--- Binary file preview clipped at %1 kB ---").arg(maxBinSize/1000);
            msg = tr("--- Binary file preview clipped at %1 kB ---").arg(maxBinSize/1000);
        }

        return QStringList() << msg << out8 << out16;
    }

    // read lines to a list and join
    QByteArray ba(buffer, readSize);
    QTextStream in(&ba);
    QStringList lines;
    int lineCount = 0;
    while (!in.atEnd() && lineCount < maxLines) {
        QString line = in.readLine();
        lines.append(line);
        lineCount++;
    }

    QString msg = "";
    if (lineCount == maxLines)
        msg = tr("--- Text file preview clipped at %1 lines ---").arg(maxLines);
    else if (!atEnd)
        msg = tr("--- Text file preview clipped at %1 kB ---").arg(maxSize/1000);

    return stringListify(msg, lines.join("\n"));
}

QString Engine::mkdir(QString path, QString name)
{
    QDir dir(path);

    if (!dir.mkdir(name)) {
        if (access(dir.absolutePath(), W_OK) == -1)
            return tr("Cannot create folder %1\nPermission denied").arg(name);

        return tr("Cannot create folder %1").arg(name);
    }

    return QString();
}

QStringList Engine::rename(QString fullOldFilename, QString newName)
{
    QFile file(fullOldFilename);
    QFileInfo fileInfo(fullOldFilename);
    QDir dir = fileInfo.absoluteDir();
    QString fullNewFilename = dir.absoluteFilePath(newName);

    QString errorMessage;
    if (!file.rename(fullNewFilename)) {
        QString oldName = fileInfo.fileName();
        errorMessage = tr("Cannot rename %1\n%2").arg(oldName).arg(file.errorString());
    }

    return QStringList() << fullNewFilename << errorMessage;
}

QString Engine::chmod(QString path,
                      bool ownerRead, bool ownerWrite, bool ownerExecute,
                      bool groupRead, bool groupWrite, bool groupExecute,
                      bool othersRead, bool othersWrite, bool othersExecute)
{
    QFile file(path);
    QFileDevice::Permissions p;
    if (ownerRead) p |= QFileDevice::ReadOwner;
    if (ownerWrite) p |= QFileDevice::WriteOwner;
    if (ownerExecute) p |= QFileDevice::ExeOwner;
    if (groupRead) p |= QFileDevice::ReadGroup;
    if (groupWrite) p |= QFileDevice::WriteGroup;
    if (groupExecute) p |= QFileDevice::ExeGroup;
    if (othersRead) p |= QFileDevice::ReadOther;
    if (othersWrite) p |= QFileDevice::WriteOther;
    if (othersExecute) p |= QFileDevice::ExeOther;
    if (!file.setPermissions(p))
        return tr("Cannot change permissions\n%1").arg(file.errorString());

    return QString();
}

QString Engine::readSetting(QString key, QString defaultValue)
{
    QSettings settings;
    return settings.value(key, defaultValue).toString();
}

void Engine::writeSetting(QString key, QString value)
{
    QSettings settings;

    // do nothing if value didn't change
    if (settings.value(key) == value)
        return;

    settings.setValue(key, value);

    emit settingsChanged();
}

void Engine::setProgress(int progress, QString filename)
{
    m_progress = progress;
    m_progressFilename = filename;
    emit progressChanged();
    emit progressFilenameChanged();
}

QString Engine::dumpHex(char *buffer, int size, int bytesPerLine)
{
    QString out;
    QString ascDump;
    int i;
    for (i = 0; i < size; ++i) {
        if ((i % bytesPerLine) == 0) { // line change
            out += " "+ascDump+"\n"+
                    QString("%1").arg(QString::number(i, 16), 4, QLatin1Char('0'))+": ";
            ascDump.clear();
        }

        out += QString("%1").arg(QString::number((unsigned char)buffer[i], 16),
                                       2, QLatin1Char('0'))+" ";
        if (buffer[i] >= 32 && buffer[i] <= 126)
            ascDump += buffer[i];
        else
            ascDump += ".";
    }
    // write out remaining asc dump
    if ((i % bytesPerLine) > 0) {
        int emptyBytes = bytesPerLine - (i % bytesPerLine);
        for (int j = 0; j < emptyBytes; ++j) {
            out += "   ";
        }
    }
    out += " "+ascDump;

    return out;
}

QStringList Engine::stringListify(QString msg, QString str)
{
    QStringList list;
    list << msg << str << str;
    return list;
}
