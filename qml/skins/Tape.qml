// A strip of washi tape (kind "widget").
//   props.pattern  stripes | dots | grid | plain
//   props.color    one of Look.tapeColors
import QtQuick
import qs.services

Item {
    id: root

    property var sticker
    property var payload

    readonly property string pattern: sticker && sticker.props.pattern ? sticker.props.pattern : "stripes"
    readonly property color tint: sticker && sticker.props.color ? sticker.props.color : Look.tapeColors[0]

    implicitWidth: Look.tapeLength
    implicitHeight: Look.tapeWidth

    onPatternChanged: tape.requestPaint()
    onTintChanged: tape.requestPaint()

    Canvas {
        id: tape
        anchors.fill: parent
        opacity: 0.88
        onPaint: {
            const ctx = getContext("2d"), w = width, h = height;
            let seed = 13;
            const rnd = () => (seed = (seed * 9301 + 49297) % 233280) / 233280;
            ctx.reset();
            // Torn ends: zigzag on both short sides.
            ctx.beginPath();
            ctx.moveTo(4, 0);
            ctx.lineTo(w - 4, 0);
            for (let y = 0; y <= h; y += 4)
                ctx.lineTo(w - 4 + (rnd() < 0.5 ? -3 : 3), y);
            ctx.lineTo(4, h);
            for (let y = h; y >= 0; y -= 4)
                ctx.lineTo(4 + (rnd() < 0.5 ? -3 : 3), y);
            ctx.closePath();
            ctx.save();
            ctx.clip();
            ctx.fillStyle = root.tint;
            ctx.fillRect(0, 0, w, h);
            ctx.fillStyle = "rgba(255, 255, 255, 0.55)";
            if (root.pattern === "stripes") {
                for (let x = -h; x < w; x += 16) {
                    ctx.beginPath();
                    ctx.moveTo(x, h);
                    ctx.lineTo(x + h, 0);
                    ctx.lineTo(x + h + 7, 0);
                    ctx.lineTo(x + 7, h);
                    ctx.closePath();
                    ctx.fill();
                }
            } else if (root.pattern === "dots") {
                for (let x = 8; x < w; x += 14)
                    for (let y = 7; y < h; y += 12) {
                        ctx.beginPath();
                        ctx.arc(x + (y % 24 ? 7 : 0), y, 2.5, 0, 2 * Math.PI);
                        ctx.fill();
                    }
            } else if (root.pattern === "grid") {
                for (let x = 0; x < w; x += 10)
                    ctx.fillRect(x, 0, 1.5, h);
                for (let y = 0; y < h; y += 10)
                    ctx.fillRect(0, y, w, 1.5);
            }
            ctx.restore();
        }
    }
}
