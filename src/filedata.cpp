#include "filedata.h"
#include <QDir>
#include <QDateTime>
#include <QMimeDatabase>
#include <QImageReader>
#include "globals.h"

FileData::FileData(QObject *parent) :
    QObject(parent)
{
    m_file = "";
}

FileData::~FileData()
{
}

void FileData::setFile(QString file)
{
    if (m_file == file)
        return;

    m_file = file;
    readInfo();
}

bool FileData::isDir() const
{
    return m_fileInfo.isDirAtEnd();
}

bool FileData::isSymLink() const
{
    return m_fileInfo.isSymLink();
}

QString FileData::kind() const
{
    return m_fileInfo.kind();
}

QString FileData::icon() const
{
    if (m_fileInfo.isSymLink() && m_fileInfo.isDirAtEnd()) return "folder-link";
    if (m_fileInfo.isDir()) return "folder";
    if (m_fileInfo.isSymLink()) return "link";
    if (m_fileInfo.isFileAtEnd()) {
        QString suffix = m_fileInfo.suffix().toLower();
        return suffixToIconName(suffix);
    }
    return "file";
}

QString FileData::permissions() const
{
    return permissionsToString(m_fileInfo.permissions());
}

QString FileData::owner() const
{
    QString owner = m_fileInfo.owner();
    if (owner.isEmpty()) {
        uint id = m_fileInfo.ownerId();
        if (id != (uint)-2)
            owner = QString::number(id);
    }
    return owner;
}

QString FileData::group() const
{
    QString group = m_fileInfo.group();
    if (group.isEmpty()) {
        uint id = m_fileInfo.groupId();
        if (id != (uint)-2)
            group = QString::number(id);
    }
    return group;
}

QString FileData::size() const
{
    if (m_fileInfo.isDirAtEnd()) return "-";
    return filesizeToString(m_fileInfo.size());
}

QString FileData::modified() const
{
    return datetimeToString(m_fileInfo.lastModified());
}

QString FileData::created() const
{
    return datetimeToString(m_fileInfo.created());
}

QString FileData::absolutePath() const
{
    return m_fileInfo.absolutePath();
}

QString FileData::name() const
{
    return m_fileInfo.fileName();
}

QString FileData::suffix() const
{
    return m_fileInfo.suffix().toLower();
}

QString FileData::symLinkTarget() const
{
    return m_fileInfo.symLinkTarget();
}

bool FileData::isSymLinkBroken() const
{
    // if it is a symlink but it doesn't exist, then it is broken
    if (m_fileInfo.isSymLink() && !m_fileInfo.exists())
        return true;
    return false;
}

QString FileData::type() const
{
    return m_mimeType.comment();
}

QString FileData::mimeType() const
{
    return m_mimeType.name();
}

QString FileData::errorMessage() const
{
    return m_errorMessage;
}

void FileData::refresh()
{
    readInfo();
}

bool FileData::mimeTypeInherits(QString parentMimeType)
{
    return m_mimeType.inherits(parentMimeType);
}

void FileData::readInfo()
{
    m_errorMessage = "";
    m_metaData.clear();

    m_fileInfo.setFile(m_file);

    // exists() checks for target existence in symlinks, so ignore it for symlinks
    if (!m_fileInfo.exists() && !m_fileInfo.isSymLink())
        m_errorMessage = tr("File does not exist");

    readMetaData();

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
    emit metaDataChanged();
    emit errorMessageChanged();
}

void FileData::readMetaData()
{
    QMimeDatabase db;
    m_mimeType = db.mimeTypeForFile(m_fileInfo.fileName());

    if (!m_fileInfo.isSafeToRead())
        return;

    // read metadata from image
    if (m_mimeType.name() == "image/jpeg" || m_mimeType.name() == "image/png" ||
            m_mimeType.name() == "image/gif") {
        QImageReader reader(m_file);
        QSize s = reader.size();
        if (s.width() >= 0 && s.height() >= 0)
            m_metaData.append(tr("Image Size")+QString(":%1 x %2").arg(s.width()).arg(s.height()));

        QStringList textKeys = reader.textKeys();
        foreach (QString key, textKeys) {
            QString value = reader.text(key);
            m_metaData.append(key+":"+value);
        }
    }
}

