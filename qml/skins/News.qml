// A newspaper clipping: torn newsprint, a masthead, a headline, the picture
// in black and white beside columns of text.
//   props.caption  the headline ("EXTRA! EXTRA!" by default)
//   props.backing  black | white: that color behind the picture
import QtQuick
import QtQuick.Effects
import qs.services

Item {
    id: root

    property var sticker
    property var payload

    readonly property string asset: sticker && sticker.props.asset ? sticker.props.asset : ""
    readonly property color backing: sticker && Look.backings[sticker.props.backing] || "transparent"
    readonly property string headline: sticker && sticker.props.caption ? sticker.props.caption : "EXTRA! EXTRA!"
    readonly property real pad: 18

    implicitWidth: Look.newsWidth
    implicitHeight: content.height + 2 * pad
    layer.enabled: true
    layer.effect: Shadow { sticker: root.sticker }

    // Newsprint torn on every side (fixed seed: the edge does not jump).
    Canvas {
        id: paper
        anchors.fill: parent
        layer.enabled: true
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d"), w = width, h = height, step = 6, j = 6;
            let seed = 11;
            const rnd = () => (seed = (seed * 9301 + 49297) % 233280) / 233280;
            ctx.reset();
            ctx.fillStyle = Look.newsPaper;
            ctx.beginPath();
            ctx.moveTo(rnd() * j, rnd() * j);
            for (let x = step; x < w; x += step)
                ctx.lineTo(x, rnd() * j);
            for (let y = step; y < h; y += step)
                ctx.lineTo(w - rnd() * j, y);
            for (let x = w - step; x > 0; x -= step)
                ctx.lineTo(x, h - rnd() * j);
            for (let y = h - step; y > 0; y -= step)
                ctx.lineTo(rnd() * j, y);
            ctx.closePath();
            ctx.fill();
        }
    }

    Column {
        id: content
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: 6

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "The Daily Sticker"
            font.family: Look.newsMastFont
            font.pixelSize: 24
            color: Look.newsInk
        }
        Rectangle {
            width: parent.width
            height: 1
            color: Look.newsInk
        }
        Text {
            width: parent.width
            text: Qt.formatDate(new Date(), "dddd, MMMM d, yyyy").toUpperCase() + " · No. " + (root.sticker ? root.sticker.id.length * 37 : 0)
            font.family: Look.newsFont
            font.pixelSize: 8
            color: Look.newsInk
            elide: Text.ElideRight
        }
        Rectangle {
            width: parent.width
            height: 2
            color: Look.newsInk
        }
        Text {
            width: parent.width
            text: root.headline
            font.family: Look.newsFont
            font.bold: true
            font.pixelSize: 26
            lineHeight: 0.9
            wrapMode: Text.Wrap
            color: Look.newsInk
        }

        Row {
            spacing: 8

            Image {
                id: photo
                width: content.width * 0.58
                height: width * 0.8
                source: Board.assetUrl(root.asset)
                fillMode: Image.PreserveAspectCrop
                mipmap: true
                visible: false
            }
            Rectangle {
                width: photo.width
                height: photo.height
                color: root.backing.a > 0 ? root.backing : "transparent"

                MultiEffect {
                    anchors.fill: parent
                    source: photo
                    saturation: -1
                    contrast: 0.25
                    brightness: -0.05
                }
            }

            // Columns of text, drawn as gray lines.
            Canvas {
                width: content.width - photo.width - 8
                height: photo.height
                onPaint: {
                    const ctx = getContext("2d");
                    let seed = 3;
                    const rnd = () => (seed = (seed * 9301 + 49297) % 233280) / 233280;
                    ctx.reset();
                    ctx.fillStyle = "rgba(30, 30, 30, 0.55)";
                    for (let y = 2; y < height - 3; y += 6)
                        ctx.fillRect(0, y, width * (rnd() < 0.15 ? 0.5 + rnd() * 0.4 : 1), 2);
                }
            }
        }

        Canvas {
            width: content.width
            height: 34
            onPaint: {
                const ctx = getContext("2d");
                let seed = 5;
                const rnd = () => (seed = (seed * 9301 + 49297) % 233280) / 233280;
                const col = (width - 8) / 2;
                ctx.reset();
                ctx.fillStyle = "rgba(30, 30, 30, 0.55)";
                for (const x0 of [0, col + 8])
                    for (let y = 2; y < height - 3; y += 6)
                        ctx.fillRect(x0, y, col * (rnd() < 0.15 ? 0.5 + rnd() * 0.4 : 1), 2);
            }
        }
    }
}
