#include "fileinfo.h"
#include <QDir>
#include <QDateTime>
#include <QMimeDatabase>
#include "globals.h"

FileInfo::FileInfo(QObject *parent) :
    QObject(parent)
{
    m_file = "";
}

FileInfo::~FileInfo()
{
}

void FileInfo::setFile(QString file)
{
    if (m_file == file)
        return;

    m_file = file;
    readInfo();
}

bool FileInfo::isDir() const
{
    return m_fileInfo.isDir();
}

bool FileInfo::isSymLink() const
{
    return m_fileInfo.isSymLink();
}

QString FileInfo::kind() const
{
    if (m_fileInfo.isSymLink()) return "l";
    if (m_fileInfo.isDir()) return "d";
    if (m_fileInfo.isFile()) return "-";
    return "?";
}

QString FileInfo::icon() const
{
    if (m_fileInfo.isSymLink() && m_fileInfo.isDir()) return "folder-link";
    if (m_fileInfo.isDir()) return "folder";
    if (m_fileInfo.isSymLink()) return "link";
    if (m_fileInfo.isFile()) {
        QString suffix = m_fileInfo.suffix().toLower();
        return suffixToIconName(suffix);
    }
    return "file";
}

QString FileInfo::permissions() const
{
    return permissionsToString(m_fileInfo.permissions());
}

QString FileInfo::owner() const
{
    QString owner = m_fileInfo.owner();
    if (owner.isEmpty()) {
        uint id = m_fileInfo.ownerId();
        if (id != (uint)-2)
            owner = QString::number(id);
    }
    return owner;
}

QString FileInfo::group() const
{
    QString group = m_fileInfo.group();
    if (group.isEmpty()) {
        uint id = m_fileInfo.groupId();
        if (id != (uint)-2)
            group = QString::number(id);
    }
    return group;
}

QString FileInfo::size() const
{
    if (m_fileInfo.isDir()) return "-";
    return filesizeToString(m_fileInfo.size());
}

QString FileInfo::modified() const
{
    return datetimeToString(m_fileInfo.lastModified());
}

QString FileInfo::created() const
{
    return datetimeToString(m_fileInfo.created());
}

QString FileInfo::absolutePath() const
{
    return m_fileInfo.absolutePath();
}

QString FileInfo::name() const
{
    return m_fileInfo.fileName();
}

QString FileInfo::suffix() const
{
    return m_fileInfo.suffix().toLower();
}

QString FileInfo::symLinkTarget() const
{
    return m_fileInfo.symLinkTarget();
}

bool FileInfo::isSymLinkBroken() const
{
    // if it is a symlink but it doesn't exist, then it is broken
    if (m_fileInfo.isSymLink() && !m_fileInfo.exists())
        return true;
    return false;
}

QString FileInfo::type() const
{
    return m_mimeType.comment();
}

QString FileInfo::mimeType() const
{
    return m_mimeType.name();
}

QString FileInfo::errorMessage() const
{
    return m_errorMessage;
}

void FileInfo::refresh()
{
    readInfo();
}

bool FileInfo::mimeTypeInherits(QString parentMimeType)
{
    return m_mimeType.inherits(parentMimeType);
}

void FileInfo::readInfo()
{
    m_errorMessage = "";

    m_fileInfo = QFileInfo(m_file);
    // exists() checks for target existence in symlinks, so ignore it for symlinks
    if (!m_fileInfo.exists() && !m_fileInfo.isSymLink())
        m_errorMessage = tr("File does not exist");

    QMimeDatabase db;
    m_mimeType = db.mimeTypeForFile(m_fileInfo);

    emit fileChanged();
    emit isDirChanged();
    emit isSymLinkChanged();
    emit kindChanged();
    emit iconChanged();
    emit permissionsChanged();
    emit ownerChanged();
    emit groupChanged();
    emit sizeChanged();
    emit modifiedChanged();
    emit createdChanged();
    emit absolutePathChanged();
    emit nameChanged();
    emit suffixChanged();
    emit symLinkTargetChanged();
    emit isSymLinkBrokenChanged();
    emit typeChanged();
    emit mimeTypeChanged();
    emit errorMessageChanged();
}
