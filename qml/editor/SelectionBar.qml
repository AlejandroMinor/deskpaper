// Under the canvas: the controls of the selected sticker.
import QtQuick

Rectangle {
    id: root

    required property var editor

    readonly property var sticker: editor.draft.find(s => s.id === editor.selected) || null

    implicitHeight: sticker ? controls.implicitHeight + 20 : 46
    color: "#2a2a2a"

    StickerControls {
        id: controls
        x: 10
        y: 10
        width: parent.width - 20
        sticker: root.sticker
        arrange: true
        focusBack: root.editor.surface
        onEdited: changes => root.editor.update(root.sticker.id, changes)
        onRestack: where => root.editor.restack(root.sticker.id, where)
        onDuplicate: root.editor.duplicate(root.sticker.id)
        onRemove: root.editor.remove(root.sticker.id)
    }

    Text {
        visible: root.sticker === null
        anchors.centerIn: parent
        text: "Click a sticker to change it"
        color: "#6a6a6a"
        font.pixelSize: 12
    }
}
