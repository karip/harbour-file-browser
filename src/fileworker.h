#ifndef FILEWORKER_H
#define FILEWORKER_H

#include <QThread>
#include <QDir>

/**
 * @brief FileWorker does delete, copy and move files in the background.
 */
class FileWorker : public QThread
{
    Q_OBJECT

public:
    explicit FileWorker(QObject *parent = 0);
    ~FileWorker();

    // call these to start the thread, returns false if start failed
    void startDeleteFiles(QStringList filenames);
    void startCopyFiles(QStringList filenames, QString destDirectory);
    void startMoveFiles(QStringList filenames, QString destDirectory);

    void cancel();

signals: // signals, can be connected from a thread to another
    void progressChanged(int progress, QString filename);

    // one of these is emitted when thread ends
    void done();
    void errorOccurred(QString message, QString filename);

    void fileDeleted(QString fullname);

protected:
    void run() Q_DECL_OVERRIDE;

private:
    enum Mode {
        DeleteMode, CopyMode, MoveMode
    };
    enum CancelStatus {
        Cancelled = 0, KeepRunning = 1
    };

    bool validateFilenames(const QStringList &filenames);

    QString deleteFile(QString filename);
    void deleteFiles();
    void copyOrMoveFiles();
    QString copyDirRecursively(QString srcDirectory, QString destDirectory);
    QString copyOverwrite(QString src, QString dest);

    FileWorker::Mode m_mode;
    QStringList m_filenames;
    QString m_destDirectory;
    QAtomicInt m_cancelled; // atomic so no locks needed
    int m_progress;
};

#endif // FILEWORKER_H
