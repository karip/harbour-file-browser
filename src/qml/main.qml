import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow
{
    initialPage: Component {
        DirectoryPage {
            initial: true
        }
    }

    cover: CoverBackground {
        CoverPlaceholder {
            id: coverPlaceholder
            text: "File Browser"
            icon.source: "images/harbour-file-browser.png"
        }
    }
}


