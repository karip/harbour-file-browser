#include "globals.h"
#include <QLocale>

QString suffixToIconName(QString suffix)
{
    if (suffix == "txt")
        return "file-txt";
    if (suffix == "rpm")
        return "file-rpm";
    if (suffix == "apk")
        return "file-apk";
    if (suffix == "png" || suffix == "jpeg" || suffix == "jpg" ||
            suffix == "gif")
        return "file-image";
    if (suffix == "wav" || suffix == "mp3" || suffix == "flac" ||
            suffix == "aac" || suffix == "ogg")
        return "file-audio";
    if (suffix == "mp4" || suffix == "mpg" || suffix == "avi" ||
            suffix == "mov")
        return "file-video";

    return "file";
}

QString permissionsToString(QFile::Permissions permissions)
{
    char str[] = "---------";
    if (permissions & 0x0400) str[0] = 'r';
    if (permissions & 0x0200) str[1] = 'w';
    if (permissions & 0x0100) str[2] = 'x';
    if (permissions & 0x0040) str[3] = 'r';
    if (permissions & 0x0020) str[4] = 'w';
    if (permissions & 0x0010) str[5] = 'x';
    if (permissions & 0x0004) str[6] = 'r';
    if (permissions & 0x0002) str[7] = 'w';
    if (permissions & 0x0001) str[8] = 'x';
    return QString::fromLatin1(str);
}

QString filesizeToString(qint64 filesize)
{
    // convert to kB, MB, GB: use 1000 instead of 1024 as divisor because it seems to be
    // the usual way to display file size (like on Ubuntu)
    QLocale locale;
    if (filesize < 1000LL)
        return locale.toString(filesize)+" bytes";

    if (filesize < 1000000LL)
        return locale.toString((double)filesize/1000.0, 'f', 2)+" kB";

    if (filesize < 1000000000LL)
        return locale.toString((double)filesize/1000000.0, 'f', 2)+" MB";

    return locale.toString((double)filesize/1000000000.0, 'f', 2)+" GB";
}

QString datetimeToString(QDateTime datetime)
{
    QLocale locale;

    // return time for today or date for older
    if (datetime.date() == QDate::currentDate())
        return locale.toString(datetime.time(), QLocale::NarrowFormat);

    return locale.toString(datetime.date(), QLocale::NarrowFormat);
}
