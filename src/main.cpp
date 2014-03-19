#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QScopedPointer>
#include <QQuickView>
#include <QQmlEngine>
#include <QGuiApplication>
#include <QQmlContext>
#include <QtQuick/QQuickPaintedItem>

#include "filemodel.h"
#include "fileinfo.h"
#include "searchengine.h"
#include "engine.h"
#include "consolemodel.h"

int main(int argc, char *argv[])
{
    qmlRegisterType<FileModel>("harbour.file.browser.FileModel", 1, 0, "FileModel");
    qmlRegisterType<FileInfo>("harbour.file.browser.FileInfo", 1, 0, "FileInfo");
    qmlRegisterType<SearchEngine>("harbour.file.browser.SearchEngine", 1, 0, "SearchEngine");
    qmlRegisterType<ConsoleModel>("harbour.file.browser.ConsoleModel", 1, 0, "ConsoleModel");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    // these values are used by QSettings to access the config file in
    // /home/nemo/.local/share/harbour-file-browser/FileBrowser.conf
    QCoreApplication::setOrganizationName("harbour-file-browser");
    QCoreApplication::setApplicationName("FileBrowser");

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // QML global engine object
    QScopedPointer<Engine> engine(new Engine);
    view->rootContext()->setContextProperty("engine", engine.data());

    // store pointer to engine to access it in any class
    QVariant engineVariant = qVariantFromValue(engine.data());
    qApp->setProperty("engine", engineVariant);

    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->show();

    return app->exec();
}
