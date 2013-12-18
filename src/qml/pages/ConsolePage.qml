import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileInfo 1.0

Page {
    id: page
    allowedOrientations: Orientation.All
    property string title: ""
    property string command: ""
    property variant arguments // this should be set to a string list, e.g. [ "arg1", "arg2" ]
    property string initialText: "Installing..."
    property string successText: "Successful"
    property string infoText: ""
    property color consoleColor: Theme.secondaryColor

    // execute command when page activates
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            fileInfo.executeCommand(page.command, page.arguments);
        }
    }

    FileInfo {
        id: fileInfo

        // called when command exits
        onProcessExited: {
            busyIndicator.running = false;
            if (exitCode == 0) {
                statusLabel.text = page.successText;
                infoLabel.text = page.infoText;
            } else {
                statusLabel.text = "Failed! Error code: "+exitCode;
            }
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            width: parent.width
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge

            PageHeader { title: page.title }

            BusyIndicator {
                id: busyIndicator
                anchors.horizontalCenter: parent.horizontalCenter
                running: true
                size: BusyIndicatorSize.Small
            }
            Label {
                id: statusLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.initialText
            }
            Label {
                id: infoLabel
                visible: text !== ""
                text: ""
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeTiny
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
            }

            Item { width: parent.width; height: 40 } // used for spacing

            // command line text
            Label {
                width: parent.width
                text: "$ "+page.command+" "+page.arguments.join(" ")
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.secondaryColor
            }

            // command output
            Label {
                width: parent.width
                text: fileInfo.processOutput
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: page.consoleColor
            }
        }
    }
}


