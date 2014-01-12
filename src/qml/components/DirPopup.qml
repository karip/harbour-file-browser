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

        // update spaces
        var rootSpace = engine.diskSpace("/");
        if (rootSpace.length > 0) {
            _contextMenu.rootSpaceText = qsTr("Root (%1)").arg(rootSpace[0]);
            _contextMenu.rootSpaceSubtext = rootSpace[1];
        } else {
            _contextMenu.rootSpaceText = qsTr("Root");
            _contextMenu.rootSpaceSubtext = "";
        }

        var sdCardSpace = engine.diskSpace(Functions.sdcardPath());
        if (sdCardSpace.length > 0) {
            _contextMenu.sdCardSpaceText = qsTr("SD Card (%1)").arg(sdCardSpace[0]);
            _contextMenu.sdCardSpaceSubtext = sdCardSpace[1];
        } else {
            _contextMenu.sdCardSpaceText = qsTr("SD Card");
            _contextMenu.sdCardSpaceSubtext = "";
        }

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

            property string sdCardSpaceText: ""
            property string sdCardSpaceSubtext: ""
            property string rootSpaceText: ""
            property string rootSpaceSubtext: ""

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
                        notificationPanel.showWithText(qsTr("SD Card not found"), sdcard);
                    }

                } else if (_selectedMenu == 3) {
                    var androidSdcard = Functions.androidSdcardPath();
                    if (engine.exists(androidSdcard)) {
                        Functions.goToFolder(androidSdcard);
                    } else {
                        // this assumes that the page has a notificationPanel
                        notificationPanel.showWithText(qsTr("Android Storage not found"), androidSdcard);
                    }

                } else if (_selectedMenu == 4) {
                    Functions.goToRoot();
                }
                _selectedMenu = 0;
            }

            MenuItem {
                text: qsTr("Home")
                onClicked: _selectedMenu = 1
            }
            DoubleMenuItem {
                text: sdCardSpaceText
                subtext: sdCardSpaceSubtext
                onClicked: _selectedMenu = 2
            }
            MenuItem {
                text: qsTr("Android Storage")
                onClicked: _selectedMenu = 3
            }
            DoubleMenuItem {
                text: rootSpaceText
                subtext: rootSpaceSubtext
                onClicked: _selectedMenu = 4
            }
        }
    }

}
