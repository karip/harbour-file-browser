import QtQuick 2.0
import Sailfish.Silica 1.0
import "functions.js" as Functions
import "../components"

Dialog {
    property string path: ""

    // return values
    property string errorMessage: ""
    property string newPath: ""

    id: dialog
    allowedOrientations: Orientation.All
    canAccept: newName.text !== ""

    onAccepted: {
        var res = engine.rename(path, newName.text);
        newPath = res[0]
        errorMessage = res[1]
    }

    Component.onCompleted: {
        newName.text = Functions.lastPartOfPath(path)
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            DialogHeader {
                id: dialogHeader
                title: qsTr("Rename")
                acceptText: qsTr("Rename")
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                text: qsTr("Give a new name for\n%1").arg(path)
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
            }

            Spacer {
                height: 20
            }

            TextField {
                id: newName
                width: parent.width
                placeholderText: qsTr("New name")
                label: qsTr("New name")
                focus: true
                EnterKey.enabled: newName.text !== ""
                EnterKey.onClicked: dialog.accept()
            }
        }
    }
}


