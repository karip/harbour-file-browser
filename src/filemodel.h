#ifndef FILEMODEL_H
#define FILEMODEL_H

#include <QAbstractListModel>
#include <QDir>

// struct to hold data for a single file
struct FileData
{
    QFileInfo info;
};

/**
 * @brief The FileModel class can be used as a model in a ListView to display a list of files
 * in the current directory. It also has methods to change the current directory and to access
 * file info.
 */
class FileModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString dir READ dir() WRITE setDir(QString) NOTIFY dirChanged())
    Q_PROPERTY(int fileCount READ fileCount() NOTIFY fileCountChanged())
    Q_PROPERTY(QString errorMessage READ errorMessage() NOTIFY errorMessageChanged())

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

    // methods accessible from QML
    Q_INVOKABLE QString appendPath(QString dirName);
    Q_INVOKABLE QString parentPath();
    Q_INVOKABLE bool deleteFile(int fileIndex);

signals:
    void dirChanged();
    void fileCountChanged();
    void errorMessageChanged();

private:
    void readDirectory();
    void readEntries();

    QString m_dir;
    QList<FileData> m_files;
    QString m_errorMessage;
};



#endif // FILEMODEL_H
