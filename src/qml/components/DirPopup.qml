import QtQuick 2.0
import Sailfish.Silica 1.0
import "../pages/functions.js" as Functions

// This component displays a list of dir options on top of a page
Item {
    id: item
    property int menuTop: Theme.itemSizeMedium

    property string _selectedMenu: ""
    property Item _contextMenu

    function show()
    {
        if (!_contextMenu)
            _contextMenu = contextMenuComponent.createObject(rect);
        _selectedMenu = "";

        // update available disk space strings
        var rootSpace = engine.diskSpace("/");
        if (rootSpace.length > 0) {
            _contextMenu.rootSpaceText = qsTr("Root (%1)").arg(rootSpace[0]);
            _contextMenu.rootSpaceSubtext = rootSpace[1];
        } else {
            _contextMenu.rootSpaceText = qsTr("Root");
            _contextMenu.rootSpaceSubtext = "";
        }

        var sdCardPath = engine.sdcardPath();
        var sdCardSpace = engine.diskSpace(sdCardPath);
        if (sdCardSpace.length > 0) {
            _contextMenu.sdCardSpaceText = qsTr("SD Card (%1)").arg(sdCardSpace[0]);
            _contextMenu.sdCardSpaceSubtext = sdCardSpace[1];
        } else {
            _contextMenu.sdCardSpaceText = qsTr("SD Card");
            _contextMenu.sdCardSpaceSubtext = "";
        }
        _contextMenu.sdCardVisible = (sdCardPath !== "");

        _contextMenu.open(rect);
    }

    Column {
        anchors.fill: parent

        Item {
            id: spacer
            width: parent.width
            height: menuTop
        }
        // bg rectangle for context menu so it covers underlying items
        Rectangle {
            id: rect
            color: Theme.overlayBackgroundColor ? Theme.overlayBackgroundColor : "black"
            width: parent.width
            height: _contextMenu ? _contextMenu.height : 0
        }
    }

    Component {
        id: contextMenuComponent
        ContextMenu {

            property string sdCardSpaceText: ""
            property string sdCardSpaceSubtext: ""
            property bool sdCardVisible: false
            property string rootSpaceText: ""
            property string rootSpaceSubtext: ""

            // delayed action so that menu has already closed when page transition happens
            onClosed: {
                if (_selectedMenu === "home") {
                    Functions.goToHome();

                } else if (_selectedMenu === "android-storage") {
                    var androidSdcard = engine.androidSdcardPath();
                    if (engine.exists(androidSdcard)) {
                        Functions.goToFolder(androidSdcard);
                    } else {
                        // this assumes that the page has a notificationPanel
                        notificationPanel.showText(qsTr("Android Storage not found"), androidSdcard);
                    }

                } else if (_selectedMenu === "root") {
                    Functions.goToRoot();

                } else if (_selectedMenu === "sdcard") {
                    var sdcard = engine.sdcardPath();
                    if (engine.exists(sdcard)) {
                        Functions.goToFolder(sdcard);
                    } else {
                        // this assumes that the page has a notificationPanel
                        notificationPanel.showText(qsTr("SD Card not found"), sdcard);
                    }
                }
                _selectedMenu = "";
            }

            MenuItem {
                text: qsTr("Home")
                onClicked: _selectedMenu = "home"
            }
            MenuItem {
                text: qsTr("Android Storage")
                onClicked: _selectedMenu = "android-storage"
            }
            DoubleMenuItem {
                text: rootSpaceText
                subtext: rootSpaceSubtext
                onClicked: _selectedMenu = "root"
            }
            DoubleMenuItem {
                text: sdCardSpaceText
                subtext: sdCardSpaceSubtext
                onClicked: _selectedMenu = "sdcard"
                visible: sdCardVisible
            }
        }
    }

}
