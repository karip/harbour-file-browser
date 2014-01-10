import QtQuick 2.0
import Sailfish.Silica 1.0

// This component displays a label and a value
Row {
    spacing: 10
    width: parent.width
    property string label: ""
    property string value: ""
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
        width: parent.width/2
        wrapMode: Text.Wrap
        font.pixelSize: pixelSize
    }
}
