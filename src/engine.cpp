#include "engine.h"
#include <QDateTime>
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

void Engine::setProgress(int progress, QString filename)
{
    m_progress = progress;
    m_progressFilename = filename;
    emit progressChanged();
    emit progressFilenameChanged();
}

