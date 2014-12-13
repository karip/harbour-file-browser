TEMPLATE=app
TARGET = harbour-file-browser

CONFIG += sailfishapp

SOURCES += main.cpp filemodel.cpp filedata.cpp engine.cpp fileworker.cpp searchengine.cpp \
           searchworker.cpp consolemodel.cpp statfileinfo.cpp globals.cpp
HEADERS += filemodel.h filedata.h engine.h fileworker.h searchengine.h searchworker.h \
           consolemodel.h statfileinfo.cpp globals.h

SOURCES += jhead/jhead-api.cpp jhead/exif.c jhead/gpsinfo.c jhead/iptc.c jhead/jpgfile.c \
           jhead/jpgqguess.c jhead/makernote.c
HEADERS += jhead/jhead-api.h jhead/jhead.h

i18n.path = /usr/share/harbour-file-browser/i18n
i18n.files = i18n/file-browser_de.qm \
             i18n/file-browser_fi.qm

INSTALLS += i18n

TRANSLATIONS = \
    i18n/file-browser_de.ts \
    i18n/file-browser_fi.ts

lupdate_only {
SOURCES += \
    qml/*.qml \
    qml/pages/*.qml \
    qml/components/*.qml
}


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
    qml/pages/ConsolePage.qml \
    qml/pages/SearchPage.qml \
    qml/pages/ViewPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/CreateFolderDialog.qml \
    qml/pages/RenameDialog.qml \
    qml/pages/PermissionsDialog.qml \
    qml/pages/AboutPage.qml \
    qml/components/DirPopup.qml \
    qml/components/Spacer.qml \
    qml/components/CenteredField.qml \
    qml/components/LetterSwitch.qml \
    qml/components/DoubleMenuItem.qml \
    qml/components/InteractionBlocker.qml \
    qml/components/NotificationPanel.qml \
    qml/components/ProgressPanel.qml \
    qml/components/SelectionPanel.qml \
    qml/main.qml \
    qml/functions.js \
    i18n/file-browser_de.ts \
    i18n/file-browser_fi.ts

INCLUDEPATH += $$PWD
