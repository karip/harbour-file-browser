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
                acceptText: qsTr("Create")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: qsTr("Create a new folder under") + "\n" + path + (path != "/" ? "/" : "");
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Spacer {
                height: Theme.paddingLarge
            }

            TextField {
                id: folderName
                width: parent.width
                placeholderText: qsTr("Folder name")
                label: qsTr("Folder name")
                focus: true

                // return key on virtual keyboard accepts the dialog
                EnterKey.enabled: folderName.text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: dialog.accept()
            }
        }
    }
}


