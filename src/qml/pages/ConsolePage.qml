import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.ConsoleModel 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property string title: ""
    property string command: ""
    property variant arguments // this must be set to a string list, e.g. [ "arg1", "arg2" ]
    property color consoleColor: Theme.secondaryColor

    // execute command when page activates
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            consoleModel.executeCommand(page.command, page.arguments);
        }
    }

    ConsoleModel {
        id: consoleModel
    }

    // display console text as a list, it is much faster compared to a Text item
    SilicaListView {
        id: itemList
        anchors.fill: parent

        model: consoleModel

        VerticalScrollDecorator { flickable: itemList }

        header: PageHeader { title: page.title }

        delegate: Item {
            id: listItem
            width: ListView.view.width
            height: listLabel.height-24

            Text {
                id: listLabel
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x

                text: modelData
                textFormat: Text.PlainText
                color: page.consoleColor
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
            }
        }
    }
}


