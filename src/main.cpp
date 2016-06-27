#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QScopedPointer>
#include <QQuickView>
#include <QQmlEngine>
#include <QGuiApplication>
#include <QTranslator>
#include <QQmlContext>
#include <QtQuick/QQuickPaintedItem>

#include "filemodel.h"
#include "filedata.h"
#include "searchengine.h"
#include "engine.h"
#include "consolemodel.h"

int main(int argc, char *argv[])
{
    // CONFIG += sailfishapp sets up QCoreApplication::OrganizationName and ApplicationName
    // so that QSettings can access the app's config file at
    // /home/nemo/.config/harbour-file-browser/harbour-file-browser.conf

    qmlRegisterType<FileModel>("harbour.file.browser.FileModel", 1, 0, "FileModel");
    qmlRegisterType<FileData>("harbour.file.browser.FileData", 1, 0, "FileData");
    qmlRegisterType<SearchEngine>("harbour.file.browser.SearchEngine", 1, 0, "SearchEngine");
    qmlRegisterType<ConsoleModel>("harbour.file.browser.ConsoleModel", 1, 0, "ConsoleModel");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    QTranslator translator;
    QString locale = QLocale::system().name();
    //locale="de"; // for testing purposes only
    if(!translator.load("file-browser_" + locale, SailfishApp::pathTo("i18n").toLocalFile())) {
        qDebug() << "Couldn't load translation for locale "+locale + " from " + SailfishApp::pathTo("i18n").toLocalFile();
    }
    app->installTranslator(&translator);

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // QML global engine object
    QScopedPointer<Engine> engine(new Engine);
    view->rootContext()->setContextProperty("engine", engine.data());

    // store pointer to engine to access it in any class, to make it a singleton
    QVariant engineVariant = qVariantFromValue(engine.data());
    qApp->setProperty("engine", engineVariant);

    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->show();

    return app->exec();
}
