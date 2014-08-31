#include "filedata.h"
#include <QDir>
#include <QDateTime>
#include <QMimeDatabase>
#include <QImageReader>
#include "globals.h"
#include <QDebug>

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

QString FileData::icon() const
{
    return infoToIconName(m_fileInfo);
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
    if (m_file.isEmpty())
        return QString();
    return m_fileInfo.absolutePath();
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
    emit metaDataChanged();
    emit mimeTypeChanged();
    emit mimeTypeCommentChanged();
    emit errorMessageChanged();
}

void FileData::readMetaData()
{
    // special file types
    // do not sniff mimetype or metadata for these, because these can't really be read

    m_mimeType = QMimeType();
    if (m_fileInfo.isBlkAtEnd()) {
        m_mimeTypeName = "inode/blockdevice";
        m_mimeTypeComment = tr("block device");
        return;
    } else if (m_fileInfo.isChrAtEnd()) {
        m_mimeTypeName = "inode/chardevice";
        m_mimeTypeComment = tr("character device");
        return;
    } else if (m_fileInfo.isFifoAtEnd()) {
        m_mimeTypeName = "inode/fifo";
        m_mimeTypeComment = tr("pipe");
        return;
    } else if (m_fileInfo.isSocketAtEnd()) {
        m_mimeTypeName = "inode/socket";
        m_mimeTypeComment = tr("socket");
        return;
    } else if (m_fileInfo.isDirAtEnd()) {
        m_mimeTypeName = "inode/directory";
        m_mimeTypeComment = tr("folder");
        return;
    }
    if (!m_fileInfo.isFileAtEnd()) { // something strange
        m_mimeTypeName = "application/octet-stream";
        m_mimeTypeComment = tr("unknown");
        return;
    }

    // normal files - match content to find mimetype, which means that the file is read

    QMimeDatabase db;
    QString filename = m_fileInfo.isSymLink() ? m_fileInfo.symLinkTarget() :
                                                m_fileInfo.absoluteFilePath();
    m_mimeType = db.mimeTypeForFile(filename);
    m_mimeTypeName = m_mimeType.name();
    m_mimeTypeComment = m_mimeType.comment();

    // read metadata for images
    // store in m_metaData, first char is priority, then label:value
    if (m_mimeType.name() == "image/jpeg" || m_mimeType.name() == "image/png" ||
            m_mimeType.name() == "image/gif") {
        QImageReader reader(m_file);
        QSize s = reader.size();
        if (s.width() >= 0 && s.height() >= 0) {
            QString ar = calculateAspectRatio(s.width(), s.height());
            m_metaData.append("0" + tr("Image Size") +
                              QString(":%1 x %2 %3").arg(s.width()).arg(s.height()).arg(ar));
        }

        QStringList textKeys = reader.textKeys();
        foreach (QString key, textKeys) {
            QString value = reader.text(key);
            m_metaData.append("9"+key+":"+value);
        }
    }
}

const int aspectWidths[] = { 16, 4, 3, 5, 5, 1,  -1 };
const int aspectHeights[] = { 9, 3, 2, 3, 4, 1,  -1 };

QString FileData::calculateAspectRatio(int width, int height) const
{
    // Jolla Camera almost 16:9 aspect ratio
    if ((width == 3264 && height == 1840) || (height == 1840 && width == 3264)) {
        return QString("(16:9)");
    }

    int i = 0;
    while (aspectWidths[i] != -1) {
        if (width * aspectWidths[i] == height * aspectHeights[i] ||
                height * aspectWidths[i] == width * aspectHeights[i]) {
            return QString("(%1:%2)").arg(aspectWidths[i]).arg(aspectHeights[i]);
        }
        ++i;
    }
    return QString();
}
