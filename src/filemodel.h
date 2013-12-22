#ifndef FILEMODEL_H
#define FILEMODEL_H

#include <QAbstractListModel>
#include <QDir>
#include <QFileSystemWatcher>

// struct to hold data for a single file
struct FileData
{
    QFileInfo info;
};

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

    // methods accessible from QML
    Q_INVOKABLE QString appendPath(QString dirName);
    Q_INVOKABLE QString parentPath();
    Q_INVOKABLE QString fileNameAt(int fileIndex);
    Q_INVOKABLE void refresh();

signals:
    void dirChanged();
    void fileCountChanged();
    void errorMessageChanged();
    void activeChanged();

private slots:
    void readDirectory();

private:
    void readEntries();

    QString m_dir;
    QList<FileData> m_files;
    QString m_errorMessage;
    bool m_active;
    bool m_dirty;
    QFileSystemWatcher *m_watcher;
};



#endif // FILEMODEL_H
