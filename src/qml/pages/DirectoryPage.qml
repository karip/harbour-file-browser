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
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Create Folder")
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
                text: qsTr("Search")
                onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"),
                                          { dir: page.dir });
            }
            MenuItem {
                text: qsTr("Paste") +
                      (engine.clipboardCount > 0 ? " ("+engine.clipboardCount+")" : "")
                onClicked: {
                    progressPanel.showText(engine.clipboardContainsCopy ?
                                               qsTr("Copying") : qsTr("Moving"))
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

            // background shown when item is selected
            Rectangle {
                anchors.fill: parent
                color: isSelected ? fileItem.highlightedColor : "transparent"
            }

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
                color: isSelected ? Theme.highlightColor : Theme.primaryColor
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
            MouseArea {
                width: 80
                height: parent.height
                onClicked: { fileModel.toggleSelectedFile(index); }
            }

            // delete file after remorse time
            ListView.onRemove: animateRemoval(fileItem)
            function deleteFile(deleteFilename) {
                remorseAction(qsTr("Deleting"), function() {
                    progressPanel.showText(qsTr("Deleting"));
                    engine.deleteFiles([ deleteFilename ]);
                }, 5000)
            }

            // context menu is activated with long press
            Component {
                 id: contextMenu
                 ContextMenu {
                     MenuItem {
                         text: qsTr("Cut")
                         onClicked: engine.cutFiles([ fileModel.fileNameAt(index) ]);
                     }
                     MenuItem {
                         text: qsTr("Copy")
                         onClicked: engine.copyFiles([ fileModel.fileNameAt(index) ]);
                     }
                     MenuItem {
                         text: qsTr("Delete")
                         onClicked:  {
                             deleteFile(fileModel.fileNameAt(index));
                         }
                     }
                     MenuItem {
                         visible: model.isDir
                         text: qsTr("Properties")
                         onClicked:  {
                             pageStack.push(Qt.resolvedUrl("FilePage.qml"),
                                            { file: fileModel.fileNameAt(index) });
                         }
                     }
                 }
             }
        }

        // text if no files or error message
        Text {
            width: parent.width
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            horizontalAlignment: Qt.AlignHCenter
            y: -fileList.contentY + 100
            visible: fileModel.fileCount === 0 || fileModel.errorMessage !== ""
            text: fileModel.errorMessage !== "" ? fileModel.errorMessage : qsTr("No files")
            color: Theme.highlightColor
        }
    }

    // bottom dock panel to display cut & copy controls
    DockedPanel {
        id: dockPanel
        width: parent.width
        open: true
        height: dockColumn.height + Theme.paddingLarge
        contentHeight: height
        dock: Dock.Bottom
        Column {
            id: dockColumn
            anchors.horizontalCenter: parent.horizontalCenter
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("%1 selected").arg(fileModel.selectedFileCount)
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeTiny
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                IconButton {
                    icon.source: "image://theme/icon-l-mute-call"
                    onClicked: { var files = fileModel.selectedFiles(); console.log("CUT!!!"+files); engine.cutFiles(files); }
                }
                IconButton {
                    icon.source: "image://theme/icon-l-copy"
                    onClicked: { var files = fileModel.selectedFiles(); console.log("COPY!!!"+files); engine.copyFiles(files); }
                }
                IconButton {
                    icon.source: "image://theme/icon-l-delete"
                    onClicked: { var files = fileModel.selectedFiles(); console.log("DELETE!!!"); deleteFiles(files); }
                }
                IconButton {
                    visible: fileModel.selectedFileCount === 1
                    icon.source: "image://theme/icon-l-hold"
                    onClicked: {
                        var files = fileModel.selectedFiles();
                        pageStack.push(Qt.resolvedUrl("FilePage.qml"), { file: files[0] });
                    }
                }
                IconButton {
                    icon.source: "image://theme/icon-l-mute-call"
                    onClicked: console.log("SELECT ALL!!!");
                }
            }
        }
    }

    onStatusChanged: {
        // clear file selections when the directory is changed
        fileModel.clearSelectedFiles();

        // update cover
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
                    filename = qsTr("Trying to move between phone and SD Card? It doesn't work, try copying.");
                else if (message === "Failure to write block")
                    filename = qsTr("Perhaps the storage is full?");

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


