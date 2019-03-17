import QtQuick 2.0
import Sailfish.Silica 1.0

// This component displays a notification panel at top of page
Item {
    anchors.fill: parent

    // reference to page to prevent back navigation (required)
    property Item page

    // open status of the panel
    property alias open: dockedPanel.open

    // shows the panel
    function showText(header, txt) {
        headerLabel.text = header;
        textLabel.text = txt;
        dockedPanel.show();
    }

    // shows the panel, maximum 5 secs
    function showTextWithTimer(header, txt) {
        headerLabel.text = header;
        textLabel.text = txt;
        dockedPanel.show();
        timer.start();
    }

    // hides the panel
    function hide() {
        timer.stop()
        dockedPanel.hide();
    }


    //// internal

    InteractionBlocker {
        anchors.fill: parent
        visible: dockedPanel.open
        onClicked: {
            dockedPanel.hide();
            timer.stop();
        }
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
        MouseArea {
            anchors.fill: parent
            enabled: true
            onClicked: {
                dockedPanel.hide();
                timer.stop();
            }
        }
        Label {
            id: headerLabel
            visible: dockedPanel.open
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            y: 2*Theme.paddingLarge
            horizontalAlignment: Text.AlignHCenter
            text: ""
            wrapMode: Text.Wrap
            color: Theme.primaryColor
        }
        Label {
            id: textLabel
            visible: dockedPanel.open
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            anchors.top: headerLabel.bottom
            horizontalAlignment: Text.AlignHCenter
            text: ""
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.primaryColor
        }
    }

    // timer to auto-hide panel
    Timer {
        id: timer
        interval: 5000
        onTriggered: {
            dockedPanel.hide();
            stop();
        }
    }
}
