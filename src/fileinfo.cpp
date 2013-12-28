#include "fileinfo.h"
#include <QDir>
#include <QDateTime>
#include <QProcess>
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
    if (m_fileInfo.isSymLink()) return "l";
    if (m_fileInfo.isDir()) return "d";
    if (m_fileInfo.isFile()) return "-";
    return "?";
}

QString FileInfo::icon() const
{
    if (m_fileInfo.isSymLink() && m_fileInfo.isDir()) return "folder-link";
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
    if (m_fileInfo.isDir()) return "-";
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

QString FileInfo::suffix() const
{
    return m_fileInfo.suffix().toLower();
}

QString FileInfo::symLinkTarget() const
{
    return m_fileInfo.symLinkTarget();
}

QString FileInfo::errorMessage() const
{
    return m_errorMessage;
}

QString FileInfo::processOutput() const
{
    return m_processOutput;
}

void FileInfo::executeCommand(QString command, QStringList arguments)
{
    m_processOutput.clear();
    emit processOutputChanged();

    // process is killed when Page is closed - should run this in bg thread to allow command finish(?)
    m_process = new QProcess(this);
    m_process->setReadChannel(QProcess::StandardOutput);
    m_process->setProcessChannelMode(QProcess::MergedChannels); // merged stderr channel with stdout channel
    connect(m_process, SIGNAL(readyReadStandardOutput()), this, SLOT(readProcessChannels()));
    connect(m_process, SIGNAL(finished(int, QProcess::ExitStatus)), this, SLOT(handleProcessFinish(int, QProcess::ExitStatus)));
    connect(m_process, SIGNAL(error(QProcess::ProcessError)), this, SLOT(handleProcessError(QProcess::ProcessError)));
    m_process->start(command, arguments);
}

void FileInfo::readProcessChannels()
{
    while (m_process->canReadLine()) {
        QString line = m_process->readLine();
        m_processOutput += line;
    }
    emit processOutputChanged();
}

void FileInfo::handleProcessFinish(int exitCode, QProcess::ExitStatus status)
{
    if (status == QProcess::CrashExit) // if it crashed, then use some error exit code
        exitCode = -99999;
    emit processExited(exitCode);
}

void FileInfo::handleProcessError(QProcess::ProcessError error)
{
    Q_UNUSED(error);
    emit processExited(-88888); // if error, then use some error exit code
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
    emit suffixChanged();
    emit symLinkTargetChanged();
    emit errorMessageChanged();
}
