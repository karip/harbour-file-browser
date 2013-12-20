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

bool FileWorker::startDeleteFiles(QStringList filenames)
{
    if (isRunning())
        return false;

    m_mode = DeleteMode;
    m_filenames = filenames;
    m_cancelled.storeRelease(KeepRunning);
    start();
    return true;
}

bool FileWorker::startCopyFiles(QStringList filenames, QString destDirectory)
{
    if (isRunning())
        return false;

    m_mode = CopyMode;
    m_filenames = filenames;
    m_destDirectory = destDirectory;
    m_cancelled.storeRelease(KeepRunning);
    start();
    return true;
}

bool FileWorker::startMoveFiles(QStringList filenames, QString destDirectory)
{
    if (isRunning())
        return false;

    m_mode = MoveMode;
    m_filenames = filenames;
    m_destDirectory = destDirectory;
    m_cancelled.storeRelease(KeepRunning);
    start();
    return true;
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
        return tr("File not found: %1").arg(info.absoluteFilePath());

    if (info.isDir()) {
        bool ok = QDir(info.absoluteFilePath()).removeRecursively();
        if (!ok)
            return tr("Can't remove %1").arg(info.absoluteFilePath());

    } else {
        bool ok = QFile(info.absoluteFilePath()).remove();
        if (!ok)
            return tr("Can't remove %1").arg(info.absoluteFilePath());
    }
    return QString();
}

void FileWorker::deleteFiles()
{
    emit progressChanged(0);
    int fileIndex = 0;
    int fileCount = m_filenames.count();

    foreach (QString filename, m_filenames) {

        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            emit cancelOccurred();
            return;
        }

        // delete file and stop if errors
        QString errMsg = deleteFile(filename);
        if (!errMsg.isEmpty()) {
            emit errorOccurred(errMsg);
            return;
        }

        emit progressChanged(fileIndex / fileCount);
    }

    emit progressChanged(100);
    emit done();
}

void FileWorker::copyOrMoveFiles()
{
    emit progressChanged(0);
    int fileIndex = 0;
    int fileCount = m_filenames.count();

    QDir dest(m_destDirectory);
    foreach (QString filename, m_filenames) {

        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            emit cancelOccurred();
            return;
        }

        // check destination does not exists, otherwise copy/move fails
        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());
        if (QFile::exists(newname)) {
            emit errorOccurred(tr("File already exists: %1").arg(filename));
            return;
        }

        // move or copy and stop if errors
        if (m_mode == MoveMode) {
            if (!QFile::rename(filename, newname)) {
                emit errorOccurred(tr("Can't move %1").arg(filename));
                return;
            }
        } else {
            if (!QFile::copy(filename, newname)) {
                emit errorOccurred(tr("Can't copy %1").arg(filename));
                return;
            }
        }

        emit progressChanged(fileIndex / fileCount);
    }

    emit progressChanged(100);
    emit done();
}
