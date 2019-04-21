import QtQuick 2.0
import Sailfish.Silica 1.0

// HighlightImage for Sailfish 2 (uses normal Image)
Item {
    property alias imgsrc: myimg.source
    property alias imgw: myimg.width
    property alias imgh: myimg.height
    Image {
        id: myimg
    }
}
