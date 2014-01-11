import QtQuick 2.0
import Sailfish.Silica 1.0

// This component creates a switch with a letter
MouseArea {
    property bool checked: false
    property string letter: ""

    height: parent.height

    Label {
        id: label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: checked ? letter : "-"
        color: Theme.highlightColor
    }

    onClicked: checked = !checked
}
