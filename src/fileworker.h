#ifndef FILEWORKER_H
#define FILEWORKER_H

#include <QThread>
#include <QDir>

/**
 * @brief FileWorker does all file related work in the background.
 */
class FileWorker : public QThread
{
    Q_OBJECT

public:
    explicit FileWorker(QObject *parent = 0);
    ~FileWorker();

    // call these to start the thread, returns false if start failed
    bool startDeleteFiles(QStringList filenames);
    bool startCopyFiles(QStringList filenames, QString destDirectory);
    bool startMoveFiles(QStringList filenames, QString destDirectory);

    void cancel();

signals: // signals, can be connected from a thread to another
    void progressChanged(double progress);

    // one of these is emitted when thread ends
    void done();
    void errorOccurred(QString message);
    void cancelOccurred();

protected:
    void run();

private:
    enum Mode {
        DeleteMode, CopyMode, MoveMode
    };
    enum CancelStatus {
        Cancelled = 0, KeepRunning = 1
    };

    QString deleteFile(QString filenames);
    void deleteFiles();
    void copyOrMoveFiles();

    FileWorker::Mode m_mode;
    QStringList m_filenames;
    QString m_destDirectory;
    QAtomicInt m_cancelled; // atomic so no locks needed
};

#endif // FILEWORKER_H
