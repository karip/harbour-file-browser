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
                                               qsTr("xdg-open found no preferred application"));
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
                onClicked: {
                    if (!fileData.isSafeToOpen()) {
                        notificationPanel.showTextWithTimer(qsTr("File cannot be opened"),
                                                   qsTr("This type of file cannot be opened."));
                        return;
                    }
                    consoleModel.executeCommand("xdg-open", [ page.file ])
                }
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
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x

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
                Spacer { height: Theme.paddingMedium; visible: playButton.visible } // fix to playButton height
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
                            height: implicitHeight < 400 * Theme.pixelRatio && implicitHeight != 0
                                    ? implicitHeight * Theme.pixelRatio
                                    : 400 * Theme.pixelRatio
                            width: parent.width
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        // HighlightImage replaced with a Loader so that HighlightImage or Image
                        // can be loaded depending on Sailfish version (lightPrimaryColor is defined on SF3)
                        Loader {
                            id: icon
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: !imagePreview.visible && !playButton.visible
                            width: 128 * Theme.pixelRatio
                            height: 128 * Theme.pixelRatio
                            Component.onCompleted: {
                                var qml = Theme.lightPrimaryColor ? "../components/MyHighlightImage3.qml"
                                                                  : "../components/MyHighlightImage2.qml";
                                setSource(qml, {
                                    imgsrc: "../images/large-"+fileData.icon+".png",
                                    imgw: 128 * Theme.pixelRatio,
                                    imgh: 128 * Theme.pixelRatio
                                })
                            }
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
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            color: openButton.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            visible: fileData.isSymLink
                            width: parent.width
                            text: Functions.unicodeArrow()+" "+fileData.symLinkTarget
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: fileData.isSymLinkBroken ? "red" :
                                    (openButton.highlighted ? Theme.highlightColor
                                                            : Theme.primaryColor)
                        }
                        Spacer { height: Theme.paddingLarge }
                    }
                }

                // Display metadata with priotity < 5
                Repeater {
                    model: fileData.metaData
                    // first char is priority (0-9), labels and values are delimited with ':'
                    DetailItem {
                        visible: modelData.charAt(0) < '5'
                        label: modelData.substring(1, modelData.indexOf(":"))
                        value: Functions.trim(modelData.substring(modelData.indexOf(":")+1))
                    }
                }

                DetailItem {
                    label: qsTr("Location")
                    value: fileData.absolutePath
                }
                DetailItem {
                    label: qsTr("Type")
                    value: fileData.isSymLink
                           ? qsTr("Link to %1").arg(fileData.mimeTypeComment) + "\n("+fileData.mimeType+")"
                           : fileData.mimeTypeComment + "\n("+fileData.mimeType+")"
                }
                DetailItem {
                    label: qsTr("Size")
                    value: fileData.size
                }
                DetailItem {
                    label: qsTr("Permissions")
                    value: fileData.permissions
                }
                DetailItem {
                    label: qsTr("Owner")
                    value: fileData.owner
                }
                DetailItem {
                    label: qsTr("Group")
                    value: fileData.group
                }
                DetailItem {
                    label: qsTr("Last modified")
                    value: fileData.modified
                }
                // Display metadata with priority >= 5
                Repeater {
                    model: fileData.metaData
                    // first char is priority (0-9), labels and values are delimited with ':'
                    DetailItem {
                        visible: modelData.charAt(0) >= '5'
                        label: modelData.substring(1, modelData.indexOf(":"))
                        value: Functions.trim(modelData.substring(modelData.indexOf(":")+1))
                    }
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
            coverText = Functions.lastPartOfPath(page.file);
        }
    }

    DirPopup {
        id: dirPopup
        anchors.fill: parent
        menuTop: Theme.itemSizeMedium
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


