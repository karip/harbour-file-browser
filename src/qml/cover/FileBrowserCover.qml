import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    CoverPlaceholder {
        id: coverPlaceholder
        text: coverText
        icon.width: Theme.iconSizeLarge
        icon.height: Theme.iconSizeLarge
        icon.source: "../images/harbour-file-browser.png"
    }
}
