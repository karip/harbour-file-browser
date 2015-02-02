#include "consolemodel.h"
#include "globals.h"

enum {
    ModelDataRole = Qt::UserRole + 1
};

ConsoleModel::ConsoleModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_process = new QProcess(this);
}

ConsoleModel::~ConsoleModel()
{
}

int ConsoleModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_lines.count();
}

QVariant ConsoleModel::data(const QModelIndex &index, int role) const
{
    Q_UNUSED(role);
    if (!index.isValid() || index.row() > m_lines.count()-1)
        return QVariant();

    QString line = m_lines.at(index.row());
    return line;
}

QHash<int, QByteArray> ConsoleModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(ModelDataRole, QByteArray("modelData"));
    return roles;
}

void ConsoleModel::setLines(QStringList lines)
{
    if (m_lines == lines)
        return;

    beginResetModel();
    m_lines = lines;
    endResetModel();

    emit linesChanged();
}

void ConsoleModel::setLines(QString lines)
{
    beginResetModel();
    m_lines = lines.split(QRegExp("[\n\r]"));
    endResetModel();
    emit linesChanged();
}

void ConsoleModel::appendLine(QString line)
{
    beginInsertRows(QModelIndex(), m_lines.count(), m_lines.count());
    m_lines.append(line);
    endInsertRows();
}

void ConsoleModel::executeCommand(QString command, QStringList arguments)
{
    // process is killed when Page is closed - should run this in bg thread to allow command finish(?)
    if(m_process->state()!=QProcess::NotRunning) //the process is still busy
        if(!m_process->waitForFinished(500)) //wait for it to finish
            return;
    setLines(QStringList());
    m_process = new QProcess(this);
    m_process->setReadChannel(QProcess::StandardOutput);
    m_process->setProcessChannelMode(QProcess::MergedChannels); // merged stderr channel with stdout channel
    connect(m_process, SIGNAL(readyReadStandardOutput()), this, SLOT(readProcessChannels()));
    connect(m_process, SIGNAL(finished(int, QProcess::ExitStatus)), this, SLOT(handleProcessFinish(int, QProcess::ExitStatus)));
    connect(m_process, SIGNAL(error(QProcess::ProcessError)), this, SLOT(handleProcessError(QProcess::ProcessError)));
    m_process->start(command, arguments);
}

void ConsoleModel::readProcessChannels()
{
    while (m_process->canReadLine()) {
        QString line = m_process->readLine();
        appendLine(line);
    }
}

void ConsoleModel::handleProcessFinish(int exitCode, QProcess::ExitStatus status)
{
    if (status == QProcess::CrashExit) { // if it crashed, then use some error exit code
        exitCode = -99999;
        appendLine(tr("** crashed"));

    } else if (exitCode != 0) {
        appendLine(tr("** error: %1").arg(exitCode));
    }
    emit processExited(exitCode);
}

void ConsoleModel::handleProcessError(QProcess::ProcessError error)
{
    Q_UNUSED(error);
    emit processExited(-88888); // if error, then use some error exit code
    appendLine(tr("** error"));
}
