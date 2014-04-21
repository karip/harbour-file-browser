import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.file.browser.FileData 1.0
import harbour.file.browser.ConsoleModel 1.0
import QtMultimedia 5.0
import "functions.js" as Functions
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property string file: "/"

    FileData {
        id: fileData
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
                            fileData.refresh();
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
                visible: !fileData.isDir
                onClicked: viewContents()
            }
            // open/install tries to open the file and fileData.onProcessExited shows error
            // if it fails
            MenuItem {
                text: isRpmFile() || isApkFile() ? qsTr("Install") : qsTr("Open")
                visible: !fileData.isDir
                onClicked: consoleModel.executeCommand("xdg-open", [ page.file ])
            }

            MenuItem {
                text: qsTr("Go to Target")
                visible: fileData.isSymLink && fileData.isDir
                onClicked: Functions.goToFolder(fileData.symLinkTarget);
            }
        }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge

            PageHeader {
                title: Functions.formatPathForTitle(fileData.absolutePath) + " " +
                       Functions.unicodeBlackDownPointingTriangle()
                MouseArea {
                    anchors.fill: parent
                    onClicked: dirPopup.show();
                }
            }

            // file info texts, visible if error is not set
            Column {
                visible: fileData.errorMessage === ""
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
                            source: visible ? fileData.file : "" // access the source only if img is visible
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
                            source: "../images/large-"+fileData.icon+".png"
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
                            text: fileData.name
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Label {
                            visible: fileData.isSymLink
                            width: parent.width
                            text: Functions.unicodeArrow()+" "+fileData.symLinkTarget
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: fileData.isSymLinkBroken ? "red" : Theme.primaryColor
                        }
                        Spacer { height: 20 }
                    }
                }
                Spacer { height: 20 }

                CenteredField {
                    label: qsTr("Location")
                    value: fileData.absolutePath
                }
                CenteredField {
                    label: qsTr("Type")
                    value: fileData.isSymLink ? qsTr("Link to %1").arg(fileData.mimeTypeComment) :
                                                fileData.mimeTypeComment
                }
                CenteredField {
                    label: "" // blank label
                    value: "("+fileData.mimeType+")"
                    valueElide: page.orientation === Orientation.Portrait ? Text.ElideMiddle : Text.ElideNone
                }
                CenteredField {
                    label: qsTr("Size")
                    value: fileData.size
                }
                CenteredField {
                    label: qsTr("Permissions")
                    value: fileData.permissions
                }
                CenteredField {
                    label: qsTr("Owner")
                    value: fileData.owner
                }
                CenteredField {
                    label: qsTr("Group")
                    value: fileData.group
                }
                CenteredField {
                    label: qsTr("Last modified")
                    value: fileData.modified
                }
                CenteredField {
                    label: qsTr("Created")
                    value: fileData.created
                }
                Spacer {
                    height: 10
                }
                // Display all metadata
                Repeater {
                    model: fileData.metaData
                    CenteredField { // labels and values are delimited with ':'
                        label: modelData.substring(0, modelData.indexOf(":"))
                        value: modelData.substring(modelData.indexOf(":")+1)
                    }
                }
                Spacer {
                    height: 10
                }
            }

            // error label, visible if error message is set
            Label {
                visible: fileData.errorMessage !== ""
                anchors.left: parent.left
                anchors.right: parent.right
                horizontalAlignment: Text.AlignHCenter
                text: fileData.errorMessage
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
        return fileData.mimeType === "image/jpeg" || fileData.mimeType === "image/png" ||
                fileData.mimeType === "image/gif";
    }

    function isAudioFile()
    {
        return fileData.mimeType === "audio/x-wav" || fileData.mimeType === "audio/mpeg" ||
                fileData.mimeType === "audio/x-vorbis+ogg" || fileData.mimeType === "audio/flac" ||
                fileData.mimeType === "audio/mp4";
    }

    function isVideoFile()
    {
        return fileData.mimeType === "video/quicktime" || fileData.mimeType === "video/mp4";
    }

    function isMediaFile()
    {
        return isAudioFile() | isVideoFile();
    }

    function isZipFile()
    {
        return fileData.mimeTypeInherits("application/zip");
    }

    function isRpmFile()
    {
        return fileData.mimeType === "application/x-rpm";
    }

    function isApkFile()
    {
        return fileData.suffix === "apk" && fileData.mimeType === "application/vnd.android.package-archive";
    }

    function quickView()
    {
        // dirs are special cases - there's no way to display their contents, so go to them
        if (fileData.isDir && fileData.isSymLink) {
            Functions.goToFolder(fileData.symLinkTarget);

        } else if (fileData.isDir) {
            Functions.goToFolder(fileData.file);

        } else {
            viewContents();
        }
    }

    function viewContents()
    {
        // view depending on file type
        if (isZipFile()) {
            pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Functions.lastPartOfPath(fileData.file),
                           command: "unzip",
                           arguments: [ "-Z", "-2ht", fileData.file ] });

        } else if (isRpmFile()) {
            pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Functions.lastPartOfPath(fileData.file),
                           command: "rpm",
                           arguments: [ "-qlp", "--info", fileData.file ] });

        } else if (fileData.mimeType === "application/x-tar" ||
                   fileData.mimeType === "application/x-compressed-tar" ||
                   fileData.mimeType === "application/x-bzip-compressed-tar") {
            pageStack.push(Qt.resolvedUrl("ConsolePage.qml"),
                         { title: Functions.lastPartOfPath(fileData.file),
                           command: "tar",
                           arguments: [ "tf", fileData.file ] });
        } else {
            pageStack.push(Qt.resolvedUrl("ViewPage.qml"), { path: page.file });
        }
    }

    function playAudio()
    {
        if (audioPlayer.playbackState !== MediaPlayer.PlayingState) {
            audioPlayer.source = fileData.file;
            audioPlayer.play();
        } else {
            audioPlayer.stop();
        }
    }

}


