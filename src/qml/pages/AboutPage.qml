import QtQuick 2.0
import Sailfish.Silica 1.0

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

            PageHeader { title: "About File Browser" }

            Item { // used for spacing, different spacing for portrait and landscape
                width: parent.width
                height: page.orientation === Orientation.Portrait ? 150 : 0
            }

            Image {
                id: icon
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                source: "../images/harbour-file-browser.png"
            }
            Item { // used for spacing
                width: parent.width
                height: 20
            }
            Label {
                width: parent.width
                text: "Browse files on your phone"
                horizontalAlignment: Text.AlignHCenter
            }
            Item { // used for spacing
                width: parent.width
                height: 40
            }
            Label {
                width: parent.width
                text: "Version 1.3" // Version number must be changed manually!
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }
            Label {
                width: parent.width
                text: "Created by Kari\n\n"+
                      "File Browser is free and unencumbered software released into the public domain."
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }
            Item { // used for spacing
                width: parent.width
                height: 40
            }
            Label {
                width: parent.width
                text: "The source code is available at\nhttps://github.com/karip/harbour-file-browser"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
            }
        }
    }
}


