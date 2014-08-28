#include "statfileinfo.h"

StatFileInfo::StatFileInfo() :
    m_filename(""), m_selected(false)
{
    refresh();
}

StatFileInfo::StatFileInfo(QString filename) :
    m_filename(filename), m_selected(false)
{
    refresh();
}

StatFileInfo::~StatFileInfo()
{
}

void StatFileInfo::setFile(QString filename)
{
    m_filename = filename;
    refresh();
}

QString StatFileInfo::kind() const
{
    if (isSymLink()) return "l";
    if (isDir()) return "d";
    if (isBlk()) return "b";
    if (isChr()) return "c";
    if (isFifo()) return "p";
    if (isSocket()) return "s";
    if (isFile()) return "-";
    return "?";
}

bool StatFileInfo::exists() const
{
    return m_fileInfo.exists();
}

bool StatFileInfo::isSafeToRead() const
{
    // it is safe to read non-existing files
    if (!exists())
        return true;

    // check the file is a regular file and not a special file
    return isFileAtEnd();
}

bool StatFileInfo::isSymLinkBroken() const
{
    // if it is a symlink but it doesn't exist, then it is broken
    if (m_fileInfo.isSymLink() && !m_fileInfo.exists())
        return true;
    return false;
}

void StatFileInfo::setSelected(bool selected)
{
    m_selected = selected;
}

void StatFileInfo::refresh()
{
    memset(&m_stat, 0, sizeof(m_stat));
    memset(&m_lstat, 0, sizeof(m_lstat));

    m_fileInfo = QFileInfo(m_filename);
    if (m_filename.isEmpty())
        return;

    QByteArray ba = m_filename.toUtf8();
    char *fn = ba.data();

    // check the file without following symlinks
    int res = lstat(fn, &m_lstat);
    if (res != 0) { // if error, then set to undefined
        m_lstat.st_mode = 0;
    }
    // if not symlink, then just copy lstat data to stat
    if (!S_ISLNK(m_lstat.st_mode)) {
        memcpy(&m_stat, &m_lstat, sizeof(m_stat));
        return;
    }

    // check the file after following possible symlinks
    res = stat(fn, &m_stat);
    if (res != 0) { // if error, then set to undefined
        m_stat.st_mode = 0;
    }

}

