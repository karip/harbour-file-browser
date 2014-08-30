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
    property bool remorsePopupOpen: false // set to true when remorsePopup is active

    FileModel {
        id: fileModel
        dir: page.dir
        // page.status does not exactly work - root folder seems to be active always??
        active: page.status === PageStatus.Active
    }

    RemorsePopup {
        id: remorsePopup
        onCanceled: remorsePopupOpen = false
        onTriggered: remorsePopupOpen = false
    }

    SilicaListView {
        id: fileList
        anchors.fill: parent
        anchors.bottomMargin: selectionPanel.visible ? selectionPanel.visibleSize : 0
        clip: true

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
                    if (remorsePopupOpen) return;
                    progressPanel.showText(engine.clipboardContainsCopy ?
                                               qsTr("Copying") : qsTr("Moving"))
                    fileModel.clearSelectedFiles();
                    selectionPanel.open = false;
                    selectionPanel.overrideText = "";
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
                visible: isSelected
                anchors.fill: parent
                color: fileItem.highlightedColor
            }

            Image {
                id: listIcon
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.top: parent.top
                anchors.topMargin: 11
                source: "../images/small-"+fileIcon+".png"
            }
            // circle shown when item is selected
            Label {
                visible: isSelected
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge-4
                anchors.top: parent.top
                anchors.topMargin: 3
                text: "\u25cb"
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
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
                color: fileItem.highlighted || isSelected ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: listSize
                anchors.left: listIcon.right
                anchors.leftMargin: 10
                anchors.top: listLabel.bottom
                text: !(isLink && isDir) ? size : Functions.unicodeArrow()+" "+symLinkTarget
                color: fileItem.highlighted || isSelected ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                visible: !(isLink && isDir)
                anchors.top: listLabel.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: filekind+permissions
                color: fileItem.highlighted || isSelected ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                visible: !(isLink && isDir)
                anchors.top: listLabel.bottom
                anchors.right: listLabel.right
                text: modified
                color: fileItem.highlighted || isSelected ? Theme.secondaryHighlightColor : Theme.secondaryColor
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
                width: 90
                height: parent.height
                onClicked: {
                    fileModel.toggleSelectedFile(index);
                    selectionPanel.open = (fileModel.selectedFileCount > 0);
                    selectionPanel.overrideText = "";
                }
            }

            // context menu is activated with long press
            Component {
                 id: contextMenu
                 ContextMenu {
                     // cancel delete if context menu is opened
                     onActiveChanged: remorsePopup.cancel()
                     MenuItem {
                         text: qsTr("Changed! Try tapping the file icons")
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

    // a bit hackery: called from selection panel
    function selectedFiles() { var files = fileModel.selectedFiles(); return files; }

    SelectionPanel {
        id: selectionPanel
        selectedCount: fileModel.selectedFileCount
        enabled: !page.remorsePopupOpen

        onDeleteTriggered: {
            var files = fileModel.selectedFiles();
            remorsePopupOpen = true;
            remorsePopup.execute("Deleting", function() {
                fileModel.clearSelectedFiles();
                selectionPanel.open = false;
                selectionPanel.overrideText = "";
                console.log("delete"+files);
                engine.deleteFiles(files);
            });
        }
        onPropertyTriggered: {
            var files = fileModel.selectedFiles();
            pageStack.push(Qt.resolvedUrl("FilePage.qml"), { file: files[0] });
        }
    }

    onStatusChanged: {
        // clear file selections when the directory is changed
        fileModel.clearSelectedFiles();
        selectionPanel.open = false;
        selectionPanel.overrideText = "";

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


