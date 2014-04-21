#ifndef STATFILEINFO_H
#define STATFILEINFO_H

#include <QFileInfo>
#include <QDateTime>
#include <QDir>
#include <sys/stat.h>

/**
 * @brief The StatFileInfo class is like QFileInfo, but has more detailed information about file types.
 */
class StatFileInfo
{
public:
    explicit StatFileInfo();
    explicit StatFileInfo(QString filename);
    ~StatFileInfo();

    void setFile(QString filename);
    QString fileName() const { return m_fileInfo.fileName(); }

    // these inspect the file itself without following symlinks

    // directory
    bool isDir() const { return S_ISDIR(m_lstat.st_mode); }
    // symbolic link
    bool isSymLink() const { return S_ISLNK(m_lstat.st_mode); }
    // block special file
    bool isBlk() const { return S_ISBLK(m_lstat.st_mode); }
    // character special file
    bool isChr() const { return S_ISCHR(m_lstat.st_mode); }
    // pipe of FIFO special file
    bool isFifo() const { return S_ISFIFO(m_lstat.st_mode); }
    // socket
    bool isSocket() const { return S_ISSOCK(m_lstat.st_mode); }
    // regular file
    bool isFile() const { return S_ISREG(m_lstat.st_mode); }
    // system file (not a dir, regular file or symlink)
    bool isSystem() const { return !S_ISDIR(m_lstat.st_mode) && !S_ISREG(m_lstat.st_mode) &&
                                   !S_ISLNK(m_lstat.st_mode); }

    // these inspect the file or if it is a symlink, then its target end point

    // directory
    bool isDirAtEnd() const { return S_ISDIR(m_stat.st_mode); }
    // block special file
    bool isBlkAtEnd() const { return S_ISBLK(m_stat.st_mode); }
    // character special file
    bool isChrAtEnd() const { return S_ISCHR(m_stat.st_mode); }
    // pipe of FIFO special file
    bool isFifoAtEnd() const { return S_ISFIFO(m_stat.st_mode); }
    // socket
    bool isSocketAtEnd() const { return S_ISSOCK(m_stat.st_mode); }
    // regular file
    bool isFileAtEnd() const { return S_ISREG(m_stat.st_mode); }
    // system file (not a dir or regular file)
    bool isSystemAtEnd() const { return !S_ISDIR(m_stat.st_mode) && !S_ISREG(m_stat.st_mode); }

    // these inspect the file or if it is a symlink, then its target end point

    QString kind() const;
    QFile::Permissions permissions() const { return m_fileInfo.permissions(); }
    QString group() const { return m_fileInfo.group(); }
    uint groupId() const { return m_fileInfo.groupId(); }
    QString owner() const { return m_fileInfo.owner(); }
    uint ownerId() const { return m_fileInfo.ownerId(); }
    qint64 size() const { return m_fileInfo.size(); }
    QDateTime lastModified() const { return m_fileInfo.lastModified(); }
    QDateTime created() const { return m_fileInfo.created(); }
    bool exists() const;
    bool isSafeToRead() const { return isFileAtEnd(); }

    // path accessors

    QDir absoluteDir() const { return m_fileInfo.absoluteDir(); }
    QString absolutePath() const { return m_fileInfo.absolutePath(); }
    QString absoluteFilePath() const { return m_fileInfo.absoluteFilePath(); }
    QString suffix() const { return m_fileInfo.suffix(); }
    QString symLinkTarget() const { return m_fileInfo.symLinkTarget(); }
    bool isSymLinkBroken() const;

    void refresh();

private:
    QString m_filename;
    QFileInfo m_fileInfo;
    struct stat m_stat;
    struct stat m_lstat;
};

#endif // STATFILEINFO_H
