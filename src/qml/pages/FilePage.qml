import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileInfo 1.0
import harbour.file.browser.ConsoleModel 1.0
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
    }

    ConsoleModel {
        id: consoleModel

        // called when open command exits
        onProcessExited: {
            if (exitCode === 0) {
                if (isApkFile()) {
                    notificationPanel.showTextWithTimer(qsTr("Install launched"),
                                               qsTr("If nothing happens, then the package is probably faulty."));
                    return;
                }
                if (!isRpmFile())
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
                onClicked: viewContents()
            }
            // open/install tries to open the file and fileInfo.onProcessExited shows error
            // if it fails
            MenuItem {
                text: isRpmFile() || isApkFile() ? qsTr("Install") : qsTr("Open")
                visible: !fileInfo.isDir
                onClicked: consoleModel.executeCommand("xdg-open", [ page.file ])
            }

            MenuItem {
                text: qsTr("Go to Target")
                visible: fileInfo.isSymLink && fileInfo.isDir
                onClicked: Functions.goToFolder(fileInfo.symLinkTarget);
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

                IconButton {
                    id: playButton
                    visible: isAudioFile()
                    icon.source: audioPlayer.playbackState !== MediaPlayer.PlayingState ?
                                     "image://theme/icon-l-play" :
                                     "image://theme/icon-l-pause"
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: playAudio();
                    MediaPlayer { // prelisten of audio
                        id: audioPlayer
                        source: ""
                    }
                }
                Spacer { height: 10; visible: playButton.visible } // fix to playButton height
                // clickable icon and filename
                BackgroundItem {
                    id: openButton
                    width: parent.width
                    height: openArea.height
                    onClicked: quickView()

                    Column {
                        id: openArea
                        width: parent.width

                        Image { // preview of image, max height 400
                            id: imagePreview
                            visible: isImageFile()
                            source: visible ? fileInfo.file : "" // access the source only if img is visible
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: implicitHeight < 400 && implicitHeight != 0 ? implicitHeight : 400
                            width: parent.width
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        Image {
                            id: icon
                            anchors.topMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: "../images/large-"+fileInfo.icon+".png"
                            visible: !imagePreview.visible && !playButton.visible
                        }
                        Spacer { // spacing if image or play button is visible
                            id: spacer
                            height: 24
                            visible: imagePreview.visible || playButton.visible
                        }
                        Label {
                            id: filename
                            width: parent.width
                            text: fileInfo.name
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Label {
                            visible: fileInfo.isSymLink
                            width: parent.width
                            text: Functions.unicodeArrow()+" "+fileInfo.symLinkTarget
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: fileInfo.isSymLinkBroken ? "red" : Theme.primaryColor
                        }
                        Spacer { height: 20 }
                    }
                }
                Spacer { height: 20 }

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
                    label: qsTr("Type")
                    value: fileInfo.isSymLink ? qsTr("Link to %1").arg(fileInfo.type) :
                                                fileInfo.type
                }
                CenteredField {
                    label: "" // blank label
                    value: "("+fileInfo.mimeType+")"
                    valueElide: page.orientation === Orientation.Portrait ? Text.ElideMiddle : Text.ElideNone
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
                color: Theme.highlightColor
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

    function isImageFile()
    {
        return fileInfo.mimeType === "image/jpeg" || fileInfo.mimeType === "image/png" ||
                fileInfo.mimeType === "image/gif";
    }

    function isAudioFile()
    {
        return fileInfo.mimeType === "audio/x-wav" || fileInfo.mimeType === "audio/mpeg" ||
                fileInfo.mimeType === "audio/x-vorbis+ogg" || fileInfo.mimeType === "audio/flac" ||
                fileInfo.mimeType === "audio/mp4";
    }

    function isVideoFile()
    {
        return fileInfo.mimeType === "video/quicktime" || fileInfo.mimeType === "video/mp4";
    }

    function isMediaFile()
    {
        return isAudioFile() | isVideoFile();
    }

    function isZipFile()
    {
        return fileInfo.mimeTypeInherits("application/zip");
    }

    function isRpmFile()
    {
        return fileInfo.mimeType === "application/x-rpm";
    }

    function isApkFile()
    {
        return fileInfo.suffix === "apk" && fileInfo.mimeType === "application/vnd.android.package-archive";
    }

    function quickView()
    {
        // dirs are special cases - there's no way to display their contents, so go to them
        if (fileInfo.isDir && fileInfo.isSymLink) {
            Functions.goToFolder(fileInfo.symLinkTarget);

        } else if (fileInfo.isDir) {
            Functions.goToFolder(fileInfo.file);

        } else {
            viewContents();
        }
    }

    function viewContents()
    {
        // view depending on file type
        if (fileInfo.suffix === "jpg") {
            pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Functions.lastPartOfPath(fileInfo.file),
                           command: "rdjpgcom",
                           arguments: [ "-verbose", fileInfo.file ] })

        } else if (isImageFile() || isVideoFile() || isAudioFile()) {
            pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Functions.lastPartOfPath(fileInfo.file),
                           command: "file",
                           arguments: [ "-b", fileInfo.file ] })

        } else if (isZipFile()) {
            pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Functions.lastPartOfPath(fileInfo.file),
                           command: "unzip",
                           arguments: [ "-Z", "-2ht", fileInfo.file ] })

        } else if (isRpmFile()) {
            pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Functions.lastPartOfPath(fileInfo.file),
                           command: "rpm",
                           arguments: [ "-qlp", "--info", fileInfo.file ] })

        } else {
            pageStack.push(Qt.resolvedUrl("ViewPage.qml"), { path: page.file });
        }
    }

    function playAudio()
    {
        if (audioPlayer.playbackState !== MediaPlayer.PlayingState) {
            audioPlayer.source = fileInfo.file;
            audioPlayer.play();
        } else {
            audioPlayer.stop();
        }
    }

}


