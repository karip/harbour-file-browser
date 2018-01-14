#ifndef SEARCHWORKER_H
#define SEARCHWORKER_H

#include <QThread>
#include <QDir>

/**
 * @brief SearchWorker does searching in the background.
 */
class SearchWorker : public QThread
{
    Q_OBJECT

public:
    explicit SearchWorker(QObject *parent = 0);
    ~SearchWorker();

    void startSearch(QString directory, QString searchTerm);

    void cancel();

signals: // signals, can be connected from a thread to another

    void progressChanged(QString directory);

    void matchFound(QString fullname);

    // one of these is emitted when thread ends
    void done();
    void errorOccurred(QString message, QString filename);

protected:
    void run() Q_DECL_OVERRIDE;

private:
    enum CancelStatus {
        Cancelled = 0, NotCancelled = 1
    };

    QString searchRecursively(QString directory, QString searchTerm);

    QString m_directory;
    QString m_searchTerm;
    QAtomicInt m_cancelled; // atomic so no locks needed
    QString m_currentDirectory;
};

#endif // SEARCHWORKER_H
