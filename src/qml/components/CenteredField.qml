import QtQuick 2.0
import Sailfish.Silica 1.0

// This component displays a label and a value as a row
Row {
    spacing: 10
    width: parent.width

    // label text
    property string label: ""

    // value text
    property string value: ""

    // font size
    property int pixelSize: Theme.fontSizeExtraSmall

    Label {
        text: label
        color: Theme.secondaryColor
        width: parent.width/2
        horizontalAlignment: Text.AlignRight
        wrapMode: Text.Wrap
        font.pixelSize: pixelSize
    }
    Label {
        text: value
        color: Theme.highlightColor
        width: parent.width/2
        wrapMode: Text.Wrap
        font.pixelSize: pixelSize
    }
}
