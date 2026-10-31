// A die-cut sticker: the picture over its white silhouette (made at import).
//   props.peel  corner peeled back
//   props.backing  black | white: a card of that color behind the picture
//   props.outline  white (default) | black | none: the die-cut border
import QtQuick
import QtQuick.Effects
import qs.services

Item {
    id: root

    property var sticker
    property var payload

    readonly property string asset: sticker && sticker.props.asset ? sticker.props.asset : ""
    readonly property color backing: sticker && Look.backings[sticker.props.backing] || "transparent"
    readonly property bool backed: backing.a > 0
    readonly property string outline: sticker && sticker.props.outline || "white"
    // With a backing the die-cut is a rounded card, not the silhouette.
    readonly property url cutSource: backed ? Board.cardUrl(asset) : Board.cutUrl(asset)
    readonly property real fit: Look.imageSide / Math.max(1, picture.sourceSize.width, picture.sourceSize.height)

    implicitWidth: picture.sourceSize.width * fit
    implicitHeight: picture.sourceSize.height * fit
    layer.enabled: true
    layer.effect: Shadow { sticker: root.sticker }

    Peel {
        anchors.fill: parent
        peel: !!root.sticker && !!root.sticker.props.peel
        cut: root.cutSource
        size: Math.min(width, height) * Look.peelRatio

        Image {
            // The die-cut shape: drawn as the outline, and clips the gloss.
            id: cut
            anchors.fill: parent
            source: root.cutSource
            mipmap: true
            visible: false
            layer.enabled: true
        }
        MultiEffect {
            visible: root.outline !== "none"
            anchors.fill: parent
            source: cut
            brightness: root.outline === "black" ? -1 : 0
        }

        Rectangle {
            // Without an outline the backing fills the whole card.
            readonly property real inset: root.outline === "none" ? 0 : Look.cutBorder * root.fit
            visible: root.backed
            anchors.fill: parent
            anchors.margins: inset
            radius: root.outline === "none" ? Look.cutBorder * 1.5 * root.fit : Look.cutBorder * 0.5 * root.fit
            color: root.backing
        }

        Image {
            id: picture
            anchors.fill: parent
            source: Board.assetUrl(root.asset)
            mipmap: true
            layer.enabled: root.outline === "none" && !root.backed  // then it clips the gloss
        }

        Sheen {
            anchors.fill: parent
            maskItem: root.outline === "none" && !root.backed ? picture : cut
        }
    }
}
