import QtQuick 2.0
import Sailfish.Silica 1.0
import "functions.js" as Functions

Page {
    id: page
    allowedOrientations: Orientation.All
    property string path: ""

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        PullDownMenu {
            MenuItem {
                text: "Go to SD Card"
                onClicked: {
                    var sdcard = Functions.sdcardPath();
                    if (engine.exists(sdcard)) {
                        Functions.goToFolder(sdcard);
                    } else {
                        notificationPanel.showWithText("SD Card not found", sdcard);
                    }
                }
            }
            MenuItem {
                text: "Go to Home"
                onClicked: Functions.goToHome(StandardPaths.documents)
            }
        }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge

            PageHeader { title: Functions.formatPathForCover(page.path) }

            Label {
                id: portraitText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.primaryColor
                visible: page.orientation === Orientation.Portrait
            }
            Label {
                id: landscapeText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.primaryColor
                visible: page.orientation === Orientation.Landscape
            }
            Item { // used for spacing
                width: parent.width
                height: 40
                visible: message.text !== ""
            }
            Label {
                id: message
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.primaryColor
                horizontalAlignment: Text.AlignHCenter
                visible: message.text !== ""
            }
            Item { // used for spacing
                width: parent.width
                height: 40
                visible: message.text !== ""
            }
        }
    }

    // update cover
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            coverPlaceholder.text = "File Browser\n"+Functions.formatPathForCover(page.path);
            // reading file returns three texts, message, portrait and landscape texts
            var txts = engine.readFile(page.path);
            message.text = txts[0];
            portraitText.text = txts[1];
            landscapeText.text = txts[2];
        }
    }
}


