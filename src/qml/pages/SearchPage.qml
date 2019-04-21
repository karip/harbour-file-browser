import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.SearchEngine 1.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string dir: "/" // holds the top directory where all searches will be made
    property string currentDirectory: "" // holds the directory which is being searched by SearchEngine

    // used to disable SelectionPanel while remorse timer is active
    property bool remorsePopupActive: false // set to true when remorsePopup is active (at top of page)
    property bool remorseItemActive: false // set to true when remorseItem is active (item level)

    property int _selectedFileCount: 0

    // this and its bg worker thread will be destroyed when page in popped from stack
    SearchEngine {
        id: searchEngine
        dir: page.dir

        // react on signals from SearchEngine
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
        onCanceled: remorsePopupActive = false
        onTriggered: remorsePopupActive = false
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

            // updates the model by clearing all data and starting searchEngine search() method async
            // using the given txt as the search string
            function update(txt) {
                if (txt === "")
                    searchEngine.cancel();

                clear();
                clearSelectedFiles();
                if (txt !== "") {
                    searchEngine.search(txt);
                    coverText = qsTr("Searching")+"\n"+txt;
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
            height: Theme.itemSizeLarge

            SearchField {
                id: searchField
                anchors.left: parent.left
                anchors.right: cancelSearchButton.left
                y: Theme.paddingSmall
                placeholderText: qsTr("Search %1").arg(Functions.formatPathForSearch(page.dir))
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                // get focus when page is shown for the first time
                Component.onCompleted: forceActiveFocus()


                // return key on virtual keyboard starts or restarts search
                EnterKey.enabled: true
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    notificationPanel.hide();
                    listModel.update(searchField.text);
                    foundText.visible = true;
                    searchField.focus = false;
                }
            }
            // our own "IconButton" to make the mouse area large and easier to tap
            IconButton {
                id: cancelSearchButton
                anchors.right: parent.right
                anchors.top: searchField.top
                width: Theme.iconSizeMedium+Theme.paddingLarge
                height: searchField.height
                onClicked: {
                        if (!searchEngine.running) {
                            listModel.update(searchField.text);
                            foundText.visible = true;
                        } else {
                            searchEngine.cancel()
                        }
                    }
                icon.source: searchEngine.running ? "image://theme/icon-m-clear" :
                                                       "image://theme/icon-m-right"
            }
            BusyIndicator {
                id: searchBusy
                anchors.centerIn: cancelSearchButton
                running: searchEngine.running
                size: BusyIndicatorSize.Small
            }

            Label {
                id: foundText
                visible: false
                anchors.left: parent.left
                anchors.leftMargin: searchField.textLeftMargin
                anchors.top: searchField.bottom
                anchors.topMargin: -Theme.paddingLarge
                text: qsTr("%1 hits").arg(listModel.count)
                font.pixelSize: Theme.fontSizeTiny
                color: searchField.placeholderColor
            }
            Label {
                anchors.left: parent.left
                anchors.leftMargin: 3*Theme.itemSizeSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: searchField.bottom
                anchors.topMargin: -Theme.paddingSmall
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
            // HighlightImage replaced with a Loader so that HighlightImage or Image
            // can be loaded depending on Sailfish version (lightPrimaryColor is defined on SF3)
            Loader {
                id: listIcon
                anchors.verticalCenter: listLabel.verticalCenter
                x: Theme.paddingLarge
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
                Component.onCompleted: {
                    var qml = Theme.lightPrimaryColor ? "../components/MyHighlightImage3.qml"
                                                      : "../components/MyHighlightImage2.qml";
                    setSource(qml, {
                        imgsrc: "../images/small-"+fileIcon+".png",
                        imgw: Theme.iconSizeSmall,
                        imgh: Theme.iconSizeSmall
                    })
                }
            }
            // circle shown when item is selected
            Rectangle {
                visible: isSelected
                anchors.verticalCenter: listLabel.verticalCenter
                x: Theme.paddingLarge - 2*Theme.pixelRatio
                width: Theme.iconSizeSmall + 4*Theme.pixelRatio
                height: Theme.iconSizeSmall + 4*Theme.pixelRatio
                color: "transparent"
                border.color: Theme.highlightColor
                border.width: 2.25 * Theme.pixelRatio
                radius: width * 0.5
            }
            Label {
                id: listLabel
                y: Theme.paddingSmall
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                text: filename
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: fileItem.highlighted || isSelected ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: listAbsoluteDir
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: listLabel.bottom
                text: absoluteDir
                color: fileItem.highlighted || isSelected ? Theme.secondaryHighlightColor : Theme.secondaryColor
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
                width: Theme.itemSizeSmall
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

            RemorseItem {
                id: remorseItem
                onTriggered: remorseItemActive = false
                onCanceled: remorseItemActive = false
            }

            // delete file after remorse time
            function deleteFile(deleteFilename) {
                remorseItemActive = true;
                remorseItem.execute(fileItem, qsTr("Deleting"), function() {
                    progressPanel.showText(qsTr("Deleting"));
                    engine.deleteFiles([ deleteFilename ]);
                });
            }

            // enable animated list item removals
            ListView.onRemove: animateRemoval(fileItem)

            // context menu is activated with long press, visible if search is not running
            Component {
                 id: contextMenu
                 ContextMenu {
                     // cancel delete if context menu is opened
                     onActiveChanged: { remorsePopup.cancel(); clearSelectedFiles(); }
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
            if (item.isSelected)
                list.push(item.fullname);
        }
        return list;
    }
    function clearSelectedFiles() {
        for (var i = 0; i < listModel.count; ++i) {
            // get returns a reference to the item
            // changing the item properties changes its properties in the list
            var item = listModel.get(i);
            item.isSelected = false;
        }
        _selectedFileCount = 0;
        selectionPanel.open = false;
        selectionPanel.overrideText = "";
    }
    function selectAllFiles() {
        for (var i = 0; i < listModel.count; ++i) {
            // get returns a reference to the item
            // changing the item properties changes its properties in the list
            var item = listModel.get(i);
            item.isSelected = true;
        }
        _selectedFileCount = listModel.count;
        selectionPanel.open = true;
        selectionPanel.overrideText = "";
    }

    SelectionPanel {
        id: selectionPanel
        selectedCount: _selectedFileCount
        enabled: !page.remorsePopupActive && !page.remorseItemActive
        orientation: page.orientation
        displayClose: _selectedFileCount === listModel.count

        onSelectAllTriggered: selectAllFiles();
        onCloseTriggered: clearSelectedFiles();
        onDeleteTriggered: {
            var files = selectedFiles();
            remorsePopupActive = true;
            remorsePopup.execute(qsTr("Deleting"), function() {
                clearSelectedFiles();
                progressPanel.showText(qsTr("Deleting"));
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
        coverText = qsTr("Search");
    }
}


