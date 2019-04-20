#ifndef ENGINE_H
#define ENGINE_H

#include <QDir>
#include <QVariant>

class FileWorker;

/**
 * @brief Engine to handle file operations, settings and other generic functionality.
 */
class Engine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int clipboardCount READ clipboardCount() NOTIFY clipboardCountChanged())
    Q_PROPERTY(int clipboardContainsCopy READ clipboardContainsCopy() NOTIFY clipboardContainsCopyChanged())
    Q_PROPERTY(int progress READ progress() NOTIFY progressChanged())
    Q_PROPERTY(QString progressFilename READ progressFilename() NOTIFY progressFilenameChanged())

public:
    explicit Engine(QObject *parent = 0);
    ~Engine();

    // properties
    int clipboardCount() const { return m_clipboardFiles.count(); }
    bool clipboardContainsCopy() const { return m_clipboardContainsCopy; }
    int progress() const { return m_progress; }
    QString progressFilename() const { return m_progressFilename; }

    // methods accessible from QML

    // asynch methods send signals when done or error occurs
    Q_INVOKABLE void deleteFiles(QStringList filenames);
    Q_INVOKABLE void cutFiles(QStringList filenames);
    Q_INVOKABLE void copyFiles(QStringList filenames);
    // returns a list of existing files if clipboard files already exist
    // or an empty list if no existing files
    Q_INVOKABLE QStringList listExistingFiles(QString destDirectory);
    Q_INVOKABLE void pasteFiles(QString destDirectory);

    // cancel asynch methods
    Q_INVOKABLE void cancel();

    // returns error msg
    Q_INVOKABLE QString errorMessage() const { return m_errorMessage; }

    // file paths
    Q_INVOKABLE QString homeFolder() const;
    Q_INVOKABLE QString sdcardPath() const;
    Q_INVOKABLE QString androidSdcardPath() const;

    // synchronous methods
    Q_INVOKABLE bool exists(QString filename);
    Q_INVOKABLE QStringList diskSpace(QString path);
    Q_INVOKABLE QStringList readFile(QString filename);
    Q_INVOKABLE QString mkdir(QString path, QString name);
    Q_INVOKABLE QStringList rename(QString fullOldFilename, QString newName);
    Q_INVOKABLE QString chmod(QString path,
                              bool ownerRead, bool ownerWrite, bool ownerExecute,
                              bool groupRead, bool groupWrite, bool groupExecute,
                              bool othersRead, bool othersWrite, bool othersExecute);

    // access settings
    Q_INVOKABLE QString readSetting(QString key, QString defaultValue = QString());
    Q_INVOKABLE void writeSetting(QString key, QString value);

signals:
    void clipboardCountChanged();
    void clipboardContainsCopyChanged();
    void progressChanged();
    void progressFilenameChanged();
    void workerDone();
    void workerErrorOccurred(QString message, QString filename);
    void fileDeleted(QString fullname);

    void settingsChanged();

private slots:
    void setProgress(int progress, QString filename);

private:
    QStringList mountPoints() const;
    QString createHexDump(char *buffer, int size, int bytesPerLine);
    QStringList makeStringList(QString msg, QString str = QString());

    QStringList m_clipboardFiles;
    bool m_clipboardContainsCopy;
    int m_progress;
    QString m_progressFilename;
    QString m_errorMessage;
    FileWorker *m_fileWorker;
};

#endif // ENGINE_H
