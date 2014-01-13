import QtQuick 2.0
import Sailfish.Silica 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge

            PageHeader { title: qsTr("Settings") }

            TextSwitch {
                id: showDirsFirst
                text: qsTr("Show folders first")
            }
            TextSwitch {
                id: showHiddenFiles
                text: qsTr("Show hidden files")
            }

            LagoonSpacer { height: 40 }

            Label {
                text: qsTr("About File Browser")
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                horizontalAlignment: Text.AlignRight
                color: Theme.highlightColor
            }
            LagoonSpacer { height: 20 }
            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                text: qsTr("Version 1.4.0") // Version number must be changed manually!
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
            }
            LagoonSpacer { height: 20 }
            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                text: "File Browser is free and unencumbered software released "+
                      "into the public domain.\nRead full text >>"
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor

                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                }
            }

            LagoonSpacer { height: 20 }
            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                text: qsTr("The source code is available at\nhttps://github.com/karip/harbour-file-browser")
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
            }
        }
    }

    onStatusChanged: {
        // update cover
        if (status === PageStatus.Activating)
            coverPlaceholder.text = qsTr("Settings");

        // read settings
        if (status === PageStatus.Activating) {
            showDirsFirst.checked = (engine.readSetting("show-dirs-first") === "true");
            showHiddenFiles.checked = (engine.readSetting("show-hidden-files") === "true");
        }

        // write settings
        if (status === PageStatus.Deactivating) {
            engine.writeSetting("show-dirs-first", showDirsFirst.checked.toString());
            engine.writeSetting("show-hidden-files", showHiddenFiles.checked.toString());
        }
    }
}


