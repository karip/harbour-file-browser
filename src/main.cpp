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
#include "engine.h"
#include "searchengine.h"

int main(int argc, char *argv[])
{
    qmlRegisterType<FileModel>("harbour.file.browser.FileModel", 1, 0, "FileModel");
    qmlRegisterType<FileInfo>("harbour.file.browser.FileInfo", 1, 0, "FileInfo");
    qmlRegisterType<SearchEngine>("harbour.file.browser.SearchEngine", 1, 0, "SearchEngine");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // global engine object
    QScopedPointer<Engine> engine(new Engine);
    view->rootContext()->setContextProperty("engine", engine.data());

    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->show();

    return app->exec();
}
