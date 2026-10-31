// A letter (or a few) cut from a magazine. `look` is one entry of Look.clippings.
import QtQuick

Item {
    id: root

    property var look

    width: chip.width
    height: chip.height + 8

    Rectangle {
        id: chip
        y: 4 + root.look.lift
        width: glyph.implicitWidth + 10
        height: glyph.implicitHeight + 4
        rotation: root.look.tilt
        color: root.look.paper
        antialiasing: true

        Text {
            id: glyph
            anchors.centerIn: parent
            text: root.look.text
            font.family: root.look.font
            font.pixelSize: root.look.size
            font.bold: root.look.bold
            color: root.look.ink
        }
    }
}
