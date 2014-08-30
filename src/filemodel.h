#ifndef FILEMODEL_H
#define FILEMODEL_H

#include <QAbstractListModel>
#include <QDir>
#include <QFileSystemWatcher>
#include "statfileinfo.h"

/**
 * @brief The FileModel class can be used as a model in a ListView to display a list of files
 * in the current directory. It has methods to change the current directory and to access
 * file info.
 * It also actively monitors the directory. If the directory changes, then the model is
 * updated automatically if active is true. If active is false, then the directory is
 * updated when active becomes true.
 */
class FileModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString dir READ dir() WRITE setDir(QString) NOTIFY dirChanged())
    Q_PROPERTY(int fileCount READ fileCount() NOTIFY fileCountChanged())
    Q_PROPERTY(QString errorMessage READ errorMessage() NOTIFY errorMessageChanged())
    Q_PROPERTY(bool active READ active() WRITE setActive(bool) NOTIFY activeChanged())
    Q_PROPERTY(int selectedFileCount READ selectedFileCount() NOTIFY selectedFileCountChanged())

public:
    explicit FileModel(QObject *parent = 0);
    ~FileModel();

    // methods needed by ListView
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    // property accessors
    QString dir() const { return m_dir; }
    void setDir(QString dir);
    int fileCount() const;
    QString errorMessage() const;
    bool active() const { return m_active; }
    void setActive(bool active);
    int selectedFileCount() const { return m_selectedFileCount; }

    // methods accessible from QML
    Q_INVOKABLE QString appendPath(QString dirName);
    Q_INVOKABLE QString parentPath();
    Q_INVOKABLE QString fileNameAt(int fileIndex);

    // file selection
    Q_INVOKABLE void toggleSelectedFile(int fileIndex);
    Q_INVOKABLE void clearSelectedFiles();
    Q_INVOKABLE QStringList selectedFiles() const;

public slots:
    // reads the directory and inserts/removes model items as needed
    Q_INVOKABLE void refresh();
    // reads the directory and sets all model items
    Q_INVOKABLE void refreshFull();

signals:
    void dirChanged();
    void fileCountChanged();
    void errorMessageChanged();
    void activeChanged();
    void selectedFileCountChanged();

private slots:
    void readDirectory();

private:
    void recountSelectedFiles();
    void readAllEntries();
    void refreshEntries();
    void clearModel();
    bool filesContains(const QList<StatFileInfo> &files, const StatFileInfo &fileData) const;

    QString m_dir;
    QList<StatFileInfo> m_files;
    int m_selectedFileCount;
    QString m_errorMessage;
    bool m_active;
    bool m_dirty;
    QFileSystemWatcher *m_watcher;
};



#endif // FILEMODEL_H
