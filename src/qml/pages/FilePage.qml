import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileInfo 1.0
import QtMultimedia 5.0
import "functions.js" as Functions
import "../components"

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
                notificationPanel.showTextWithTimer(qsTr("Open successful"),
                                               qsTr("Sometimes the application stays in the background"));
            } else if (exitCode === 1) {
                notificationPanel.showTextWithTimer(qsTr("Internal error"),
                                               "xdg-open exit code 1");
            } else if (exitCode === 2) {
                notificationPanel.showTextWithTimer(qsTr("File not found"),
                                               page.file);
            } else if (exitCode === 3) {
                notificationPanel.showTextWithTimer(qsTr("No application to open the file"),
                                               qsTr("xdg-open found no preferred application (3)"));
            } else if (exitCode === 4) {
                notificationPanel.showTextWithTimer(qsTr("Action failed"),
                                               "xdg-open exit code 4");
            } else if (exitCode === -88888) {
                notificationPanel.showTextWithTimer(qsTr("xdg-open not found"), "");

            } else if (exitCode === -99999) {
                notificationPanel.showTextWithTimer(qsTr("xdg-open crash?"), "");

            } else {
                notificationPanel.showTextWithTimer(qsTr("xdg-open error"), "exit code: "+exitCode);
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
                text: qsTr("Change Permissions")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("PermissionsDialog.qml"),
                                                { path: page.file })
                    dialog.accepted.connect(function() {
                        if (dialog.errorMessage === "")
                            fileInfo.refresh();
                        else
                            notificationPanel.showTextWithTimer(dialog.errorMessage, "");
                    })
                }
            }
            MenuItem {
                text: qsTr("Rename")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("RenameDialog.qml"),
                                                { path: page.file })
                    dialog.accepted.connect(function() {
                        if (dialog.errorMessage === "")
                            page.file = dialog.newPath;
                        else
                            notificationPanel.showTextWithTimer(dialog.errorMessage, "");
                    })
                }
            }

            MenuItem {
                text: qsTr("View Contents")
                visible: !fileInfo.isDir
                onClicked: pageStack.push(Qt.resolvedUrl("ViewPage.qml"),
                                          { path: page.file });
            }
            // open menu tries to open the file and fileInfo.onProcessExited shows error if it fails
            MenuItem {
                text: qsTr("Open")
                visible: !fileInfo.isDir
                onClicked: fileInfo.executeCommand("xdg-open", [ page.file ])
            }

            // file type specific menu items

            MenuItem {
                text: qsTr("Install")
                visible: fileInfo.suffix === "apk" || fileInfo.suffix === "rpm" && !fileInfo.isDir
                onClicked: {
                    if (fileInfo.suffix === "apk") {
                        pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                                       { title: qsTr("Install"),
                                           successText: qsTr("Install Launched"),
                                           infoText: qsTr("If the app is already installed or the package is faulty, then nothing happens."),
                                           command: "apkd-install",
                                           arguments: [ fileInfo.file ] })
                    }
                    if (fileInfo.suffix === "rpm") {
                        pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                                       { title: qsTr("Install"),
                                           successText: qsTr("Install Finished"),
                                           command: "pkcon",
                                           arguments: [ "-y", "-p", "install-local",
                                                        fileInfo.file ] })
                    }
                }
            }
            MenuItem {
                text: qsTr("Go to Target")
                visible: fileInfo.icon === "folder-link"
                onClicked: Functions.goToFolder(fileInfo.symLinkTarget);
            }
            MenuItem {
                text: playMedia.playbackState !== MediaPlayer.PlayingState ? qsTr("Play") : qsTr("Stop")
                visible: isAudioFile(fileInfo)
                onClicked: {
                    if (isAudioFile(fileInfo)) {
                        if (playMedia.playbackState !== MediaPlayer.PlayingState) {
                            playMedia.source = fileInfo.file;
                            playMedia.play();
                        } else {
                            playMedia.stop();
                        }
                    }
                }
                MediaPlayer { // prelisten of audio
                    id: playMedia
                    source: ""
                }
            }
        }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge

            PageHeader {
                title: Functions.formatPathForTitle(fileInfo.absolutePath) + " " +
                       Functions.unicodeBlackDownPointingTriangle()
                MouseArea {
                    anchors.fill: parent
                    onClicked: dirPopup.show();
                }
            }

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
                    visible: !imagePreview.visible
                }
                Image { // preview of image, max height 400
                    id: imagePreview
                    visible: isImageFile(fileInfo)
                    source: visible ? fileInfo.file : "" // access the source only if img is visible
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: implicitHeight < 400 && implicitHeight != 0 ? implicitHeight : 400
                    width: parent.width
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                Spacer { // spacing if image or video is visible
                    height: 24
                    visible: imagePreview.visible
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
                    text: Functions.unicodeArrow()+" "+fileInfo.symLinkTarget
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                }

                Spacer { height: 40 }

                Label {
                    visible: fileInfo.suffix === "apk" || fileInfo.suffix === "rpm" && !fileInfo.isDir
                    width: parent.width
                    text: qsTr("Installable packages may contain malware.")
                    color: "red"
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
                Spacer {
                    visible: fileInfo.suffix === "apk" || fileInfo.suffix === "rpm" && !fileInfo.isDir
                    height: 40
                }

                CenteredField {
                    label: qsTr("Location")
                    value: fileInfo.absolutePath
                }
                CenteredField {
                    label: qsTr("Size")
                    value: fileInfo.size
                }
                CenteredField {
                    label: qsTr("Permissions")
                    value: fileInfo.permissions
                }
                CenteredField {
                    label: qsTr("Owner")
                    value: fileInfo.owner
                }
                CenteredField {
                    label: qsTr("Group")
                    value: fileInfo.group
                }
                CenteredField {
                    label: qsTr("Last modified")
                    value: fileInfo.modified
                }
                CenteredField {
                    label: qsTr("Created")
                    value: fileInfo.created
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
            coverPlaceholder.text = Functions.lastPartOfPath(page.file);
        }
    }

    DirPopup {
        id: dirPopup
        anchors.fill: parent
        menuTop: 100
    }

    NotificationPanel {
        id: notificationPanel
        page: page
    }

    function isImageFile(fileInfo)
    {
        if (fileInfo.isDir) return false;
        return fileInfo.suffix === "jpg" || fileInfo.suffix === "jpeg" ||
                fileInfo.suffix === "png" || fileInfo.suffix === "gif";
    }

    function isAudioFile(fileInfo)
    {
        if (fileInfo.isDir) return false;
        return fileInfo.suffix === "wav" || fileInfo.suffix === "mp3" ||
                fileInfo.suffix === "ogg" || fileInfo.suffix === "flac" ||
                fileInfo.suffix === "aac" || fileInfo.suffix === "m4a";
    }

    function isVideoFile(fileInfo)
    {
        if (fileInfo.isDir) return false;
        return fileInfo.suffix === "mp4" || fileInfo.suffix === "m4v";
    }

    function isMediaFile(fileInfo)
    {
        if (fileInfo.isDir) return false;
        return isAudioFile(fileInfo) | isVideoFile(fileInfo);
    }

}


