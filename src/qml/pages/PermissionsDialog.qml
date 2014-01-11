import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileInfo 1.0
import "../components"

Dialog {
    property string path: ""

    // return value
    property string errorMessage: ""

    id: dialog
    allowedOrientations: Orientation.All

    property int _executeWidth: executeLabel.width

    onAccepted: errorMessage = engine.chmod(path,
                        ownerRead.checked, ownerWrite.checked, ownerExecute.checked,
                        groupRead.checked, groupWrite.checked, groupExecute.checked,
                        othersRead.checked, othersWrite.checked, othersExecute.checked);

    FileInfo {
        id: fileInfo
        file: path
    }

    // copy values to fields when page shows up
    Component.onCompleted: {
        ownerName.text = fileInfo.owner
        groupName.text = fileInfo.group
        var permissions = fileInfo.permissions
        if (permissions.charAt(0) !== '-') ownerRead.checked = true;
        if (permissions.charAt(1) !== '-') ownerWrite.checked = true;
        if (permissions.charAt(2) !== '-') ownerExecute.checked = true;
        if (permissions.charAt(3) !== '-') groupRead.checked = true;
        if (permissions.charAt(4) !== '-') groupWrite.checked = true;
        if (permissions.charAt(5) !== '-') groupExecute.checked = true;
        if (permissions.charAt(6) !== '-') othersRead.checked = true;
        if (permissions.charAt(7) !== '-') othersWrite.checked = true;
        if (permissions.charAt(8) !== '-') othersExecute.checked = true;
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
                title: qsTr("Change Permissions")
                acceptText: qsTr("Change")
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                text: qsTr("Change permissions for\n%1").arg(path)
                wrapMode: Text.Wrap
            }

            LagoonSpacer {
                height: 40
            }

            // read, write, execute small labels
            Row {
                width: parent.width
                Label {
                    width: parent.width/2
                    text: " "
                }

                Label {
                    id: readLabel
                    width: executeLabel.width
                    text: qsTr("Read")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    id: writeLabel
                    width: executeLabel.width
                    text: qsTr("Write")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    id: executeLabel
                    text: qsTr("Execute")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // owner
            Row {
                width: parent.width
                Column {
                    width: parent.width/2
                    Label {
                        id: ownerName
                        width: parent.width-20
                        text: ""
                        horizontalAlignment: Text.AlignRight
                    }
                    Label {
                        width: parent.width-20
                        text: qsTr("Owner")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        horizontalAlignment: Text.AlignRight
                    }
                }
                TextSwitch {
                    id: ownerRead
                    width: _executeWidth
                }
                TextSwitch {
                    id: ownerWrite
                    width: _executeWidth
                }
                TextSwitch {
                    id: ownerExecute
                    width: _executeWidth
                }
            }

            // group
            Row {
                width: parent.width
                Column {
                    width: parent.width/2
                    Label {
                        id: groupName
                        width: parent.width-20
                        text: ""
                        horizontalAlignment: Text.AlignRight
                    }
                    Label {
                        width: parent.width-20
                        text: qsTr("Group")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        horizontalAlignment: Text.AlignRight
                    }
                }
                TextSwitch {
                    id: groupRead
                    width: _executeWidth
                }
                TextSwitch {
                    id: groupWrite
                    width: _executeWidth
                }
                TextSwitch {
                    id: groupExecute
                    width: _executeWidth
                }
            }

            // others
            Row {
                width: parent.width
                Item {
                    width: parent.width/2
                    height: othersRead.height
                    Label {
                        width: parent.width-20
                        height: parent.height
                        text: qsTr("Others")
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                TextSwitch {
                    id: othersRead
                    width: _executeWidth
                }
                TextSwitch {
                    id: othersWrite
                    width: _executeWidth
                }
                TextSwitch {
                    id: othersExecute
                    width: _executeWidth
                }
            }
        }
    }
}


