#ifndef SEARCHENGINE_H
#define SEARCHENGINE_H

#include <QDir>

class SearchWorker;

/**
 * @brief The SearchEngine is a front-end for the SearchWorker class.
 * These two classes could be merged, but it is clearer to keep the background thread
 * in its own class.
 */
class SearchEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString dir READ dir() WRITE setDir(QString) NOTIFY dirChanged())
    Q_PROPERTY(bool running READ running() NOTIFY runningChanged())

public:
    explicit SearchEngine(QObject *parent = 0);
    ~SearchEngine();

    // property accessors
    QString dir() const { return m_dir; }
    void setDir(QString dir);
    bool running() const;

    // callable from QML
    Q_INVOKABLE void search(QString searchTerm);
    Q_INVOKABLE void cancel();

signals:
    void dirChanged();
    void runningChanged();

    void progressChanged(QString directory);
    void matchFound(QString fullname, QString filename, QString absoluteDir,
                    QString fileIcon, QString fileKind);
    void workerDone();
    void workerErrorOccurred(QString message, QString filename);

private slots:
    void emitMatchFound(QString fullpath);

private:
    QString m_dir;
    QString m_errorMessage;
    SearchWorker *m_searchWorker;
};

#endif // SEARCHENGINE_H
