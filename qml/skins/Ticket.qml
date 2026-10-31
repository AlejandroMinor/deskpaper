// An admission ticket: notched sides, the picture on the stub, a title.
//   props.caption  the title ("ONE LIFE" by default)
//   props.backing  black | white: that color behind the picture
import QtQuick
import qs.services

Item {
    id: root

    property var sticker
    property var payload

    readonly property string asset: sticker && sticker.props.asset ? sticker.props.asset : ""
    readonly property color backing: sticker && Look.backings[sticker.props.backing] || "transparent"
    readonly property string caption: sticker && sticker.props.caption ? sticker.props.caption : "ONE LIFE"

    implicitWidth: Look.ticketWidth
    implicitHeight: Look.ticketHeight
    layer.enabled: true
    layer.effect: Shadow { sticker: root.sticker }

    Canvas {
        id: paper
        anchors.fill: parent
        layer.enabled: true
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d"), w = width, h = height, r = Look.ticketNotch, stub = h;
            ctx.reset();
            ctx.fillStyle = Look.ticketPaper;
            ctx.fillRect(0, 0, w, h);
            ctx.globalCompositeOperation = "destination-out";
            for (const x of [0, w]) {
                ctx.beginPath();
                ctx.arc(x, h / 2, r, 0, 2 * Math.PI);
                ctx.fill();
            }
            ctx.globalCompositeOperation = "source-over";
            // Perforation between the stub and the body.
            ctx.strokeStyle = "rgba(0, 0, 0, 0.35)";
            ctx.setLineDash([4, 4]);
            ctx.beginPath();
            ctx.moveTo(stub, 8);
            ctx.lineTo(stub, h - 8);
            ctx.stroke();
        }
    }

    Rectangle {
        visible: root.backing.a > 0
        x: 12
        y: 12
        width: root.height - 24
        height: root.height - 24
        color: root.backing
    }

    Image {
        x: 12
        y: 12
        width: root.height - 24
        height: root.height - 24
        source: Board.assetUrl(root.asset)
        fillMode: Image.PreserveAspectCrop
        mipmap: true
    }

    Column {
        x: root.height + 14
        anchors.verticalCenter: parent.verticalCenter
        width: root.width - x - 18
        spacing: 2

        Text {
            width: parent.width
            text: "ADMIT ONE"
            font.family: Look.typeFont
            font.pixelSize: 11
            color: "#555555"
        }
        Text {
            width: parent.width
            text: root.caption
            font.family: Look.typeFont
            font.pixelSize: 24
            color: "#1d1d1d"
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: "Nº " + (root.sticker ? root.sticker.id.toUpperCase() : "")
            font.family: Look.typeFont
            font.pixelSize: 11
            color: "#7a1c1c"
        }
    }

    Sheen {
        anchors.fill: parent
    }
}
