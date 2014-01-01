import QtQuick 2.0
import Sailfish.Silica 1.0
import "functions.js" as Functions

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
                text: qsTr("Show directories first")
            }
            TextSwitch {
                id: showHiddenFiles
                text: qsTr("Show hidden files")
            }
            Item { // used for spacing
                width: parent.width
                height: 40
            }
            Button {
                text: qsTr("About")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
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


