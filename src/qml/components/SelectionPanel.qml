import QtQuick 2.0
import Sailfish.Silica 1.0

// bottom dock panel to display cut & copy controls
// this assumes that its parent implements selectedFiles() function
DockedPanel {
    id: dockPanel
    width: parent.width
    open: false
    height: dockColumn.height + Theme.paddingLarge
    dock: Dock.Bottom

    signal deleteTriggered
    signal propertyTriggered

    // number of selected items
    property int selectedCount: 0

    // enable or disable the buttons
    property bool enabled: true

    // override text is shown if set, it gets cleared whenever selected file count changes
    property string overrideText: ""

    Column {
        id: dockColumn
        anchors.horizontalCenter: parent.horizontalCenter
        Spacer { height: Theme.paddingLarge }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: dockPanel.overrideText === "" ? qsTr("%1 selected").arg(dockPanel.selectedCount)
                                                : dockPanel.overrideText
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeTiny
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            IconButton {
                enabled: dockPanel.enabled
                icon.source: "../images/toolbar-cut.png"
                onClicked: {
                    var files = dockPanel.parent.selectedFiles();
                    engine.cutFiles(files);
                    dockPanel.overrideText = qsTr("%1 cut").arg(engine.clipboardCount);
                }
            }
            IconButton {
                enabled: dockPanel.enabled
                icon.source: "../images/toolbar-copy.png"
                onClicked: {
                    var files = dockPanel.parent.selectedFiles();
                    engine.copyFiles(files);
                    dockPanel.overrideText = qsTr("%1 copied").arg(engine.clipboardCount);
                }
            }
            IconButton {
                enabled: dockPanel.enabled
                icon.source: "image://theme/icon-l-delete"
                onClicked: { deleteTriggered(); }
            }
            IconButton {
                enabled: dockPanel.enabled
                icon.source: "../images/toolbar-properties.png"
                onClicked: { propertyTriggered(); }
            }
        }
    }
}
