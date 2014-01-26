import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property string dir: "/"
    property bool initial: false // this is set to true if the page is initial page

    FileModel {
        id: fileModel
        dir: page.dir
        // page.status does not exactly work - root folder seems to be active always??
        active: page.status === PageStatus.Active
    }

    SilicaListView {
        id: fileList
        anchors.fill: parent

        model: fileModel

        VerticalScrollDecorator { flickable: fileList }

        PullDownMenu {
            MenuItem {
                text: "Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: "Create Folder"
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("CreateFolderDialog.qml"),
                                          { path: page.dir })
                    dialog.accepted.connect(function() {
                        if (dialog.errorMessage !== "")
                            notificationPanel.showText(dialog.errorMessage, "")
                    })
                }
            }
            MenuItem {
                text: "Search"
                onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                                          { dir: page.dir });
            }
            MenuItem {
                text: "Paste" + (engine.clipboardCount > 0 ? " ("+engine.clipboardCount+")" : "")
                onClicked: {
                    progressPanel.showText(engine.clipboardContainsCopy ? "Copying" : "Moving")
                    engine.pasteFiles(page.dir);
                }
            }
        }

        header: PageHeader {
            title: Functions.formatPathForTitle(page.dir) + " " +
                   Functions.unicodeBlackDownPointingTriangle()
            MouseArea {
                anchors.fill: parent
                onClicked: dirPopup.show();
            }
        }

        delegate: ListItem {
            id: fileItem
            menu: contextMenu
            width: ListView.view.width
            contentHeight: listLabel.height+listSize.height + 13

            Image {
                id: listIcon
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.top: parent.top
                anchors.topMargin: 11
                source: "../images/small-"+fileIcon+".png"
            }
            Label {
                id: listLabel
                anchors.left: listIcon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: parent.top
                anchors.topMargin: 5
                text: filename
                elide: Text.ElideRight
            }
            Label {
                id: listSize
                anchors.left: listIcon.right
                anchors.leftMargin: 10
                anchors.top: listLabel.bottom
                text: !(isLink && isDir) ? size : Functions.unicodeArrow()+" "+symLinkTarget
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                visible: !(isLink && isDir)
                anchors.top: listLabel.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: filekind+permissions
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                visible: !(isLink && isDir)
                anchors.top: listLabel.bottom
                anchors.right: listLabel.right
                text: modified
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            onClicked: {
                if (model.isDir)
                    pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"),
                                   { dir: fileModel.appendPath(listLabel.text) });
                else
                    pageStack.push(Qt.resolvedUrl("FilePage.qml"),
                                   { file: fileModel.appendPath(listLabel.text) });
            }

            // delete file after remorse time
            ListView.onRemove: animateRemoval(fileItem)
            function deleteFile(deleteFilename) {
                remorseAction("Deleting", function() {
                    progressPanel.showText("Deleting");
                    engine.deleteFiles([ deleteFilename ]);
                }, 5000)
            }

            // context menu is activated with long press
            Component {
                 id: contextMenu
                 ContextMenu {
                     MenuItem {
                         text: "Cut"
                         onClicked: engine.cutFiles([ fileModel.fileNameAt(index) ]);
                     }
                     MenuItem {
                         text: "Copy"
                         onClicked: engine.copyFiles([ fileModel.fileNameAt(index) ]);
                     }
                     MenuItem {
                         text: "Delete"
                         onClicked:  {
                             deleteFile(fileModel.fileNameAt(index));
                         }
                     }
                     MenuItem {
                         visible: model.isDir
                         text: "Properties"
                         onClicked:  {
                             pageStack.push(Qt.resolvedUrl("FilePage.qml"),
                                            { file: fileModel.fileNameAt(index) });
                         }
                     }
                 }
             }
        }

    }

    // no files text
    Label {
        anchors.centerIn: parent
        text: "No files"
        visible: fileModel.fileCount === 0 && fileModel.errorMessage === ""
    }
    // error text
    Label {
        anchors.centerIn: parent
        text: fileModel.errorMessage
        visible: fileModel.errorMessage !== ""
    }

    // update cover
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            coverPlaceholder.text = Functions.lastPartOfPath(page.dir)+"/";

            // go to Home on startup
            if (page.initial) {
                page.initial = false;
                Functions.goToHome();
            }
        }
    }

    DirPopup {
        id: dirPopup
        anchors.fill: parent
        menuTop: 100
    }

    // connect signals from engine to panels
    Connections {
        target: engine
        onProgressChanged: progressPanel.text = engine.progressFilename
        onWorkerDone: progressPanel.hide()
        onWorkerErrorOccurred: {
            // the error signal goes to all pages in pagestack, show it only in the active one
            if (progressPanel.open) {
                progressPanel.hide();
                if (message === "Unknown error")
                    filename = "Trying to move between phone and SD Card? It doesn't work, try copying.";
                else if (message === "Failure to write block")
                    filename = "Perhaps the storage is full?";

                notificationPanel.showText(message, filename);
            }
        }
    }

    NotificationPanel {
        id: notificationPanel
        page: page
    }

    ProgressPanel {
        id: progressPanel
        page: page
        onCancelled: engine.cancel()
    }

}


