#include "fileworker.h"
#include <QDateTime>
#include "globals.h"

FileWorker::FileWorker(QObject *parent) :
    QThread(parent),
    m_mode(DeleteMode),
    m_cancelled(KeepRunning),
    m_progress(0)
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

    if (!validateFilenames(filenames))
        return;

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

    if (!validateFilenames(filenames))
        return;

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

    if (!validateFilenames(filenames))
        return;

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

void FileWorker::run()
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

bool FileWorker::validateFilenames(const QStringList &filenames)
{
    // basic validity check
    foreach (QString filename, filenames) {
        if (filename.isEmpty()) {
            emit errorOccurred(tr("Empty filename"), "");
            return false;
        }
    }
    return true;
}

QString FileWorker::deleteFile(QString filename)
{
    QFileInfo info(filename);
    if (!info.exists() && !info.isSymLink())
        return tr("File not found");

    if (info.isDir() && info.isSymLink()) {
        // only delete the link and do not remove recursively subfolders
        QFile file(info.absoluteFilePath());
        bool ok = file.remove();
        if (!ok)
            return file.errorString();

    } else if (info.isDir()) {
        // this should be custom function to get better error reporting
        bool ok = QDir(info.absoluteFilePath()).removeRecursively();
        if (!ok)
            return tr("Folder delete failed");

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
        m_progress = 100 * fileIndex / fileCount;
        emit progressChanged(m_progress, filename);

        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            emit errorOccurred(tr("Cancelled"), filename);
            return;
        }

        // delete file and stop if errors
        QString errMsg = deleteFile(filename);
        if (!errMsg.isEmpty()) {
            emit errorOccurred(errMsg, filename);
            return;
        }
        emit fileDeleted(filename);

        fileIndex++;
    }

    m_progress = 100;
    emit progressChanged(m_progress, "");
    emit done();
}

void FileWorker::copyOrMoveFiles()
{
    int fileIndex = 0;
    int fileCount = m_filenames.count();

    QDir dest(m_destDirectory);
    foreach (QString filename, m_filenames) {
        m_progress = 100 * fileIndex / fileCount;
        emit progressChanged(m_progress, filename);

        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            emit errorOccurred(tr("Cancelled"), filename);
            return;
        }

        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());

        // move or copy and stop if errors
        QFile file(filename);
        if (m_mode == MoveMode) {
            if (fileInfo.isSymLink()) {
                // move symlink by creating a new link and deleting the old one
                QFile targetFile(fileInfo.symLinkTarget());
                if (!targetFile.link(newname)) {
                    emit errorOccurred(targetFile.errorString(), filename);
                    return;
                }
                if (!file.remove()) {
                    emit errorOccurred(targetFile.errorString(), filename);
                    return;
                }

            } else if (!file.rename(newname)) {
                emit errorOccurred(file.errorString(), filename);
                return;
            }

        } else { // CopyMode
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

    m_progress = 100;
    emit progressChanged(m_progress, "");
    emit done();
}

QString FileWorker::copyDirRecursively(QString srcDirectory, QString destDirectory)
{
    QFileInfo srcInfo(srcDirectory);
    if (srcInfo.isSymLink()) {
        // copy dir symlink by creating a new link
        QFile targetFile(srcInfo.symLinkTarget());
        if (!targetFile.link(destDirectory))
            return targetFile.errorString();

        return QString();
    }

    QDir srcDir(srcDirectory);
    if (!srcDir.exists())
        return tr("Source folder doesn't exist");

    QDir destDir(destDirectory);
    if (!destDir.exists()) {
        QDir d(destDir);
        d.cdUp();
        if (!d.mkdir(destDir.dirName()))
            return tr("Can't create target folder %1").arg(destDirectory);
    }

    // copy files
    QStringList names = srcDir.entryList(QDir::Files);
    for (int i = 0 ; i < names.count() ; ++i) {
        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled)
            return tr("Cancelled");

        QString filename = names.at(i);
        emit progressChanged(m_progress, filename);
        QString spath = srcDir.absoluteFilePath(filename);
        QString dpath = destDir.absoluteFilePath(filename);
        QString errmsg = copyOverwrite(spath, dpath);
        if (!errmsg.isEmpty())
            return errmsg;
    }

    // copy dirs
    names = srcDir.entryList(QDir::NoDotAndDotDot | QDir::AllDirs);
    for (int i = 0 ; i < names.count() ; ++i) {
        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled)
            return tr("Cancelled");

        QString filename = names.at(i);
        emit progressChanged(m_progress, filename);
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
    // delete destination if it exists
    QFile dfile(dest);
    if (dfile.exists()) {
        if (!dfile.remove())
            return dfile.errorString();
    }

    QFileInfo fileInfo(src);
    if (fileInfo.isSymLink()) {
        // copy symlink by creating a new link
        QFile targetFile(fileInfo.symLinkTarget());
        if (!targetFile.link(dest))
            return targetFile.errorString();

        return QString();
    }

    // normal file copy
    QFile sfile(src);
    if (!sfile.copy(dest))
        return sfile.errorString();

    return QString();
}
