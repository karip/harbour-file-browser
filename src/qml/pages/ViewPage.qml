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

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge

            PageHeader { title: Functions.formatPathForCover(page.path) }

            Label {
                id: portraitText
                textFormat: Text.PlainText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.primaryColor
                visible: page.orientation === Orientation.Portrait
            }
            Label {
                id: landscapeText
                textFormat: Text.PlainText
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
                font.pixelSize: portraitText.text === "" ? Theme.fontSizeMedium : Theme.fontSizeTiny
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
            coverPlaceholder.text = Functions.formatPathForCover(page.path);
            // reading file returns three texts, message, portrait and landscape texts
            var txts = engine.readFile(page.path);
            message.text = txts[0];
            portraitText.text = txts[1];
            landscapeText.text = txts[2];
        }
    }
}


