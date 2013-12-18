#include "filemodel.h"
#include <QDateTime>
#include "globals.h"

enum {
    FilenameRole = Qt::UserRole + 1,
    FileKindRole = Qt::UserRole + 2,
    FileIconRole = Qt::UserRole + 3,
    PermissionsRole = Qt::UserRole + 4,
    SizeRole = Qt::UserRole + 5,
    LastModifiedRole = Qt::UserRole + 6,
    CreatedRole = Qt::UserRole + 7
};

FileModel::FileModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_dir = "";
}

FileModel::~FileModel()
{
}

int FileModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_files.count();
}

QVariant FileModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() > m_files.size()-1)
        return QVariant();

    QFileInfo info = m_files.at(index.row()).info;
    switch (role) {

    case Qt::DisplayRole:
    case FilenameRole:
        return info.fileName();

    case FileKindRole:
        if (info.isDir()) return "d";
        if (info.isSymLink()) return "l";
        if (info.isFile()) return "-";
        return "?";

    case FileIconRole:
        if (info.isDir()) return "folder";
        if (info.isSymLink()) return "link";
        if (info.isFile()) {
            QString suffix = info.suffix().toLower();
            return suffixToIconName(suffix);
        }
        return "file";

    case PermissionsRole:
        return permissionsToString(info.permissions());

    case SizeRole:
        if (info.isDir()) return "";
        return filesizeToString(info.size());

    case LastModifiedRole: {
        return datetimeToString(info.lastModified());
    }

    case CreatedRole: {
        return datetimeToString(info.created());
    }

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> FileModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(FilenameRole, QByteArray("filename"));
    roles.insert(FileKindRole, QByteArray("filekind"));
    roles.insert(FileIconRole, QByteArray("fileIcon"));
    roles.insert(PermissionsRole, QByteArray("permissions"));
    roles.insert(SizeRole, QByteArray("size"));
    roles.insert(LastModifiedRole, QByteArray("modified"));
    roles.insert(CreatedRole, QByteArray("created"));
    return roles;
}

int FileModel::fileCount() const
{
    return m_files.count();
}

QString FileModel::errorMessage() const
{
    return m_errorMessage;
}

void FileModel::setDir(QString dir)
{
    if (m_dir == dir)
        return;

    m_dir = dir;

    readDirectory();
    emit dirChanged();
}

QString FileModel::appendPath(QString dirName)
{
    return QDir::cleanPath(QDir(m_dir).absoluteFilePath(dirName));
}

QString FileModel::parentPath()
{
    return QDir::cleanPath(QDir(m_dir).absoluteFilePath(".."));
}

bool FileModel::deleteFile(int fileIndex)
{
    if (fileIndex < 0 || fileIndex >= m_files.count())
        return false;

    // remove file from file system

    // TODO: this should be performed in bg thread and progress given to user as delete may
    // take a long time
    QFileInfo info = m_files.at(fileIndex).info;
    if (info.isDir()) {
        bool ok = QDir(info.absoluteFilePath()).removeRecursively();
        if (!ok)
            return false;
    } else {
        bool ok = QFile(info.absoluteFilePath()).remove();
        if (!ok)
            return false;
    }

    // remove file from model

    beginRemoveRows(index(fileIndex).parent(), fileIndex, fileIndex);
    m_files.removeAt(fileIndex);
    endRemoveRows();
    return true;
}

void FileModel::readDirectory()
{
    // wrapped in reset model methods to get views notified
    beginResetModel();

    m_files.clear();
    m_errorMessage = "";

    if (!m_dir.isEmpty()) {
        readEntries();
    }

    endResetModel();
    emit fileCountChanged();
    emit errorMessageChanged();
}

void FileModel::readEntries()
{
    QDir dir(m_dir);
    if (!dir.exists()) {
        m_errorMessage = tr("Directory does not exist");
        return;
    }
    QByteArray ba = m_dir.toLatin1();
    char *dirname = ba.data();
    if (access(dirname, R_OK) == -1) {
        m_errorMessage = tr("No permission to read the directory");
        return;
    }

    QFileInfoList infoList = dir.entryInfoList();
    foreach (QFileInfo info, infoList) {
        QString filename = info.fileName();
        if (filename == "." || filename == "..")
            continue;

        FileData data;
        data.info = info;
        m_files.append(data);
    }
}
