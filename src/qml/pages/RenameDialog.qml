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

    DialogHeader {
        id: dialogHeader
        title: qsTr("Rename")
        acceptText: qsTr("Rename")
    }

    Column {
        anchors.top: dialogHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            text: qsTr("Give a new name for\n%1").arg(path)
            wrapMode: Text.Wrap
        }

        LagoonSpacer {
            height: 20
        }

        TextField {
            id: newName
            width: parent.width
            placeholderText: qsTr("Enter new name")
            focus: true

            // return key on virtual keyboard accepts the dialog
            Keys.onPressed: {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    dialog.accept();
            }
        }
    }
}


