import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.SearchEngine 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    showNavigationIndicator: false // hide back indicator because it would be on top of search field
    property string dir: "/"
    property string currentDirectory: ""
    property bool remorsePopupOpen: false // set to true when remorsePopup is active

    property int _selectedFileCount: 0

    // this and its bg worker thread will be destroyed when page in popped from stack
    SearchEngine {
        id: searchEngine
        dir: page.dir

        onProgressChanged: page.currentDirectory = directory
        onMatchFound: listModel.append({ fullname: fullname, filename: filename,
                                         absoluteDir: absoluteDir,
                                         fileIcon: fileIcon, fileKind: fileKind,
                                         isSelected: false
                                       });
        onWorkerDone: { clearCover(); }
        onWorkerErrorOccurred: { clearCover(); notificationPanel.showText(message, filename); }
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

        // prevent newly added list delegates from stealing focus away from the search field
        currentIndex: -1

        model: ListModel {
            id: listModel

            function update(txt) {
                if (txt === "")
                    searchEngine.cancel();

                clear();
                clearSelectedFiles();
                if (txt !== "") {
                    searchEngine.search(txt);
                    coverPlaceholder.text = qsTr("Searching")+"\n"+txt;
                }
            }

            Component.onCompleted: update("")
        }

        VerticalScrollDecorator { flickable: fileList }

        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
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
                placeholderText: qsTr("Search %1").arg(Functions.formatPathForSearch(page.dir))
                inputMethodHints: Qt.ImhNoAutoUppercase

                // get focus when page is shown for the first time
                Component.onCompleted: forceActiveFocus()

                // return key on virtual keyboard starts or restarts search
                EnterKey.enabled: true
                EnterKey.onClicked: {
                    notificationPanel.hide();
                    listModel.update(searchField.text);
                    foundText.visible = true;
                    searchField.focus = false;
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
                text: qsTr("%1 hits").arg(listModel.count)
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
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: fileItem.highlighted || isSelected ? Theme.highlightColor : Theme.primaryColor
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
            MouseArea {
                width: 90
                height: parent.height
                onClicked: {
                    if (!model.isSelected) {
                        _selectedFileCount++;
                        var item = { fullname: fullname, filename: filename,
                            absoluteDir: absoluteDir,
                            fileIcon: fileIcon, fileKind: fileKind,
                            isSelected: true
                        };
                        fileList.model.set(index, item);
                    } else {
                        _selectedFileCount--;
                        var item2 = { fullname: fullname, filename: filename,
                            absoluteDir: absoluteDir,
                            fileIcon: fileIcon, fileKind: fileKind,
                            isSelected: false
                        };
                        fileList.model.set(index, item2);
                    }
                    selectionPanel.open = (_selectedFileCount > 0);
                    selectionPanel.overrideText = "";
                }
            }

            // delete file after remorse time
            ListView.onRemove: animateRemoval(fileItem)
            function deleteFile(deleteFilename) {
                remorseAction(qsTr("Deleting"), function() {
                    progressPanel.showText(qsTr("Deleting"));
                    engine.deleteFiles([ deleteFilename ]);
                }, 5000)
            }

            // context menu is activated with long press, visible if search is not running
            Component {
                 id: contextMenu
                 ContextMenu {
                     // cancel delete if context menu is opened
                     onActiveChanged: remorsePopup.cancel()
                     MenuItem {
                         text: qsTr("Go to containing folder")
                         onClicked: Functions.goToFolder(model.absoluteDir)
                     }
                     MenuItem {
                         text: qsTr("Cut")
                         onClicked: engine.cutFiles([ model.fullname ]);
                     }
                     MenuItem {
                         text: qsTr("Copy")
                         onClicked: engine.copyFiles([ model.fullname ]);
                     }
                     MenuItem {
                         text: qsTr("Delete")
                         onClicked: deleteFile(model.fullname);
                     }
                 }
             }
        }

    }

    // a bit hackery: these are called from selection panel
    function selectedFiles() {
        var list = [];
        for (var i = 0; i < listModel.count; ++i) {
            var item = listModel.get(i);
            console.log("selected item:"+item);
            if (item.isSelected)
                list.push(item.fullname);
        }
        return list;
    }
    function clearSelectedFiles() {
        for (var i = 0; i < listModel.count; ++i) {
            var item = listModel.get(i);
            console.log("clear item:"+item);
            item.isSelected = false;
            listModel.set(i, item);
        }
        _selectedFileCount = 0;
    }

    SelectionPanel {
        id: selectionPanel
        selectedCount: _selectedFileCount
        enabled: !page.remorsePopupOpen

        onDeleteTriggered: {
            var files = selectedFiles();
            remorsePopupOpen = true;
            remorsePopup.execute("Deleting", function() {
                clearSelectedFiles();
                selectionPanel.open = false;
                selectionPanel.overrideText = "";
                engine.deleteFiles(files);
            });
        }
        onPropertyTriggered: {
            var files = selectedFiles();
            pageStack.push(Qt.resolvedUrl("FilePage.qml"), { file: files[0] });
        }
    }

    // update cover
    onStatusChanged: {
        // clear file selections when the directory is changed
        clearSelectedFiles();
        selectionPanel.open = false;
        selectionPanel.overrideText = "";

        if (status === PageStatus.Activating)
            clearCover();
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
                notificationPanel.showText(message, filename);
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

    NotificationPanel {
        id: notificationPanel
        page: page
    }

    ProgressPanel {
        id: progressPanel
        page: page
        onCancelled: engine.cancel()
    }

    function clearCover() {
        coverPlaceholder.text = qsTr("Search");
    }
}


