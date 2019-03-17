import QtQuick 2.0
import Sailfish.Silica 1.0

// This component blocks all components under it and displays a dark background
Rectangle {
    id: interactionBlocker

    // clicked signal is emitted when the component is clicked
    signal clicked

    visible: false
    color: Theme.overlayBackgroundColor ? Theme.overlayBackgroundColor : "black"
    opacity: 0.4

    MouseArea {
        anchors.fill: parent
        enabled: true
        onClicked: interactionBlocker.clicked()
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
