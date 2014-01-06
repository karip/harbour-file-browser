import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.SearchEngine 1.0
import "functions.js" as Functions

Page {
    id: page
    allowedOrientations: Orientation.All
    showNavigationIndicator: false // hide back indicator because it would be on top of search field
    property string dir: "/"
    property string currentDirectory: ""

    // this and its bg worker thread will be destroyed when page in popped from stack
    SearchEngine {
        id: searchEngine
        dir: page.dir

        onProgressChanged: page.currentDirectory = directory
        onMatchFound: listModel.append({ fullname: fullname, filename: filename,
                                           absoluteDir: absoluteDir,
                                           fileIcon: fileIcon, fileKind: fileKind });
        onWorkerDone: { clearCover(); }
        onWorkerErrorOccurred: { clearCover(); notificationPanel.showWithText(message, filename); }
    }

    SilicaListView {
        id: fileList
        anchors.fill: parent

        // prevent newly added list delegates from stealing focus away from the search field
        currentIndex: -1

        model: ListModel {
            id: listModel

            function update(txt) {
                if (txt === "")
                    searchEngine.cancel();

                clear();
                if (txt !== "") {
                    searchEngine.search(txt);
                    coverPlaceholder.text = "Searching\n"+txt;
                }
            }

            Component.onCompleted: update("")
        }

        VerticalScrollDecorator { flickable: fileList }

        PullDownMenu {
            MenuItem {
                text: "Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
        }

        header: Item {
            width: parent.width
            height: 110

            SearchField {
                id: searchField
                anchors.left: parent.left
                anchors.right: cancelSearchButton.left
                placeholderText: "Search "+Functions.formatPathForSearch(page.dir)
                inputMethodHints: Qt.ImhNoAutoUppercase

                // get focus when page is shown for the first time
                Component.onCompleted: forceActiveFocus()

                // return key on virtual keyboard starts or restarts search
                Keys.onPressed: {
                    notificationPanel.hide();
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        listModel.update(searchField.text);
                        foundText.visible = true;
                        searchField.focus = false;
                    }
                }
            }
            // our own "IconButton" to make the mouse area large and easier to tap
            Rectangle {
                id: cancelSearchButton
                anchors.right: parent.right
                anchors.top: searchField.top
                width: Theme.iconSizeMedium+Theme.paddingLarge
                height: searchField.height
                color: cancelSearchMouseArea.pressed ? Theme.secondaryHighlightColor : "transparent"
                MouseArea {
                    id: cancelSearchMouseArea
                    anchors.fill: parent
                    onClicked: {
                        if (!searchEngine.running) {
                            listModel.update(searchField.text);
                            foundText.visible = true;
                        } else {
                            searchEngine.cancel()
                        }
                    }
                    enabled: true
                    Image {
                        id: cancelSearchButtonImage
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingLarge
                        source: searchEngine.running ? "image://theme/icon-m-clear" :
                                                       "image://theme/icon-m-right"
                    }
                    BusyIndicator {
                        id: searchBusy
                        anchors.centerIn: cancelSearchButtonImage
                        running: searchEngine.running
                        size: BusyIndicatorSize.Small
                    }
                }
            }
            Label {
                id: foundText
                visible: false
                anchors.left: parent.left
                anchors.leftMargin: searchField.textLeftMargin
                anchors.top: searchField.bottom
                anchors.topMargin: -26
                text: listModel.count+" hits"
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
            }
            Label {
                anchors.left: parent.left
                anchors.leftMargin: 240
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: searchField.bottom
                anchors.topMargin: -26
                text: page.currentDirectory
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
                elide: Text.ElideRight
            }
        }

        delegate: ListItem {
            id: fileItem
            menu: contextMenu
            width: ListView.view.width
            contentHeight: listLabel.height+listAbsoluteDir.height + 13

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
                id: listAbsoluteDir
                anchors.left: listIcon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: listLabel.bottom
                text: absoluteDir
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                elide: Text.ElideLeft
            }

            onClicked: {
                if (model.fileKind === "d")
                    pageStack.push(Qt.resolvedUrl("DirectoryPage.qml"),
                                   { dir: model.fullname });
                else
                    pageStack.push(Qt.resolvedUrl("FilePage.qml"),
                                   { file: model.fullname });
            }

            // delete file after remorse time
            ListView.onRemove: animateRemoval(fileItem)
            function deleteFile(deleteFilename) {
                remorseAction("Deleting", function() {
                    progressPanel.showWithText("Deleting");
                    engine.deleteFiles([ deleteFilename ]);
                }, 5000)
            }

            // context menu is activated with long press, visible if search is not running
            Component {
                 id: contextMenu
                 ContextMenu {
                     MenuItem {
                         text: "Go to containing folder"
                         onClicked: Functions.goToFolder(model.absoluteDir)
                     }
                     MenuItem {
                         text: "Cut"
                         onClicked: engine.cutFiles([ model.fullname ]);
                     }
                     MenuItem {
                         text: "Copy"
                         onClicked: engine.copyFiles([ model.fullname ]);
                     }
                     MenuItem {
                         text: "Delete"
                         onClicked: deleteFile(model.fullname);
                     }
                 }
             }
        }

    }

    // update cover
    onStatusChanged: {
        if (status === PageStatus.Activating)
            clearCover();
    }

    Rectangle {
        id: interactionBlocker

        anchors.fill: parent
        visible: false
        color: "#000000"
        opacity: 0.4

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
            interval: 300
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
            onWorkerErrorOccurred: {
                // the error signal goes to all pages in pagestack, show it only in the active one
                if (progressPanel.open) {
                    progressPanel.hide();
                    notificationPanel.showWithText(message, filename);
                }
            }

            // item got deleted by worker, so remove it from list
            onFileDeleted: {
                for (var i = 0; i < listModel.count; ++i) {
                    var item = listModel.get(i);
                    if (item.fullname === fullname) {
                        listModel.remove(i)
                        return;
                    }
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
        Rectangle {
            id: cancelButton
            anchors.right: parent.right
            width: 100
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: cancelMouseArea.pressed ? Theme.secondaryHighlightColor : "transparent"
            MouseArea {
                id: cancelMouseArea
                anchors.fill: parent
                onClicked: engine.cancel()
                enabled: true
                Text {
                    anchors.centerIn: parent
                    color: Theme.primaryColor
                    text: "X"
                }
            }
        }
        Label {
            id: progressHeader
            visible: progressPanel.open
            anchors.left: parent.left
            anchors.right: cancelButton.left
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
            anchors.right: cancelButton.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.top: progressHeader.bottom
            text: ""
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.primaryColor
        }
    }

    function clearCover() {
        coverPlaceholder.text = "Search";
    }
}


