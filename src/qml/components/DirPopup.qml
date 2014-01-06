import QtQuick 2.0
import Sailfish.Silica 1.0
import "../pages/functions.js" as Functions

// This component displays a list of dir options on top of a page
Item {
    id: item
    property int menuTop: 100

    property int _selectedMenu: 0
    property Item _contextMenu

    function show()
    {
        if (!_contextMenu)
            _contextMenu = contextMenuComponent.createObject(rect);
        _selectedMenu = 0;
        _contextMenu.show(rect);
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
            color: "black"
            width: parent.width
            height: _contextMenu ? _contextMenu.height : 0
        }
    }

    Component {
        id: contextMenuComponent
        ContextMenu {

            // delayed action so that menu has already closed when page transition happens
            onClosed: {
                if (_selectedMenu == 1) {
                    Functions.goToHome(StandardPaths.documents);

                } else if (_selectedMenu == 2) {
                    var sdcard = Functions.sdcardPath();
                    if (engine.exists(sdcard)) {
                        Functions.goToFolder(sdcard);
                    } else {
                        // this assumes that the page has a notificationPanel
                        notificationPanel.showWithText("SD Card not found", sdcard);
                    }

                } else if (_selectedMenu == 3) {
                    var androidSdcard = Functions.androidSdcardPath();
                    if (engine.exists(androidSdcard)) {
                        Functions.goToFolder(androidSdcard);
                    } else {
                        // this assumes that the page has a notificationPanel
                        notificationPanel.showWithText("Android SD Card not found", androidSdcard);
                    }

                } else if (_selectedMenu == 4) {
                    Functions.goToRoot();
                }
                _selectedMenu = 0;
            }

            MenuItem {
                text: "Home"
                onClicked: _selectedMenu = 1
            }
            MenuItem {
                text: "SD Card"
                onClicked: _selectedMenu = 2
            }
            MenuItem {
                text: "Android SD Card"
                onClicked: _selectedMenu = 3
            }
            MenuItem {
                text: "Root"
                onClicked: _selectedMenu = 4
            }
        }
    }

}
