#ifndef FILEDATA_H
#define FILEDATA_H

#include <QObject>
#include <QDir>
#include <QVariantList>
#include <QMimeType>
#include <QSize>

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
    Q_PROPERTY(QString type READ type() NOTIFY typeChanged())
    Q_PROPERTY(QString mimeType READ mimeType() NOTIFY mimeTypeChanged())
    Q_PROPERTY(QStringList metaData READ metaData() NOTIFY metaDataChanged())
    Q_PROPERTY(QString errorMessage READ errorMessage() NOTIFY errorMessageChanged())

public:
    explicit FileData(QObject *parent = 0);
    ~FileData();

    // property accessors
    QString file() const { return m_file; }
    void setFile(QString file);

    bool isDir() const;
    bool isSymLink() const;
    QString kind() const;
    QString icon() const;
    QString permissions() const;
    QString owner() const;
    QString group() const;
    QString size() const;
    QString modified() const;
    QString created() const;
    QString absolutePath() const;
    QString name() const;
    QString suffix() const;
    QString symLinkTarget() const;
    bool isSymLinkBroken() const;
    QString type() const;
    QString mimeType() const;
    QStringList metaData() const { return m_metaData; }
    QString errorMessage() const;

    // methods accessible from QML
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool mimeTypeInherits(QString parentMimeType);

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
    void typeChanged();
    void metaDataChanged();
    void mimeTypeChanged();
    void errorMessageChanged();

private:
    void readInfo();

    QString m_file;
    QFileInfo m_fileInfo;
    QMimeType m_mimeType;
    QStringList m_metaData;
    QString m_errorMessage;
};

#endif // FILEDATA_H
