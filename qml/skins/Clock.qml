// A clock (kind "widget": it needs no data).
//   props.style  "analog": hands on a paper disc (default)
//                otherwise the time, 24 h, in a lettering:
//                "label"      punched on a label-maker strip ("digital" too)
//                "ransom"     cut from magazines, like the ransom note
//                "marker"     written with a marker
//                "typewriter" typed
import QtQuick
import qs.services

Item {
    id: root

    property var sticker
    property var payload
    property date now: new Date()
    readonly property string style: sticker && sticker.props.style ? sticker.props.style : "analog"
    readonly property bool analog: style === "analog"
    readonly property string digits: Qt.formatTime(now, "HH:mm")

    implicitWidth: analog ? Look.clockSide : lettering.implicitWidth
    implicitHeight: analog ? Look.clockSide : lettering.implicitHeight
    layer.enabled: true
    layer.effect: Shadow { sticker: root.sticker }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Item {
        visible: root.analog
        anchors.fill: parent

        Canvas {
            anchors.fill: parent
            onVisibleChanged: if (visible) requestPaint()
            onPaint: {
                const ctx = getContext("2d"), c = width / 2;
                ctx.reset();
                ctx.fillStyle = Look.clockPaper;
                ctx.beginPath();
                ctx.arc(c, c, c - 1, 0, 2 * Math.PI);
                ctx.fill();
                ctx.strokeStyle = Look.postitInk;
                ctx.lineWidth = 3;
                ctx.beginPath();
                ctx.arc(c, c, c - 6, 0, 2 * Math.PI);
                ctx.stroke();
                ctx.lineCap = "round";
                for (let i = 0; i < 60; i++) {
                    const a = i * Math.PI / 30, long = i % 5 === 0;
                    ctx.lineWidth = long ? 3 : 1;
                    ctx.beginPath();
                    ctx.moveTo(c + Math.sin(a) * (c - 12), c - Math.cos(a) * (c - 12));
                    ctx.lineTo(c + Math.sin(a) * (c - (long ? 22 : 16)), c - Math.cos(a) * (c - (long ? 22 : 16)));
                    ctx.stroke();
                }
            }
        }

        Repeater {
            model: [12, 3, 6, 9]
            Text {
                required property int modelData
                readonly property real a: modelData * Math.PI / 6
                x: root.width / 2 + Math.sin(a) * (root.width / 2 - 36) - width / 2
                y: root.height / 2 - Math.cos(a) * (root.height / 2 - 36) - height / 2
                text: modelData
                font.family: Look.typeFont
                font.pixelSize: 18
                color: Look.postitInk
            }
        }

        // A hand pivots on its base, which sits on the center.
        component Hand: Rectangle {
            property real angle
            property real length
            x: root.width / 2 - width / 2
            y: root.height / 2 - length
            height: length
            radius: width / 2
            color: Look.postitInk
            antialiasing: true
            transformOrigin: Item.Bottom
            rotation: angle
        }

        Hand {
            width: 6
            length: root.width * 0.24
            angle: (root.now.getHours() % 12 + root.now.getMinutes() / 60) * 30
        }
        Hand {
            width: 4
            length: root.width * 0.34
            angle: (root.now.getMinutes() + root.now.getSeconds() / 60) * 6
        }
        Hand {
            width: 2
            length: root.width * 0.38
            angle: root.now.getSeconds() * 6
            color: Look.calendarToday
        }
        Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 12
            radius: 6
            color: Look.postitInk
        }
    }

    Loader {
        id: lettering
        active: !root.analog
        sourceComponent: root.style === "ransom" ? ransom
            : root.style === "marker" || root.style === "typewriter" ? written : label
    }

    Component {
        id: label

        Rectangle {
            // Wide enough for any time, so the strip does not change size.
            implicitWidth: widest.width + 2 * Look.labelPad
            implicitHeight: widest.height + Look.labelPad
            radius: 4
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(Look.labelTape, 1.25) }
                GradientStop { position: 0.5; color: Look.labelTape }
                GradientStop { position: 1; color: Qt.darker(Look.labelTape, 1.2) }
            }

            TextMetrics {
                id: widest
                font: time.font
                text: "00:00"
            }
            Text {
                id: time
                anchors.centerIn: parent
                text: root.digits
                font.family: "monospace"
                font.bold: true
                font.pixelSize: Look.labelText
                font.letterSpacing: 4
                color: Look.labelInk
                style: Text.Raised  // embossed, as the label maker presses it
                styleColor: "#66000000"
            }
        }
    }

    Component {
        id: ransom

        // Each place keeps its paper and font as the digits change.
        Row {
            spacing: 3

            Repeater {
                model: Look.clippings(Array.from(root.digits), Look.clippingSeed(root.sticker), Look.clockClippingText)
                Clipping {
                    required property var modelData
                    look: modelData
                }
            }
        }
    }

    Component {
        id: written

        Item {
            implicitWidth: widest.width
            implicitHeight: time.implicitHeight

            TextMetrics {
                id: widest
                font: time.font
                text: "00:00"
            }
            Text {
                id: time
                anchors.centerIn: parent
                text: root.digits
                font.family: root.style === "marker" ? Look.markerFont : Look.typeFont
                font.pixelSize: Look.clockText
                color: Look.clockInk
            }
        }
    }
}
