import QtQuick 2.0
import Sailfish.Silica 1.0

// This component displays a progress panel at top of page and blocks all interactions under it
Item {
    id: progressPanel
    anchors.fill: parent

    // reference to page to prevent back navigation (required)
    property Item page

    // large text displayed on panel
    property string headerText: ""

    // small text displayed on panel
    property string text: ""

    // open status of the panel
    property alias open: dockedPanel.open

    // shows the panel
    function showText(txt) {
        headerText = txt;
        text = "";
        dockedPanel.show();
    }

    // hides the panel
    function hide() {
        dockedPanel.hide();
    }

    // cancelled signal is emitted when user presses the cancel button
    signal cancelled


    //// internal

    InteractionBlocker {
        anchors.fill: parent
        visible: dockedPanel.open
    }

    DockedPanel {
        id: dockedPanel

        width: parent.width
        height: Theme.itemSizeExtraLarge + Theme.paddingLarge

        dock: Dock.Top
        open: false
        onOpenChanged: page.backNavigation = !open; // disable back navigation

        Rectangle {
            anchors.fill: parent
            color: Theme.overlayBackgroundColor ? Theme.overlayBackgroundColor : "black"
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
            width: Theme.itemSizeMedium
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: cancelMouseArea.pressed ? Theme.secondaryHighlightColor : "transparent"

            MouseArea {
                id: cancelMouseArea
                anchors.fill: parent
                onClicked: cancelled();
                enabled: true
                Text {
                    anchors.centerIn: parent
                    color: Theme.primaryColor
                    text: "\u00d7" // times symbol (cross)
                }
            }
        }
        Label {
            id: progressHeader
            visible: dockedPanel.open

            y: 2*Theme.paddingLarge
            anchors.left: parent.left
            anchors.right: cancelButton.left
            anchors.leftMargin: progressBusy.width + Theme.paddingLarge*4
            anchors.rightMargin: Theme.paddingLarge
            text: progressPanel.headerText
            color: Theme.primaryColor
        }
        Label {
            id: progressText
            visible: dockedPanel.open
            anchors.left: progressHeader.left
            anchors.right: cancelButton.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.top: progressHeader.bottom
            text: progressPanel.text
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.primaryColor
        }
    }
}
