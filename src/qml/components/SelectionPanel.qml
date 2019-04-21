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
            spacing: Theme.paddingLarge
            IconButton {
                id: iconbutton1
                enabled: dockPanel.enabled
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.source: displayClose ? "image://theme/icon-m-close"
                                          : "../images/toolbar-select-all.png"
                onClicked: { displayClose ? closeTriggered() : selectAllTriggered(); }
            }
            IconButton {
                id: iconbutton2
                enabled: dockPanel.enabled
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.source: "../images/toolbar-cut.png"
                onClicked: {
                    var files = dockPanel.parent.selectedFiles();
                    engine.cutFiles(files);
                    dockPanel.overrideText = qsTr("%1 cut").arg(engine.clipboardCount);
                }
            }
            IconButton {
                id: iconbutton3
                enabled: dockPanel.enabled
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.source: "../images/toolbar-copy.png"
                onClicked: {
                    var files = dockPanel.parent.selectedFiles();
                    engine.copyFiles(files);
                    dockPanel.overrideText = qsTr("%1 copied").arg(engine.clipboardCount);
                }
            }
            IconButton {
                id: iconbutton4
                enabled: dockPanel.enabled
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.source: "image://theme/icon-m-delete"
                onClicked: { deleteTriggered(); }
            }
            IconButton {
                id: iconbutton5
                enabled: dockPanel.enabled
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                icon.source: "../images/toolbar-properties.png"
                onClicked: { propertyTriggered(); }
            }
            // set icon color for IconButtons only on Sailfish 3 (when overlayBackgroundColor is defined)
            // these won't be set on Sailfish 2 which doesn't have Theme.lightPrimaryColor
            Binding {
                target: iconbutton1
                property: "icon.color"
                value: Theme.primaryColor
                when: Theme.lightPrimaryColor !== undefined
            }
            Binding {
                target: iconbutton2
                property: "icon.color"
                value: Theme.primaryColor
                when: Theme.lightPrimaryColor !== undefined
            }
            Binding {
                target: iconbutton3
                property: "icon.color"
                value: Theme.primaryColor
                when: Theme.lightPrimaryColor !== undefined
            }
            Binding {
                target: iconbutton4
                property: "icon.color"
                value: Theme.primaryColor
                when: Theme.lightPrimaryColor !== undefined
            }
            Binding {
                target: iconbutton5
                property: "icon.color"
                value: Theme.primaryColor
                when: Theme.lightPrimaryColor !== undefined
            }
        }
    }

    Row {
        id: dockRow
        visible: dockPanel.orientation === Orientation.Landscape ||
                 dockPanel.orientation === Orientation.LandscapeInverted
        anchors.horizontalCenter: parent.horizontalCenter
        height: cutButton.height + Theme.paddingLarge*2
        spacing: Theme.paddingLarge
        Spacer { width: Theme.paddingLarge; height: parent.height }
        Label {
            width: 2*Theme.itemSizeLarge
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            text: dockPanel.overrideText === "" ? qsTr("%1 selected").arg(dockPanel.selectedCount)
                                                : dockPanel.overrideText
            color: dockPanel.enabled ? Theme.highlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }
        Spacer { width: Theme.paddingLarge; height: parent.height }
        IconButton {
            id: viconbutton1
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.width: Theme.iconSizeMedium
            icon.height: Theme.iconSizeMedium
            icon.source: displayClose ? "image://theme/icon-m-close"
                                      : "../images/toolbar-select-all.png"
            onClicked: { displayClose ? closeTriggered() : selectAllTriggered(); }
        }
        IconButton {
            id: cutButton
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.width: Theme.iconSizeMedium
            icon.height: Theme.iconSizeMedium
            icon.source: "../images/toolbar-cut.png"
            onClicked: {
                var files = dockPanel.parent.selectedFiles();
                engine.cutFiles(files);
                dockPanel.overrideText = qsTr("%1 cut").arg(engine.clipboardCount);
            }
        }
        IconButton {
            id: viconbutton3
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.width: Theme.iconSizeMedium
            icon.height: Theme.iconSizeMedium
            icon.source: "../images/toolbar-copy.png"
            onClicked: {
                var files = dockPanel.parent.selectedFiles();
                engine.copyFiles(files);
                dockPanel.overrideText = qsTr("%1 copied").arg(engine.clipboardCount);
            }
        }
        IconButton {
            id: viconbutton4
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.width: Theme.iconSizeMedium
            icon.height: Theme.iconSizeMedium
            icon.source: "image://theme/icon-m-delete"
            onClicked: { deleteTriggered(); }
        }
        IconButton {
            id: viconbutton5
            enabled: dockPanel.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon.width: Theme.iconSizeMedium
            icon.height: Theme.iconSizeMedium
            icon.source: "../images/toolbar-properties.png"
            onClicked: { propertyTriggered(); }
        }
        // set icon color for IconButtons only on Sailfish 3 (when overlayBackgroundColor is defined)
        // these won't be set on Sailfish 2 which doesn't have Theme.lightPrimaryColor
        Binding {
            target: viconbutton1
            property: "icon.color"
            value: Theme.primaryColor
            when: Theme.lightPrimaryColor !== undefined
        }
        Binding {
            target: cutButton
            property: "icon.color"
            value: Theme.primaryColor
            when: Theme.lightPrimaryColor !== undefined
        }
        Binding {
            target: viconbutton3
            property: "icon.color"
            value: Theme.primaryColor
            when: Theme.lightPrimaryColor !== undefined
        }
        Binding {
            target: viconbutton4
            property: "icon.color"
            value: Theme.primaryColor
            when: Theme.lightPrimaryColor !== undefined
        }
        Binding {
            target: viconbutton5
            property: "icon.color"
            value: Theme.primaryColor
            when: Theme.lightPrimaryColor !== undefined
        }
    }
}
