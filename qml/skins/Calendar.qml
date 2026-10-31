// This month on a torn sheet of paper. Reads `payload` from the month source:
// {title, days, weeks: [[day|null]], today, marked: [day]}.
import QtQuick
import qs.services

Item {
    id: root

    property var sticker
    property var payload

    readonly property var weeks: payload && payload.weeks ? payload.weeks : []

    implicitWidth: Look.calendarWidth
    implicitHeight: body.height + 44
    layer.enabled: true
    layer.effect: Shadow { sticker: root.sticker }

    // Paper with a torn top edge (fixed seed so it does not jump on reload).
    Canvas {
        id: paper
        anchors.fill: parent
        layer.enabled: true
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d"), w = width, h = height;
            let seed = 7;
            const rnd = () => (seed = (seed * 9301 + 49297) % 233280) / 233280;
            ctx.reset();
            ctx.fillStyle = Look.calendarPaper;
            ctx.beginPath();
            ctx.moveTo(0, h);
            ctx.lineTo(0, 8);
            for (let x = 0; x <= w; x += 7)
                ctx.lineTo(x, 2 + rnd() * 10);
            ctx.lineTo(w, h);
            ctx.closePath();
            ctx.fill();
        }
    }

    Column {
        id: body
        x: 18
        y: 24
        width: root.width - 36
        spacing: 6

        Text {
            text: root.payload ? root.payload.title.toUpperCase() : ""
            font.family: Look.typeFont
            font.pixelSize: 17
            color: "#222222"
        }

        Grid {
            columns: 7
            columnSpacing: 0
            rowSpacing: 3

            Repeater {
                model: root.payload ? root.payload.days : []
                Text {
                    required property string modelData
                    width: body.width / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: Look.typeFont
                    font.pixelSize: 11
                    color: "#7a1c1c"
                }
            }

            Repeater {
                model: [].concat(...root.weeks)
                Item {
                    required property var modelData
                    readonly property bool isToday: !!root.payload && modelData === root.payload.today
                    readonly property bool marked: !!root.payload && modelData !== null && root.payload.marked.includes(modelData)

                    width: body.width / 7
                    height: 22

                    Rectangle {
                        visible: parent.isToday
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        radius: 11
                        color: Look.calendarToday
                    }
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData === null ? "" : parent.modelData
                        font.family: Look.typeFont
                        font.pixelSize: 13
                        color: parent.isToday ? "white" : "#333333"
                    }
                    Rectangle {
                        visible: parent.marked && !parent.isToday
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 4
                        height: 4
                        radius: 2
                        color: Look.calendarToday
                    }
                }
            }
        }
    }

    Sheen {
        anchors.fill: parent
    }
}
