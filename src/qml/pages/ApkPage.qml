import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.ConsoleModel 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property string command: ""
    property variant arguments // this must be set to a string list, e.g. [ "arg1", "arg2" ]

    // execute command when page activates
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            consoleModel.executeCommand(page.command, page.arguments);
        }
    }

    ConsoleModel {
        id: consoleModel
    }

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

            PageHeader { title: qsTr("Install") }

            Spacer { height: 40 }

            Label {
                text: qsTr("Install launched")
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.highlightColor
            }

            Spacer { height: 40 }

            Label {
                text: qsTr("If the app is already installed or "+
                           "the package is faulty, then nothing happens.")
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }
    }

}


