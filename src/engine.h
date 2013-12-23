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
    Q_PROPERTY(int clipboardCut READ clipboardCut() NOTIFY clipboardCutChanged())
    Q_PROPERTY(int progress READ progress() NOTIFY progressChanged())
    Q_PROPERTY(QString progressFilename READ progressFilename() NOTIFY progressFilenameChanged())

public:
    explicit Engine(QObject *parent = 0);
    ~Engine();

    int clipboardCount() const { return m_clipboardFiles.count(); }
    bool clipboardCut() const { return m_clipboardCut; }
    int progress() const { return m_progress; }
    QString progressFilename() const { return m_progressFilename; }

    // methods accessible from QML

    // asynch methods send signals when done or error occurs
    Q_INVOKABLE void deleteFiles(QStringList filenames);
    Q_INVOKABLE void cutFiles(QStringList filenames);
    Q_INVOKABLE void copyFiles(QStringList filenames);
    Q_INVOKABLE void pasteFiles(QString destDirectory);

    Q_INVOKABLE void cancel();

    Q_INVOKABLE QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE bool exists(QString filename);

signals:
    void clipboardCountChanged();
    void clipboardCutChanged();
    void progressChanged();
    void progressFilenameChanged();
    void workerDone();
    void workerErrorOccurred(QString message, QString filename);
    void workerCancelDone();

private slots:
    void setProgress(int progress, QString filename);

private:
    QStringList m_clipboardFiles;
    bool m_clipboardCut;
    int m_progress;
    QString m_progressFilename;
    QString m_errorMessage;
    FileWorker *m_fileWorker;
};

#endif // ENGINE_H
