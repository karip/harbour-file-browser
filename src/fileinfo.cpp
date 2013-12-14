#include "fileinfo.h"
#include <QDir>
#include <QDateTime>
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
    readFile();
    emit fileChanged();
}

QString FileInfo::kind() const
{
    if (m_fileInfo.isDir()) return "d";
    if (m_fileInfo.isSymLink()) return "l";
    if (m_fileInfo.isFile()) return "-";
    return "?";
}

QString FileInfo::icon() const
{
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

QString FileInfo::size() const
{
    if (m_fileInfo.isDir()) return "";
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

QString FileInfo::symLinkTarget() const
{
    return m_fileInfo.symLinkTarget();
}

QString FileInfo::errorMessage() const
{
    return m_errorMessage;
}

void FileInfo::readFile()
{
    m_errorMessage = "";

    m_fileInfo = QFileInfo(m_file);
    if (!m_fileInfo.exists())
        m_errorMessage = tr("File does not exist");

    emit fileChanged();
    emit kindChanged();
    emit iconChanged();
    emit permissionsChanged();
    emit sizeChanged();
    emit modifiedChanged();
    emit createdChanged();
    emit absolutePathChanged();
    emit nameChanged();
    emit symLinkTargetChanged();
    emit errorMessageChanged();
}
