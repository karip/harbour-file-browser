import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Dialog {
    property variant files: [] // this must be set to a string list, e.g. [ "file1", "file2" ]

    id: dialog
    allowedOrientations: Orientation.All

    SilicaListView {
        id: overwriteFileList
        anchors.fill: parent
        anchors.bottomMargin: 0
        clip: true

        model: files

        VerticalScrollDecorator { flickable: overwriteFileList }

        header: Item {
            width: parent.width
            height: dialogHeader.height + dialogLabel.height + 2*Theme.paddingLarge

            DialogHeader {
                id: dialogHeader
                title: qsTr("Replace?")
                acceptText: qsTr("Replace")
            }
            Label {
                id: dialogLabel
                text: qsTr("These files or folders already exist:")
                wrapMode: Text.Wrap
                anchors.top: dialogHeader.bottom
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                color: Theme.highlightColor
            }
        }

        delegate: Item {
            id: fileItem
            width: ListView.view.width
            height: listLabel.height

            Label {
                id: listLabel
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                text: modelData
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.primaryColor
            }
        }
    }
}
