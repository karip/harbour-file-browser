#ifndef CONSOLEMODEL_H
#define CONSOLEMODEL_H

#include <QAbstractListModel>
#include <QStringList>
#include <QProcess>

/**
 * @brief The ConsoleModel class holds a list of strings for a QML list model.
 */
class ConsoleModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QStringList lines READ lines() WRITE setLines(QString) NOTIFY linesChanged())

public:
    explicit ConsoleModel(QObject *parent = 0);
    ~ConsoleModel();

    // methods needed by ListView
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    // property accessors
    QStringList lines() const { return m_lines; }
    void setLines(QStringList lines);
    void setLines(QString lines);

    void appendLine(QString line);

    Q_INVOKABLE bool executeCommand(QString command, QStringList arguments);

signals:
    void linesChanged();
    void processExited(int exitCode);

private slots:
    void readProcessChannels();
    void handleProcessFinish(int exitCode, QProcess::ExitStatus status);
    void handleProcessError(QProcess::ProcessError error);

private:
    QProcess *m_process;
    QStringList m_lines;
};

#endif // CONSOLEMODEL_H
