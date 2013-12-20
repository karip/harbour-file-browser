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
    connect(m_fileWorker, SIGNAL(progressChanged(double)), this, SLOT(setProgress(double)));

    // pass worker end signals to QML
    connect(m_fileWorker, SIGNAL(done()), this, SIGNAL(workerDone()));
    connect(m_fileWorker, SIGNAL(workerErrorOccurred(QString message)),
            this, SIGNAL(workerDone(QString message)));
    connect(m_fileWorker, SIGNAL(workerCancelOccurred()), this, SIGNAL(workerDone()));
}

Engine::~Engine()
{
    // is this the way to force stop the worker thread?
    m_fileWorker->cancel(); // stop possibly running background thread
    m_fileWorker->wait();   // wait until thread stops
    delete m_fileWorker;    // delete it
}

bool Engine::deleteFiles(QStringList filenames)
{
    setProgress(0);
    return m_fileWorker->startDeleteFiles(filenames);
}

bool Engine::cutFiles(QStringList files)
{
    m_clipboardFiles = files;
    m_clipboardCut = true;
    emit clipboardCountChanged();
    return true;
}

bool Engine::copyFiles(QStringList files)
{
    m_clipboardFiles = files;
    m_clipboardCut = false;
    emit clipboardCountChanged();
    return true;
}

bool Engine::pasteFiles(QString destDirectory)
{
    if (m_clipboardFiles.isEmpty())
        return true;

    QStringList files = m_clipboardFiles;
    m_clipboardFiles.clear();
    emit clipboardCountChanged();
    setProgress(0);

    QDir dest(destDirectory);
    if (!dest.exists()) {
        m_errorMessage = tr("Destination does not exist: %1").arg(destDirectory);
        return false;
    }

    if (m_clipboardCut)
        return m_fileWorker->startMoveFiles(files, destDirectory);

    return m_fileWorker->startCopyFiles(files, destDirectory);
}

void Engine::setProgress(double progress)
{
    m_progress = progress;
    emit progressChanged();
}

