TEMPLATE=app
TARGET = harbour-file-browser

CONFIG += sailfishapp

SOURCES += main.cpp filemodel.cpp filedata.cpp engine.cpp fileworker.cpp searchengine.cpp \
           searchworker.cpp consolemodel.cpp statfileinfo.cpp globals.cpp
HEADERS += filemodel.h filedata.h engine.h fileworker.h searchengine.h searchworker.h \
           consolemodel.h statfileinfo.h globals.h

SOURCES += jhead/jhead-api.cpp jhead/exif.c jhead/gpsinfo.c jhead/iptc.c jhead/jpgfile.c \
           jhead/jpgqguess.c jhead/makernote.c
HEADERS += jhead/jhead-api.h jhead/jhead.h

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

i18n.path = /usr/share/harbour-file-browser/i18n
i18n.files = i18n/file-browser_de.qm \
             i18n/file-browser_el.qm \
             i18n/file-browser_es.qm \
             i18n/file-browser_fi.qm \
             i18n/file-browser_fr.qm \
             i18n/file-browser_it_IT.qm \
             i18n/file-browser_nl.qm \
             i18n/file-browser_ru_RU.qm \
             i18n/file-browser_sv.qm \
             i18n/file-browser_zh_CN.qm

INSTALLS += i18n

# automatic generation of the translation .qm files from .ts files
system(lrelease $$PWD/i18n/*.ts)

TRANSLATIONS = \
    i18n/file-browser_de.ts \
    i18n/file-browser_el.ts \
    i18n/file-browser_es.ts \
    i18n/file-browser_fi.ts \
    i18n/file-browser_fr.ts \
    i18n/file-browser_it_IT.ts \
    i18n/file-browser_nl.ts \
    i18n/file-browser_ru_RU.ts \
    i18n/file-browser_sv.ts \
    i18n/file-browser_zh_CN.ts

lupdate_only {
SOURCES += \
    qml/*.qml \
    qml/cover/*.qml \
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
    qml/pages/*.qml \
    qml/cover/*.qml \
    qml/components/*.qml \
    qml/*.qml \
    qml/functions.js \
    i18n/*.ts

INCLUDEPATH += $$PWD
