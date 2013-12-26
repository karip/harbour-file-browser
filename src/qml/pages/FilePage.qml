import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileInfo 1.0
import QtMultimedia 5.0
import Sailfish.Media 1.0
import "functions.js" as Functions

Page {
    id: page
    allowedOrientations: Orientation.All
    property string file: "/"

    FileInfo {
        id: fileInfo
        file: page.file

        // called when open command exits
        onProcessExited: {
            if (exitCode === 0) {
                notificationPanel.showWithText("Open successful",
                                               "Sometimes the application is left into background");
            } else if (exitCode === 1) {
                notificationPanel.showWithText("Internal error",
                                               "xdg-open exit code 1");
            } else if (exitCode === 2) {
                notificationPanel.showWithText("File not found",
                                               page.file);
            } else if (exitCode === 3) {
                notificationPanel.showWithText("No application to open the file",
                                               "xdg-open found no preferred application (3)");
            } else if (exitCode === 4) {
                notificationPanel.showWithText("Action failed",
                                               "xdg-open exit code 4");
            } else if (exitCode === -88888) {
                notificationPanel.showWithText("xdg-open not found");
            }
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        PullDownMenu {
            MenuItem {
                text: "Go to SD Card"
                onClicked: {
                    var sdcard = Functions.sdcardPath();
                    if (engine.exists(sdcard)) {
                        Functions.goToFolder(sdcard, page.file);
                    } else {
                        notificationPanel.showWithText("SD Card not found", sdcard);
                    }
                }
            }
            MenuItem {
                text: "Go to Home"
                onClicked: Functions.goToHome(StandardPaths.documents, page.file)
            }
            MenuItem {
                text: "Install"
                visible: fileInfo.suffix === "apk" || fileInfo.suffix === "rpm"
                onClicked: {
                    if (fileInfo.suffix === "apk") {
                        pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                                       { title: "Install",
                                           successText: "Install Launched",
                                           infoText: "If the application is already installed, then this will probably do nothing.",
                                           command: "apkd-install",
                                           arguments: [ fileInfo.file ] })
                    }
                    if (fileInfo.suffix === "rpm") {
                        pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                                       { title: "Install",
                                           successText: "Install Finished",
                                           command: "pkcon",
                                           arguments: [ "-y", "-p", "install-local",
                                                        fileInfo.file ] })
                    }
                }
            }
            // open menu tries to open the file and fileInfo.onProcessExited show error if it fails
            MenuItem {
                text: "Open"
                visible: fileInfo.suffix !== "apk" && fileInfo.suffix !== "rpm" && fileInfo.suffix !== "mp3" // && fileInfo.suffix !== "mp4"
                onClicked: fileInfo.executeCommand("xdg-open", [ page.file ])
            }
            MenuItem {
                text: "Play " + (fileInfo.suffix == "mp3" ? "Music" : "Video")
                visible: fileInfo.suffix == "mp3" || fileInfo.suffix == "mp4"
                onClicked: {
                    if (fileInfo.suffix == "mp3"){
                        playMedia.play();
                        videoOut.visible = false;
                    }
                    if (fileInfo.suffix == "mp4"){
                        videoOut.visible = true;
                        videoOut.play();

                    }
                }
                MediaPlayer{ //used to play audio since xdg-open will not work
                    id: playMedia
                    source: fileInfo.file
                }
            }
        }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge

            PageHeader { title: Functions.formatPathForTitle(fileInfo.absolutePath) }

            // file info texts, visible if error is not set
            Column {
                visible: fileInfo.errorMessage === ""
                anchors.left: parent.left
                anchors.right: parent.right

                Image {
                    id: icon
                    anchors.topMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "../images/large-"+fileInfo.icon+".png"
                }
                Label {
                    width: parent.width
                    text: fileInfo.name
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    visible: fileInfo.symLinkTarget !== ""
                    width: parent.width
                    text: "\u2192 "+fileInfo.symLinkTarget // uses unicode arrow
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Item { // used for spacing
                    width: parent.width
                    height: 40
                }
                VideoPlayer{ //used to play video since xdg-open will not work
                    id: videoOut
                    source: fileInfo.file
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 400
                    width: parent.width
                    visible: false
                }
                Item { // used for spacing
                    width: parent.width
                    height: 40
                }
                Row {
                    width: parent.width
                    spacing: 10
                    Label {
                        id: firstLabel
                        text: "Location"
                        color: Theme.secondaryColor
                        width: parent.width/2
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    Label {
                        text: fileInfo.absolutePath
                        wrapMode: Text.Wrap
                        width: parent.width/2
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
                Row {
                    width: parent.width
                    spacing: 10
                    Label {
                        text: "Size"
                        color: Theme.secondaryColor
                        width: parent.width/2
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    Label {
                        text: fileInfo.size
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
                Row {
                    spacing: 10
                    Label {
                        text: "Permissions"
                        color: Theme.secondaryColor
                        width: firstLabel.width
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    Label {
                        text: fileInfo.permissions
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
                Row {
                    spacing: 10
                    Label {
                        text: "Last modified"
                        color: Theme.secondaryColor
                        width: firstLabel.width
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    Label {
                        text: fileInfo.modified
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
                Row {
                    spacing: 10
                    Label {
                        text: "Created"
                        color: Theme.secondaryColor
                        width: firstLabel.width
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    Label {
                        text: fileInfo.created
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            // error label, visible if error message is set
            Label {
                visible: fileInfo.errorMessage !== ""
                anchors.left: parent.left
                anchors.right: parent.right
                horizontalAlignment: Text.AlignHCenter
                text: fileInfo.errorMessage
                wrapMode: Text.Wrap
            }
        }
    }

    // update cover
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            coverPlaceholder.text = "File Browser\n"+Functions.formatPathForCover(page.file);
        }
        //Pop of page detected to reset video player visibility
        if (status == 3 ){
            videoOut.visible = false;

        }
    }


    // notification panel to display messages at top of the screen
    DockedPanel {
        id: notificationPanel

        width: parent.width
        height: Theme.itemSizeExtraLarge + Theme.paddingLarge

        dock: Dock.Top
        open: false
        onOpenChanged: {
            interactionBlocker.visible = open; // disable row selection and menus
            page.backNavigation = !open; // disable back navigation
        }

        function showWithText(header, txt) {
            notificationHeader.text = header;
            notificationText.text = txt;
            notificationPanel.show();
            notificationTimer.start();
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.7
        }
        Label {
            id: notificationHeader
            visible: notificationPanel.open
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            anchors.topMargin: 40
            horizontalAlignment: Text.AlignHCenter
            text: ""
            wrapMode: Text.Wrap
            color: Theme.primaryColor
        }
        Label {
            id: notificationText
            visible: notificationPanel.open
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: notificationHeader.bottom
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            horizontalAlignment: Text.AlignHCenter
            text: ""
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.primaryColor
        }
        Timer {
            id: notificationTimer
            interval: 5000
            onTriggered: {
                notificationPanel.hide();
                stop();
            }
        }
    }

}


