// A polaroid: square photo, wide bottom edge for a caption.
//   props.caption  optional handwritten text
//   props.curl     lifted corner
//   props.backing  black | white: that color behind the picture
import QtQuick
import qs.services

Item {
    id: root

    property var sticker
    property var payload

    readonly property string asset: sticker && sticker.props.asset ? sticker.props.asset : ""
    readonly property color backing: sticker && Look.backings[sticker.props.backing] || "transparent"

    implicitWidth: Look.polaroidPhoto + 2 * Look.polaroidSide
    implicitHeight: Look.polaroidPhoto + Look.polaroidSide + Look.polaroidBottom
    layer.enabled: true
    layer.effect: Shadow { sticker: root.sticker }

    Paper {
        id: paper
        anchors.fill: parent
        layer.enabled: true
        color: Look.polaroidPaper
        curl: root.sticker && root.sticker.props.curl ? Look.curlSize : 0
    }

    Rectangle {
        visible: root.backing.a > 0
        x: Look.polaroidSide
        y: Look.polaroidSide
        width: Look.polaroidPhoto
        height: Look.polaroidPhoto
        color: root.backing
    }

    Image {
        x: Look.polaroidSide
        y: Look.polaroidSide
        width: Look.polaroidPhoto
        height: Look.polaroidPhoto
        source: Board.assetUrl(root.asset)
        fillMode: Image.PreserveAspectCrop
        mipmap: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Look.polaroidBottom / 2 - font.pixelSize / 2
        text: root.sticker && root.sticker.props.caption ? root.sticker.props.caption : ""
        font.family: Look.markerFont
        font.pixelSize: 20
        color: "#333333"
    }

    Sheen {
        anchors.fill: parent
    }
}
