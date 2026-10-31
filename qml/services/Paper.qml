// A sheet of paper, optionally with its bottom-right corner lifted.
//   curl  size of the lifted corner in px; 0 = flat
import QtQuick

Canvas {
    id: root

    property color color: "white"
    property real curl: 0

    onColorChanged: requestPaint()
    onCurlChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d"), w = width, h = height, c = Math.min(curl, w / 2, h / 2);
        ctx.reset();
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(w, 0);
        ctx.lineTo(w, h - c);
        ctx.lineTo(w - c, h);
        ctx.lineTo(0, h);
        ctx.closePath();
        ctx.fill();
        if (c <= 0)
            return;
        // The back of the lifted corner, with a soft shadow under it.
        ctx.save();
        ctx.shadowColor = "rgba(0, 0, 0, 0.35)";
        ctx.shadowBlur = c / 4;
        ctx.shadowOffsetX = -c / 10;
        ctx.shadowOffsetY = -c / 10;
        const back = ctx.createLinearGradient(w - c, h - c, w - c / 2, h - c / 2);
        back.addColorStop(0, Qt.lighter(color, 1.08));
        back.addColorStop(1, Qt.darker(color, 1.18));
        ctx.fillStyle = back;
        ctx.beginPath();
        ctx.moveTo(w - c, h);
        ctx.lineTo(w, h - c);
        ctx.lineTo(w - c, h - c);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
    }
}
