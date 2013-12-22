#include "fileworker.h"
#include <QDateTime>
#include "globals.h"

FileWorker::FileWorker(QObject *parent) :
    QThread(parent),
    m_mode(DeleteMode),
    m_cancelled(KeepRunning)
{
}

FileWorker::~FileWorker()
{
}

void FileWorker::startDeleteFiles(QStringList filenames)
{
    if (isRunning()) {
        emit errorOccurred(tr("File operation already in progress"), "");
        return;
    }

    // basic validity check
    foreach (QString filename, filenames) {
        if (filename.isEmpty()) {
            emit errorOccurred(tr("Empty filename"), "");
            return;
        }
    }

    m_mode = DeleteMode;
    m_filenames = filenames;
    m_cancelled.storeRelease(KeepRunning);
    start();
}

void FileWorker::startCopyFiles(QStringList filenames, QString destDirectory)
{
    if (isRunning()) {
        emit errorOccurred(tr("File operation already in progress"), "");
        return;
    }

    // basic validity check
    foreach (QString filename, filenames) {
        if (filename.isEmpty()) {
            emit errorOccurred(tr("Empty filename"), "");
            return;
        }
    }

    m_mode = CopyMode;
    m_filenames = filenames;
    m_destDirectory = destDirectory;
    m_cancelled.storeRelease(KeepRunning);
    start();
}

void FileWorker::startMoveFiles(QStringList filenames, QString destDirectory)
{
    if (isRunning()) {
        emit errorOccurred(tr("File operation already in progress"), "");
        return;
    }

    // basic validity check
    foreach (QString filename, filenames) {
        if (filename.isEmpty()) {
            emit errorOccurred(tr("Empty filename"), "");
            return;
        }
    }

    m_mode = MoveMode;
    m_filenames = filenames;
    m_destDirectory = destDirectory;
    m_cancelled.storeRelease(KeepRunning);
    start();
}

void FileWorker::cancel()
{
    m_cancelled.storeRelease(Cancelled);
}

void FileWorker::run() Q_DECL_OVERRIDE
{
    switch (m_mode) {
    case DeleteMode:
        deleteFiles();
        break;

    case MoveMode:
    case CopyMode:
        copyOrMoveFiles();
        break;
    }
}

QString FileWorker::deleteFile(QString filename)
{
    QFileInfo info(filename);
    if (!info.exists())
        return tr("File not found");

    if (info.isDir()) {
        // this should be custom function to get better error reporting
        bool ok = QDir(info.absoluteFilePath()).removeRecursively();
        if (!ok)
            return tr("Directory remove failed");

    } else {
        QFile file(info.absoluteFilePath());
        bool ok = file.remove();
        if (!ok)
            return file.errorString();
    }
    return QString();
}

void FileWorker::deleteFiles()
{
    int fileIndex = 0;
    int fileCount = m_filenames.count();

    foreach (QString filename, m_filenames) {
        emit progressChanged(100 * fileIndex / fileCount, filename);

        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            emit done();
            return;
        }

        // delete file and stop if errors
        QString errMsg = deleteFile(filename);
        if (!errMsg.isEmpty()) {
            emit errorOccurred(errMsg, filename);
            return;
        }

        fileIndex++;
    }

    emit progressChanged(100, "");
    emit done();
}

void FileWorker::copyOrMoveFiles()
{
    int fileIndex = 0;
    int fileCount = m_filenames.count();

    QDir dest(m_destDirectory);
    foreach (QString filename, m_filenames) {
        emit progressChanged(100 * fileIndex / fileCount, filename);

        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            emit done();
            return;
        }

        // check destination does not exists, otherwise copy/move fails
        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());

        // move or copy and stop if errors
        QFile file(filename);
        if (m_mode == MoveMode) {
            if (!file.rename(newname)) {
                emit errorOccurred(file.errorString(), filename);
                return;
            }
        } else {
            if (fileInfo.isDir()) {
                QString errmsg = copyDirRecursively(filename, newname);
                if (!errmsg.isEmpty()) {
                    emit errorOccurred(errmsg, filename);
                    return;
                }
            } else {
                QString errmsg = copyOverwrite(filename, newname);
                if (!errmsg.isEmpty()) {
                    emit errorOccurred(errmsg, filename);
                    return;
                }
            }
        }

        fileIndex++;
    }

    emit progressChanged(100, "");
    emit done();
}

QString FileWorker::copyDirRecursively(QString srcDirectory, QString destDirectory)
{
    QDir srcDir(srcDirectory);
    if (!srcDir.exists())
        return tr("Source directory doesn't exist");

    QDir destDir(destDirectory);
    if (!destDir.exists()) {
        QDir d(destDir);
        d.cdUp();
        if (!d.mkdir(destDir.dirName()))
            return tr("Can't create target directory %1").arg(destDirectory);
    }

    QStringList names = srcDir.entryList(QDir::Files);
    for (int i = 0 ; i < names.count() ; ++i) {
        QString filename = names.at(i);
        QString spath = srcDir.absoluteFilePath(filename);
        QString dpath = destDir.absoluteFilePath(filename);
        QString errmsg = copyOverwrite(spath, dpath);
        if (!errmsg.isEmpty())
            return errmsg;
    }

    names = srcDir.entryList(QDir::NoDotAndDotDot | QDir::AllDirs);
    for (int i = 0 ; i < names.count() ; ++i) {
        QString filename = names.at(i);
        QString spath = srcDir.absoluteFilePath(filename);
        QString dpath = destDir.absoluteFilePath(filename);
        QString errmsg = copyDirRecursively(spath, dpath);
        if (!errmsg.isEmpty())
            return errmsg;
    }

    return QString();
}

QString FileWorker::copyOverwrite(QString src, QString dest)
{
    QFile dfile(dest);
    if (dfile.exists()) {
        if (!dfile.remove())
            return dfile.errorString();
    }

    QFile sfile(src);
    if (!sfile.copy(dest))
        return sfile.errorString();

    return QString();
}
