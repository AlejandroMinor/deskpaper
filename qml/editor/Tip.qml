// A hover label for a control whose icon or name does not say enough.
// Put it inside the control; it shows over it while `shown` (under it with
// `below`, where there is no room above).
import QtQuick

Rectangle {
    id: root

    property string text
    property bool shown: false
    property bool below: false

    visible: shown && text !== ""
    z: 1000
    y: below ? parent.height + 6 : -height - 6
    anchors.horizontalCenter: parent.horizontalCenter
    width: label.implicitWidth + 12
    height: label.implicitHeight + 8
    radius: 4
    color: "#111111"
    border.color: "#505050"

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: "#e6e6e6"
        font.pixelSize: 11
    }
}
