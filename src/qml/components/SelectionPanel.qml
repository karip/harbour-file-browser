import QtQuick 2.0
import Sailfish.Silica 1.0

// bottom dock panel to display cut & copy controls
// this requires that its parent implements selectedFiles() function
DockedPanel {
    id: dockPanel
    width: parent.width
    open: false
    height: (dockColumn.visible ? dockColumn.height + Theme.paddingLarge : dockRow.height)
    dock: Dock.Bottom
    visible: shouldBeVisible & !Qt.inputMethod.visible

    signal selectAllTriggered
    signal closeTriggered
    signal deleteTriggered
    signal propertyTriggered

    // oriantation of the panel
    property int orientation: Orientation.Portrait

    // number of selected items
    property int selectedCount: 0

    property bool displayClose: false

    // enable or disable the buttons
    property bool enabled: true

    // override text is shown if set, it gets cleared whenever selected file count changes
    property string overrideText: ""

    // property to indicate that the panel is really visible (open or showing closing animation)
    property bool shouldBeVisible: false
    onOpenChanged: { if (open) shouldBeVisible = true; }
    onMovingChanged: { if (!open && !moving) shouldBeVisible = false; }

    Column {
        id: dockColumn
        visible: dockPanel.orientation === Orientation.Portrait ||
                 dockPanel.orientation === Orientation.PortraitInverted
        anchors.horizontalCenter: parent.horizontalCenter
        Spacer { height: Theme.paddingLarge }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: dockPanel.overrideText === "" ? qsTr("%1 selected").arg(dockPanel.selectedCount)
                                                : dockPanel.overrideText
            color: dockPanel.enabled ? Theme.highlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            IconButton {
                enabled: dockPanel.enabled
                icon.source: displayClose ? "image://theme/icon-m-close"
                                          : "../images/toolbar-select-all.png"
                onClicked: { displayClose ? closeTriggered() : selectAllTriggered(); }
            }
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
                icon.source: "image://theme/icon-m-delete"
                onClicked: { deleteTriggered(); }
            }
            IconButton {
                enabled: dockPanel.enabled
                icon.source: "../images/toolbar-properties.png"
                onClicked: { propertyTriggered(); }
            }
        }
    }

    Row {
        id: dockRow
        visible: dockPanel.orientation === Orientation.Landscape ||
                 dockPanel.orientation === Orientation.LandscapeInverted
        anchors.horizontalCenter: parent.horizontalCenter
        height: cutButton.height + Theme.paddingLarge*2
        spacing: 20
        Spacer { width: Theme.paddingLarge; height: parent.height }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: dockPanel.overrideText === "" ? qsTr("%1 selected").arg(dockPanel.selectedCount)
                                                : dockPanel.overrideText
            color: dockPanel.enabled ? Theme.highlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }
        Spacer { width: 40; height: parent.height }
        IconButton {
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.source: displayClose ? "image://theme/icon-m-close"
                                      : "../images/toolbar-select-all.png"
            onClicked: { displayClose ? closeTriggered() : selectAllTriggered(); }
        }
        IconButton {
            id: cutButton
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "../images/toolbar-cut.png"
            onClicked: {
                var files = dockPanel.parent.selectedFiles();
                engine.cutFiles(files);
                dockPanel.overrideText = qsTr("%1 cut").arg(engine.clipboardCount);
            }
        }
        IconButton {
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "../images/toolbar-copy.png"
            onClicked: {
                var files = dockPanel.parent.selectedFiles();
                engine.copyFiles(files);
                dockPanel.overrideText = qsTr("%1 copied").arg(engine.clipboardCount);
            }
        }
        IconButton {
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "image://theme/icon-m-delete"
            onClicked: { deleteTriggered(); }
        }
        IconButton {
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "../images/toolbar-properties.png"
            onClicked: { propertyTriggered(); }
        }
    }
}
