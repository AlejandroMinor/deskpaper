// A postage stamp: the picture on paper with a perforated edge.
//   props.caption  optional text under the picture
//   props.backing  black | white: that color behind the picture
import QtQuick
import qs.services

Item {
    id: root

    property var sticker
    property var payload

    readonly property string asset: sticker && sticker.props.asset ? sticker.props.asset : ""
    readonly property color backing: sticker && Look.backings[sticker.props.backing] || "transparent"
    readonly property string caption: sticker && sticker.props.caption ? sticker.props.caption : ""
    readonly property real fit: (Look.imageSide - 2 * Look.stampMargin) / Math.max(1, picture.sourceSize.width, picture.sourceSize.height)

    implicitWidth: picture.width + 2 * Look.stampMargin
    implicitHeight: picture.height + 2 * Look.stampMargin + (caption ? 22 : 0)
    layer.enabled: true
    layer.effect: Shadow { sticker: root.sticker }

    Canvas {
        id: paper
        anchors.fill: parent
        layer.enabled: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d"), w = width, h = height, r = Look.stampHole;
            ctx.reset();
            ctx.fillStyle = Look.stampPaper;
            ctx.fillRect(0, 0, w, h);
            ctx.globalCompositeOperation = "destination-out";
            const holes = (length, put) => {
                const n = Math.max(1, Math.round(length / Look.stampStep));
                for (let i = 0; i <= n; i++)
                    put(i * length / n);
            };
            const hole = (x, y) => {
                ctx.beginPath();
                ctx.arc(x, y, r, 0, 2 * Math.PI);
                ctx.fill();
            };
            holes(w, x => { hole(x, 0); hole(x, h); });
            holes(h, y => { hole(0, y); hole(w, y); });
        }
    }

    Rectangle {
        visible: root.backing.a > 0
        x: picture.x
        y: picture.y
        width: picture.width
        height: picture.height
        color: root.backing
    }

    Image {
        id: picture
        x: Look.stampMargin
        y: Look.stampMargin
        width: sourceSize.width * root.fit
        height: sourceSize.height * root.fit
        source: Board.assetUrl(root.asset)
        mipmap: true
    }

    Text {
        visible: root.caption !== ""
        anchors.top: picture.bottom
        anchors.topMargin: 4
        anchors.left: picture.left
        text: root.caption
        font.family: Look.typeFont
        font.pixelSize: 13
        color: "#7a1c1c"
    }

    Sheen {
        anchors.fill: parent
    }
}
