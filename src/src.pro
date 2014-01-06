TEMPLATE=app
TARGET = harbour-file-browser

# In the bright future this config line will do a lot of stuff to you
#CONFIG += sailfishapp

# Start of temporary fix for the icon for the Nov 2013 harbour requirements, basically reimplements
# what CONFIG += sailfishapp is supposed to do manually (with small corrections)
# QML files and folders
QT += quick qml
CONFIG += link_pkgconfig
PKGCONFIG += sailfishapp

INCLUDEPATH += /usr/include/sailfishapp

TARGETPATH = /usr/bin
target.path = $$TARGETPATH

DEPLOYMENT_PATH = /usr/share/$$TARGET
qml.files = qml
qml.path = $$DEPLOYMENT_PATH

desktop.files = harbour-file-browser.desktop
desktop.path = /usr/share/applications

icon.files = harbour-file-browser.png
icon.path = /usr/share/icons/hicolor/86x86/apps

INSTALLS += target icon desktop  qml
# End of Nov 2013 fix

SOURCES += main.cpp filemodel.cpp fileinfo.cpp engine.cpp fileworker.cpp searchengine.cpp \
           searchworker.cpp globals.cpp
HEADERS += filemodel.h fileinfo.h engine.h fileworker.h searchengine.h searchworker.h globals.h

OTHER_FILES = \
# You DO NOT want .yaml be listed here as Qt Creator's editor is completely not ready for multi package .yaml's
#
# Also Qt Creator as of Nov 2013 will anyway try to rewrite your .yaml whenever you change your .pro
# Well, you will just have to restore .yaml from version control again and again unless you figure out
# how to kill this particular Creator's plugin
#    ../rpm/harbour-file-browser.yaml \
    ../rpm/harbour-file-browser.spec \
    qml/pages/DirectoryPage.qml \
    qml/pages/FilePage.qml \
    qml/pages/ViewPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/AboutPage.qml \
    qml/components/DirPopup.qml \
    qml/main.qml \
    qml/functions.js

INCLUDEPATH += $$PWD
