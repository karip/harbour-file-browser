#ifndef FILEDATA_H
#define FILEDATA_H

#include <QObject>
#include <QDir>
#include <QVariantList>
#include <QMimeType>
#include <QSize>
#include "statfileinfo.h"

/**
 * @brief The FileData class provides info about one file.
 */
class FileData : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString file READ file() WRITE setFile(QString) NOTIFY fileChanged())
    Q_PROPERTY(bool isDir READ isDir() NOTIFY isDirChanged())
    Q_PROPERTY(bool isSymLink READ isSymLink() NOTIFY isSymLinkChanged())
    Q_PROPERTY(QString kind READ kind() NOTIFY kindChanged())
    Q_PROPERTY(QString icon READ icon() NOTIFY iconChanged())
    Q_PROPERTY(QString permissions READ permissions() NOTIFY permissionsChanged())
    Q_PROPERTY(QString owner READ owner() NOTIFY ownerChanged())
    Q_PROPERTY(QString group READ group() NOTIFY groupChanged())
    Q_PROPERTY(QString size READ size() NOTIFY sizeChanged())
    Q_PROPERTY(QString modified READ modified() NOTIFY modifiedChanged())
    Q_PROPERTY(QString created READ created() NOTIFY createdChanged())
    Q_PROPERTY(QString absolutePath READ absolutePath() NOTIFY absolutePathChanged())
    Q_PROPERTY(QString name READ name() NOTIFY nameChanged())
    Q_PROPERTY(QString suffix READ suffix() NOTIFY suffixChanged())
    Q_PROPERTY(QString symLinkTarget READ symLinkTarget() NOTIFY symLinkTargetChanged())
    Q_PROPERTY(bool isSymLinkBroken READ isSymLinkBroken() NOTIFY isSymLinkBrokenChanged())
    Q_PROPERTY(QString mimeType READ mimeType() NOTIFY mimeTypeChanged())
    Q_PROPERTY(QString mimeTypeComment READ mimeTypeComment() NOTIFY mimeTypeCommentChanged())
    Q_PROPERTY(QStringList metaData READ metaData() NOTIFY metaDataChanged())
    Q_PROPERTY(QString errorMessage READ errorMessage() NOTIFY errorMessageChanged())

public:
    explicit FileData(QObject *parent = 0);
    ~FileData();

    // property accessors
    QString file() const { return m_file; }
    void setFile(QString file);

    bool isDir() const { return m_fileInfo.isDirAtEnd(); }
    bool isSymLink() const { return m_fileInfo.isSymLink(); }
    QString kind() const { return m_fileInfo.kind(); }
    QString icon() const;
    QString permissions() const;
    QString owner() const;
    QString group() const;
    QString size() const;
    QString modified() const;
    QString created() const;
    QString absolutePath() const;
    QString name() const { return m_fileInfo.fileName(); }
    QString suffix() const { return m_fileInfo.suffix().toLower(); }
    QString symLinkTarget() const { return m_fileInfo.symLinkTarget(); }
    bool isSymLinkBroken() const { return m_fileInfo.isSymLinkBroken(); }
    QString mimeType() const { return m_mimeTypeName; }
    QString mimeTypeComment() const { return m_mimeTypeComment; }
    QStringList metaData() const { return m_metaData; }
    QString errorMessage() const { return m_errorMessage; }

    // methods accessible from QML
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool mimeTypeInherits(QString parentMimeType);
    Q_INVOKABLE bool isSafeToOpen() const { return m_fileInfo.isSafeToRead(); }

signals:
    void fileChanged();
    void isDirChanged();
    void isSymLinkChanged();
    void kindChanged();
    void iconChanged();
    void permissionsChanged();
    void ownerChanged();
    void groupChanged();
    void sizeChanged();
    void modifiedChanged();
    void createdChanged();
    void nameChanged();
    void suffixChanged();
    void absolutePathChanged();
    void symLinkTargetChanged();
    void isSymLinkBrokenChanged();
    void metaDataChanged();
    void mimeTypeChanged();
    void mimeTypeCommentChanged();
    void errorMessageChanged();

private:
    void readInfo();
    void readMetaData();
    QString calculateAspectRatio(int width, int height) const;
    QStringList readExifData(QString filename);

    QString m_file;
    StatFileInfo m_fileInfo;
    QMimeType m_mimeType;
    QString m_mimeTypeName;
    QString m_mimeTypeComment;
    QStringList m_metaData;
    QString m_errorMessage;
};

#endif // FILEDATA_H
