// Upcoming events on a post-it. Reads `payload` from the events source:
// {items: [{label, title}], error}.
//   props.title  heading, "Upcoming" by default
//   props.curl   lifted corner
import QtQuick
import qs.services

Item {
    id: root

    property var sticker
    property var payload

    readonly property var items: payload && payload.items ? payload.items : []

    implicitWidth: Look.postitSide
    implicitHeight: Look.postitSide

    Paper {
        id: paper
        anchors.fill: parent
        color: Look.postitPaper
        curl: root.sticker && root.sticker.props.curl ? Look.curlSize : 0
        layer.enabled: true
        layer.effect: Shadow { sticker: root.sticker }
    }

    Rectangle {
        // Tape holding it.
        width: 70
        height: 22
        x: (parent.width - width) / 2
        y: -10
        rotation: -4
        color: Look.tape
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        Text {
            text: root.sticker && root.sticker.props.title ? root.sticker.props.title : "Upcoming"
            font.family: Look.handFont
            font.pixelSize: 26
            font.bold: true
            color: Look.postitInk
        }

        Repeater {
            model: root.items

            Text {
                required property var modelData

                width: parent.width
                text: modelData.label + " · " + modelData.title
                elide: Text.ElideRight
                font.family: Look.handFont
                font.pixelSize: 20
                color: Look.postitInk
            }
        }

        Text {
            visible: root.items.length === 0
            text: "Nothing coming up"
            font.family: Look.handFont
            font.pixelSize: 20
            color: Look.postitInk
            opacity: 0.6
        }
    }
}
