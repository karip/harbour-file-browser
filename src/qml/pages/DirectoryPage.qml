import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "functions.js" as Functions

Page {
    id: page
    allowedOrientations: Orientation.All
    property string dir: "/"

    FileModel {
        id: fileModel
        dir: page.dir
    }

    SilicaListView {
        id: fileList
        anchors {
            fill: parent
            bottomMargin: notificationPanel.margin
        }

        model: fileModel

        VerticalScrollDecorator { flickable: fileList }

        PullDownMenu {
            MenuItem {
                text: "About"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: "Go to Root"
                onClicked: Functions.goToRoot()
            }
        }

        header: PageHeader { title: Functions.formatPathForTitle(page.dir) }

        delegate: ListItem {
            id: fileItem
            menu: contextMenu
            width: ListView.view.width
            contentHeight: Theme.itemSizeMedium

            Image {
                id: listIcon
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.top: parent.top
                anchors.topMargin: 9
                source: "../images/small-"+fileIcon+".png"
            }
            Label {
                id: listLabel
                anchors.left: listIcon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: parent.top
                anchors.topMargin: 3
                text: filename
                elide: Text.ElideRight
            }
            Label {
                id: listFilesize
                anchors.left: listIcon.right
                anchors.leftMargin: 10
                anchors.top: listLabel.bottom
                text: filekind != "d" ? size : "dir"
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                anchors.top: listLabel.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: filekind+permissions
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                anchors.top: listLabel.bottom
                anchors.right: listLabel.right
                text: modified
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            onClicked: {
                if (listFilesize.text == "dir")
                    pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"),
                                   { dir: fileModel.appendPath(listLabel.text) });
                else
                    pageStack.push(Qt.resolvedUrl("FilePage.qml"),
                                   { file: fileModel.appendPath(listLabel.text) });
            }

            // delete file
            ListView.onRemove: animateRemoval(fileItem)
            function deleteFile() {
                remorseAction("Deleting", function() {
                    if (!fileModel.deleteFile(index))
                        notificationPanel.showWithText("Delete Failed!");
                })
            }

            // context menu is activated with long press
            Component {
                 id: contextMenu
                 ContextMenu {
                     MenuItem {
                         text: "Delete"
                         onClicked: deleteFile();
                     }
                 }
             }
        }

    }
    Label {
        anchors.centerIn: parent
        text: "No files"
        visible: fileModel.fileCount === 0 && fileModel.errorMessage === ""
    }
    Label {
        anchors.centerIn: parent
        text: fileModel.errorMessage
        visible: fileModel.errorMessage !== ""
    }

    // update cover
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            coverPlaceholder.text = "File Browser\n"+Functions.formatPathForCover(page.dir)+"/";
        }
    }

    // notification panel to display messages at top of the screen
    DockedPanel {
        id: notificationPanel

        width: parent.width
        height: Theme.itemSizeExtraLarge + Theme.paddingLarge

        dock: Dock.Top
        open: false
        onOpenChanged: if (open === true) notificationTimer.start()

        function showWithText(txt) {
            notificationText.text = txt;
            notificationPanel.show();
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.7
        }
        Label {
            id: notificationText
            anchors.centerIn: parent
            text: ""
            color: Theme.primaryColor
        }
        Timer {
            id: notificationTimer
            interval: 5000
            onTriggered: {
                notificationPanel.hide()
                stop()
            }
        }
    }
}


