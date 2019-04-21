#include "engine.h"
#include <QDateTime>
#include <QTextStream>
#include <QSettings>
#include <QStandardPaths>
#include <unistd.h>
#include "globals.h"
#include "fileworker.h"
#include "statfileinfo.h"

Engine::Engine(QObject *parent) :
    QObject(parent),
    m_clipboardContainsCopy(false),
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
    m_fileWorker->cancel(); // ask the background thread to exit its loop
    // is this the way to force stop the worker thread?
    m_fileWorker->wait();   // wait until thread stops
    m_fileWorker->deleteLater();    // delete it
}

void Engine::deleteFiles(QStringList filenames)
{
    setProgress(0, "");
    m_fileWorker->startDeleteFiles(filenames);
}

void Engine::cutFiles(QStringList filenames)
{
    m_clipboardFiles = filenames;
    m_clipboardContainsCopy = false;
    emit clipboardCountChanged();
    emit clipboardContainsCopyChanged();
}

void Engine::copyFiles(QStringList filenames)
{
    // don't copy special files (chr/blk/fifo/sock)
    QMutableStringListIterator i(filenames);
    while (i.hasNext()) {
        QString filename = i.next();
        StatFileInfo info(filename);
        if (info.isSystem())
            i.remove();
    }

    m_clipboardFiles = filenames;
    m_clipboardContainsCopy = true;
    emit clipboardCountChanged();
    emit clipboardContainsCopyChanged();
}

QStringList Engine::listExistingFiles(QString destDirectory)
{
    if (m_clipboardFiles.isEmpty()) {
        return QStringList();
    }
    QDir dest(destDirectory);
    if (!dest.exists()) {
        return QStringList();
    }

    QStringList existingFiles;
    foreach (QString filename, m_clipboardFiles) {
        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());

        // source and dest filenames are the same? let pasteFiles() create a numbered copy for it.
        if (filename == newname) {
            continue;
        }

        // dest is under source? (directory) let pasteFiles() return an error.
        if (newname.startsWith(filename)) {
            return QStringList();
        }
        if (QFile::exists(newname)) {
            existingFiles.append(fileInfo.fileName());
        }
    }
    return existingFiles;
}

void Engine::pasteFiles(QString destDirectory)
{
    if (m_clipboardFiles.isEmpty()) {
        emit workerErrorOccurred(tr("No files to paste"), "");
        return;
    }

    setProgress(0, "");

    QDir dest(destDirectory);
    if (!dest.exists()) {
        emit workerErrorOccurred(tr("Destination does not exist"), destDirectory);
        return;
    }

    // validate that the files can be pasted
    foreach (QString filename, m_clipboardFiles) {
        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());

        // moving and source and dest filenames are the same?
        if (!m_clipboardContainsCopy && filename == newname) {
            emit workerErrorOccurred(tr("Cannot overwrite itself"), newname);
            return;
        }

        // dest is under source? (directory)
        if (newname.startsWith(filename) && newname != filename) {
            emit workerErrorOccurred(tr("Cannot move/copy to itself"), filename);
            return;
        }
    }

    QStringList files = m_clipboardFiles;
    m_clipboardFiles.clear();
    emit clipboardCountChanged();

    if (m_clipboardContainsCopy) {
        m_fileWorker->startCopyFiles(files, destDirectory);
        return;
    }

    m_fileWorker->startMoveFiles(files, destDirectory);
}

void Engine::cancel()
{
    m_fileWorker->cancel();
}

QString Engine::homeFolder() const
{
    return QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
}

static QStringList subdirs(const QString &dirname)
{
    QDir dir(dirname);
    if (!dir.exists())
        return QStringList();
    dir.setFilter(QDir::AllDirs | QDir::NoDotAndDotDot);
    QStringList list = dir.entryList();
    QStringList abslist;
    foreach (QString relpath, list) {
        abslist.append(dir.absoluteFilePath(relpath));
    }
    return abslist;
}

QString Engine::sdcardPath() const
{
    // from SailfishOS 2.2.0 onwards, "/media/sdcard" is
    // a symbolic link instead of a folder. In that case, follow the link
    // to the actual folder.
    QString sdcardFolder = "/media/sdcard";
    QFileInfo fileinfo(sdcardFolder);
    if (fileinfo.isSymLink()) {
        sdcardFolder = fileinfo.symLinkTarget();
    }

    // get sdcard dir candidates for "/media/sdcard" (or its symlink target)
    QStringList sdcards = subdirs(sdcardFolder);

    // some users may have a symlink from "/media/sdcard/nemo" (not from "/media/sdcard"), which means
    // no sdcards are found, so also get candidates directly from "/run/media/nemo" for those users
    if (sdcardFolder != "/run/media/nemo")
        sdcards.append(subdirs("/run/media/nemo"));

    if (sdcards.isEmpty())
        return QString();

    // remove all directories which are not mount points
    QStringList mps = mountPoints();
    QMutableStringListIterator i(sdcards);
    while (i.hasNext()) {
        QString dirname = i.next();
        // is it a mount point?
        if (!mps.contains(dirname))
            i.remove();
    }

    // none found, return empty string
    if (sdcards.isEmpty())
        return QString();

    // if only one directory, then return it
    if (sdcards.count() == 1)
        return sdcards.first();

    // if multiple directories, then return the sdcard parent folder
    // this works for SFOS<2.2 and SFOS>=2.2, because "/media/sdcard" should exist in both
    // as a folder or symlink
    return "/media/sdcard";
}

QString Engine::androidSdcardPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::HomeLocation)+"/android_storage";
}

bool Engine::exists(QString filename)
{
    if (filename.isEmpty())
        return false;

    return QFile::exists(filename);
}

QStringList Engine::diskSpace(QString path)
{
    if (path.isEmpty())
        return QStringList();

    // return no disk space for sdcard parent directory
    if (path == "/media/sdcard")
        return QStringList();

    // run df for the given path to get disk space
    QString blockSize = "--block-size=1024";
    QString result = execute("/bin/df", QStringList() << blockSize << path, false);
    if (result.isEmpty())
        return QStringList();

    // split result to lines
    QStringList lines = result.split(QRegExp("[\n\r]"));
    if (lines.count() < 2)
        return QStringList();

    // get first line and its columns
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
    int maxSize = 10240;
    int maxBinSize = 2048;

    // check existence
    StatFileInfo fileInfo(filename);
    if (!fileInfo.exists()) {
        if (!fileInfo.isSymLink())
            return makeStringList(tr("File does not exist") + "\n" + filename);
        else
            return makeStringList(tr("Broken symbolic link") + "\n" + filename);
    }

    // don't read unsafe system files
    if (!fileInfo.isSafeToRead()) {
        return makeStringList(tr("Cannot read this type of file") + "\n" + filename);
    }

    // check permissions
    QFileInfo info(filename);
    if (!info.isReadable())
        return makeStringList(tr("No permission to read the file") + "\n" + filename);

    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
        return makeStringList(tr("Error reading file") + "\n" + filename);

    // read start of file
    char buffer[maxSize+1];
    qint64 readSize = file.read(buffer, maxSize);
    if (readSize < 0)
        return makeStringList(tr("Error reading file") + "\n" + filename);

    if (readSize == 0)
        return makeStringList(tr("Empty file"));

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
        QString out8 = createHexDump(buffer, readSize, 8);
        QString out16 = createHexDump(buffer, readSize, 16);
        QString msg = "";

        if (!atEnd) {
            msg = tr("--- Binary file preview clipped at %1 kB ---").arg(maxBinSize/1024);
            msg = tr("--- Binary file preview clipped at %1 kB ---").arg(maxBinSize/1024);
        }

        return QStringList() << msg << out8 << out16;
    }

    // read lines to a string list and join
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
        msg = tr("--- Text file preview clipped at %1 kB ---").arg(maxSize/1024);

    return makeStringList(msg, lines.join("\n"));
}

QString Engine::mkdir(QString path, QString name)
{
    QDir dir(path);

    if (!dir.mkdir(name)) {
        QFileInfo info(path);
        if (!info.isWritable())
            return tr("No permissions to create %1").arg(name);

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
        errorMessage = tr("Cannot rename %1").arg(oldName) + "\n" + file.errorString();
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
        return tr("Cannot change permissions") + "\n" + file.errorString();

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

QStringList Engine::mountPoints() const
{
    // read /proc/mounts and return all mount points for the filesystem
    QFile file("/proc/mounts");
    if (!file.open(QFile::ReadOnly | QFile::Text))
        return QStringList();

    QTextStream in(&file);
    QString result = in.readAll();

    // split result to lines
    QStringList lines = result.split(QRegExp("[\n\r]"));

    // get columns
    QStringList dirs;
    foreach (QString line, lines) {
        QStringList columns = line.split(QRegExp("\\s+"), QString::SkipEmptyParts);
        if (columns.count() < 6) // sanity check
            continue;

        QString dir = columns.at(1);
        dirs.append(dir);
    }

    return dirs;
}

QString Engine::createHexDump(char *buffer, int size, int bytesPerLine)
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

QStringList Engine::makeStringList(QString msg, QString str)
{
    QStringList list;
    list << msg << str << str;
    return list;
}
