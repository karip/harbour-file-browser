#ifndef GLOBALS_H
#define GLOBALS_H

#include <QString>
#include <QDateTime>
#include <QDir>

// Global functions

QString suffixToIconName(QString suffix);
QString permissionsToString(QFile::Permissions permissions);
QString filesizeToString(qint64 filesize);
QString datetimeToString(QDateTime datetime);

QString infoToFileKind(QFileInfo info);
QString infoToIconName(QFileInfo info);

int access(QString filename, int how);

QString execute(QString command, QStringList arguments, bool mergeErrorStream);

#endif // GLOBALS_H
