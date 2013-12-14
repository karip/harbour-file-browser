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

int main(int argc, char *argv[])
{
    qmlRegisterType<FileModel>("FileModel", 1, 0, "FileModel");
    qmlRegisterType<FileInfo>("FileInfo", 1, 0, "FileInfo");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->show();

    return app->exec();
}
