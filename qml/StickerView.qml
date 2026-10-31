// One sticker: picks its skin and feeds it. Used by the desktop and by the
// editor's canvas, so both look the same.
//   sticker  one entry of board.json
//   unit     screen height / 1080, so a sticker keeps its size on any screen
import QtQuick
import qs.services

Item {
    id: root

    property var sticker
    property real unit: 1
    property bool popIn: false  // bounce in when created (desktop only)

    readonly property string skinName: sticker && sticker.skin
        ? sticker.skin.charAt(0).toUpperCase() + sticker.skin.slice(1) : ""
    readonly property bool isData: !!sticker && sticker.kind === "data"

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0
    width: implicitWidth
    height: implicitHeight
    z: sticker && sticker.z || 0
    rotation: sticker && sticker.rotation || 0
    scale: (sticker && sticker.scale || 1) * unit

    Source {
        id: source
        name: root.isData ? root.sticker.props.source : ""
        interval: root.isData && root.sticker.props.interval ? root.sticker.props.interval : 300
    }

    Loader {
        id: loader
        source: root.skinName ? Qt.resolvedUrl("skins/" + root.skinName + ".qml") : ""
        transform: Scale {
            id: pop
            origin.x: loader.width / 2
            origin.y: loader.height / 2
        }
    }

    SequentialAnimation {
        id: popAnim
        PropertyAction { target: loader; property: "opacity"; value: 0 }
        PauseAnimation { duration: Math.random() * 200 }  // not all at once
        ParallelAnimation {
            NumberAnimation { target: loader; property: "opacity"; from: 0; to: 1; duration: Look.popDuration / 2 }
            NumberAnimation { target: pop; property: "xScale"; from: 0.6; to: 1; duration: Look.popDuration; easing.type: Easing.OutBack }
            NumberAnimation { target: pop; property: "yScale"; from: 0.6; to: 1; duration: Look.popDuration; easing.type: Easing.OutBack }
        }
    }

    Component.onCompleted: if (popIn) popAnim.start()

    Binding {
        target: loader.item
        property: "sticker"
        value: root.sticker
        when: loader.item !== null
    }

    Binding {
        target: loader.item
        property: "payload"
        value: source.payload
        when: loader.item !== null && root.isData
    }
}
