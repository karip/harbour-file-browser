#ifndef ENGINE_H
#define ENGINE_H

#include <QDir>

class FileWorker;

/**
 * @brief Engine to handle cut, copy and paste.
 */
class Engine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int clipboardCount READ clipboardCount() NOTIFY clipboardCountChanged())
    Q_PROPERTY(double progress READ progress() NOTIFY progressChanged())

public:
    explicit Engine(QObject *parent = 0);
    ~Engine();

    int clipboardCount() const { return m_clipboardFiles.count(); }
    double progress() const { return m_progress; }

    // methods accessible from QML
    Q_INVOKABLE bool deleteFiles(QStringList filenames);
    Q_INVOKABLE bool cutFiles(QStringList filenames);
    Q_INVOKABLE bool copyFiles(QStringList filenames);
    Q_INVOKABLE bool pasteFiles(QString destDirectory);

signals:
    void clipboardCountChanged();
    void progressChanged();
    void workerDone();
    void workerErrorOccurred(QString message);
    void workerCancelOccurred();

private slots:
    void setProgress(double progress);

private:
    QStringList m_clipboardFiles;
    bool m_clipboardCut;
    double m_progress;
    QString m_errorMessage;
    FileWorker *m_fileWorker;
};

#endif // ENGINE_H
