import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Dialog {
    property string path: ""

    // return value
    property string errorMessage: ""

    id: dialog
    allowedOrientations: Orientation.All
    canAccept: folderName.text !== ""

    onAccepted: errorMessage = engine.mkdir(path, folderName.text);

    DialogHeader {
        id: dialogHeader
        title: qsTr("Create Folder")
        acceptText: qsTr("Create")
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
            text: qsTr("Create a new folder under\n%1").arg(path)
            wrapMode: Text.Wrap
        }

        LagoonSpacer {
            height: 20
        }

        TextField {
            id: folderName
            width: parent.width
            placeholderText: qsTr("Enter folder name")
            focus: true

            // return key on virtual keyboard accepts the dialog
            Keys.onPressed: {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    dialog.accept();
            }
        }
    }
}


