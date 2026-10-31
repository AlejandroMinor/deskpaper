import QtQuick

Rectangle {
    id: root

    property string text
    property bool active: false
    property bool danger: false  // red: removes something
    property string tip  // hover label, when the name does not say enough
    property bool enabled: true
    signal clicked

    implicitWidth: label.implicitWidth + 20
    implicitHeight: 30
    radius: 6
    color: danger ? (area.containsMouse ? "#e74c3c" : "#a93226")
        : active ? "#4a4a4a" : area.containsMouse ? "#3a3a3a" : "#2e2e2e"
    border.color: danger ? "#e74c3c" : "#505050"
    opacity: enabled ? 1 : 0.4

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: "#e6e6e6"
        font.pixelSize: 13
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }

    Tip {
        text: root.tip
        shown: area.containsMouse
    }
}
