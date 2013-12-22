import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileModel 1.0
import "functions.js" as Functions

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
                text: "Paste" + (engine.clipboardCount > 0 ? " ("+engine.clipboardCount+")" : "")
                onClicked: {
                    progressPanel.showWithText(engine.clipboardCut ? "Moving" : "Copying")
                    engine.pasteFiles(page.dir);
                }
            }
            MenuItem {
                text: "Go to Root"
                onClicked: Functions.goToRoot()
            }
            MenuItem {
                text: "Go to Home"
                onClicked: Functions.goToHome(StandardPaths.documents, page.dir)
            }
        }

        header: PageHeader { title: Functions.formatPathForTitle(page.dir) }

        delegate: ListItem {
            id: fileItem
            menu: contextMenu
            width: ListView.view.width

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

            // delete file after remorse time
            ListView.onRemove: animateRemoval(fileItem)
            function deleteFile() {
                remorseAction("Deleting", function() {
                    progressPanel.showWithText("Deleting");
                    engine.deleteFiles([ fileModel.fileNameAt(index) ]);
                }, 3)
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
                             deleteFile();
                         }
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

            // go to Home on startup
            if (page.initial) {
                page.initial = false;
                Functions.goToHome(StandardPaths.documents);
            }
        }
    }

    Rectangle {
        id: interactionBlocker

        anchors.fill: parent
        visible: false
        color: "#808080"
        opacity: 0.3

        MouseArea {
            anchors.fill: parent
            enabled: true
            // if blocker is clicked and notification panel is open, then close it
            // otherwise, this only blocks all clicks to underlying items
            onClicked: {
                if (notificationPanel.open)
                    notificationPanel.hide();
            }
        }
        // use a timer to delay the visibility of interaction blocker by adjusting opacity
        // this is done to prevent flashing if the file operation is fast
        onVisibleChanged: {
            if (visible === true) {
                interactionBlocker.opacity = 0;
                blockerTimer.start();
            } else {
                blockerTimer.stop();
            }
        }
        Timer {
            id: blockerTimer
            interval: 200
            onTriggered: {
                interactionBlocker.opacity = 0.3;
                stop();
            }
        }
    }

    // notification panel to display messages at top of the screen
    DockedPanel {
        id: notificationPanel

        width: parent.width
        height: Theme.itemSizeExtraLarge + Theme.paddingLarge

        dock: Dock.Top
        open: false
        onOpenChanged: {
            interactionBlocker.visible = open; // disable row selection and menus
            page.backNavigation = !open; // disable back navigation
        }

        function showWithText(header, txt) {
            notificationHeader.text = header;
            notificationText.text = txt;
            notificationPanel.show();
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.7
        }
        MouseArea {
            anchors.fill: parent
            enabled: true
            onClicked: notificationPanel.hide()
        }
        Label {
            id: notificationHeader
            visible: notificationPanel.open
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            anchors.topMargin: 40
            horizontalAlignment: Text.AlignHCenter
            text: ""
            wrapMode: Text.Wrap
            color: Theme.primaryColor
        }
        Label {
            id: notificationText
            visible: notificationPanel.open
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: notificationHeader.bottom
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            horizontalAlignment: Text.AlignHCenter
            text: ""
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.primaryColor
        }
    }

    // progress panel to display progress
    DockedPanel {
        id: progressPanel

        width: parent.width
        height: Theme.itemSizeExtraLarge + Theme.paddingLarge

        dock: Dock.Top
        open: false
        onOpenChanged: {
            interactionBlocker.visible = open; // disable row selection and menus
            page.backNavigation = !open; // disable back navigation
        }

        Connections {
            target: engine
            onProgressChanged: progressText.text = engine.progressFilename
            onWorkerDone: progressPanel.hide()
            onWorkerCancelDone: progressPanel.hide()
            onWorkerErrorOccurred: {
                // the error signal goes to all pages in pagestack, show it only in the active one
                if (progressPanel.open) {
                    progressPanel.hide();
                    notificationPanel.showWithText(message, filename);
                }
            }
        }

        function showWithText(txt) {
            progressHeader.text = txt;
            progressPanel.show();
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.7
        }
        BusyIndicator {
            id: progressBusy
            anchors.right: progressHeader.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.verticalCenter: parent.verticalCenter
            running: true
            size: BusyIndicatorSize.Small
        }
        Label {
            id: progressHeader
            visible: progressPanel.open
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.leftMargin: progressBusy.width + Theme.paddingLarge*4
            anchors.rightMargin: Theme.paddingLarge
            text: ""
            color: Theme.primaryColor
        }
        Label {
            id: progressText
            visible: progressPanel.open
            anchors.left: progressHeader.left
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingLarge
            anchors.top: progressHeader.bottom
            text: ""
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.primaryColor
        }
    }
}


