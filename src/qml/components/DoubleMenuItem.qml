import QtQuick 2.0
import Sailfish.Silica 1.0

// This component is a menu item with two lines
MenuItem {
    property string subtext: ""

    Label {
        visible: subtext !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(Theme.paddingSmall/3)
        text: subtext
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeTiny
    }
}
