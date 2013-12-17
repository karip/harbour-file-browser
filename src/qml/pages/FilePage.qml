import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileInfo 1.0
import "functions.js" as Functions

// File page of File Browser
Page {
    id: page
    allowedOrientations: Orientation.All
    property string file: "/"

    FileInfo {
        id: fileInfo
        file: page.file
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: childrenRect.height
        PullDownMenu {
            MenuItem {
                text: "Go to root"
                onClicked: Functions.goToRoot()
            }
        }

        PageHeader {
            id: pageHeader
            title: Functions.formatPathForTitle(fileInfo.absolutePath)
        }

        Column {
            anchors.top: pageHeader.bottom
            anchors.bottom: parent.bottom
            width: parent.width
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            visible: fileInfo.errorMessage === ""

            Image {
                id: icon
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                source: "../images/large-"+fileInfo.icon+".png"
            }
            Label {
                width: parent.width
                text: fileInfo.name
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
            Label {
                visible: fileInfo.symLinkTarget !== ""
                width: parent.width
                text: "\u2192 "+fileInfo.symLinkTarget // uses unicode arrow
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Item { // used for spacing
                width: parent.width
                height: 40
            }
            Row {
                width: parent.width
                spacing: 10
                Label {
                    id: firstLabel
                    text: "Location"
                    color: Theme.secondaryColor
                    width: parent.width/2
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Label {
                    text: fileInfo.absolutePath
                    wrapMode: Text.Wrap
                    width: parent.width/2
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
            Row {
                width: parent.width
                spacing: 10
                Label {
                    text: "Size"
                    color: Theme.secondaryColor
                    width: parent.width/2
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Label {
                    text: fileInfo.size
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
            Row {
                spacing: 10
                Label {
                    text: "Permissions"
                    color: Theme.secondaryColor
                    width: firstLabel.width
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Label {
                    text: fileInfo.permissions
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
            Row {
                spacing: 10
                Label {
                    text: "Last modified"
                    color: Theme.secondaryColor
                    width: firstLabel.width
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Label {
                    text: fileInfo.modified
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
            Row {
                spacing: 10
                Label {
                    text: "Created"
                    color: Theme.secondaryColor
                    width: firstLabel.width
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Label {
                    text: fileInfo.created
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
        }

        Label {
            anchors.centerIn: parent
            text: fileInfo.errorMessage
            visible: fileInfo.errorMessage !== ""
        }
    }

    // update cover
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            coverPlaceholder.text = "File Browser\n"+Functions.formatPathForCover(page.file);
        }
    }
}


