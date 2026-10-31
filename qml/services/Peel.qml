// Peels a die-cut sticker's bottom-right corner: the part past the fold is
// hidden and drawn folded back over the sticker, showing its silver back.
// The flap is the silhouette mirrored across the fold, so it follows the shape.
//   peel  on/off     cut  the die-cut image (its alpha is the silhouette)
//   size  how far the fold reaches from the corner, in px
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property bool peel: false
    property url cut
    property real size: 0
    default property alias content: face.data

    // The fold is the line x + y = d; the corner past it is peeled.
    readonly property real d: width + height - size

    Item {
        id: face
        anchors.fill: parent
        layer.enabled: root.peel
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: keep
        }
    }

    Canvas {
        id: keep
        anchors.fill: parent
        visible: false
        layer.enabled: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onSizeChanged() { keep.requestPaint(); }
        }
        onPaint: {
            const ctx = getContext("2d"), w = width, h = height, c = root.size;
            ctx.reset();
            ctx.fillStyle = "black";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w, h - c);
            ctx.lineTo(w - c, h);
            ctx.lineTo(0, h);
            ctx.closePath();
            ctx.fill();
        }
    }

    Canvas {
        id: flap
        anchors.fill: parent
        visible: root.peel
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: loadImage(root.cut)
        onImageLoaded: requestPaint()
        Connections {
            target: root
            function onSizeChanged() { flap.requestPaint(); }
            function onCutChanged() { flap.loadImage(root.cut); }
        }
        onPaint: {
            const ctx = getContext("2d"), w = width, h = height, c = root.size, d = root.d;
            ctx.reset();
            if (!isImageLoaded(root.cut) || c <= 0)
                return;
            // The flap: the silhouette mirrored across the fold...
            ctx.save();
            ctx.beginPath();
            ctx.moveTo(w - c, h);
            ctx.lineTo(w, h - c);
            ctx.lineTo(w - c, h - c);
            ctx.closePath();
            ctx.clip();
            ctx.setTransform(0, -1, -1, 0, d, d);
            ctx.drawImage(root.cut, 0, 0, w, h);
            ctx.restore();
            // ...tinted silver, darker at the fold.
            ctx.globalCompositeOperation = "source-atop";
            const g = ctx.createLinearGradient(w - c / 2, h - c / 2, w - c, h - c);
            g.addColorStop(0, "#9a9ea6");
            g.addColorStop(0.35, "#e9ebef");
            g.addColorStop(1, "#c4c8cf");
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, w, h);
        }
    }
}
