// Stickers on every screen, above the wallpaper and below every window.
// No input: they are decoration; only the editor moves them.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "deskpaper"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: area
            anchors.fill: parent

            Repeater {
                model: Board.stickers.filter(s => s.monitor === win.modelData.name && !s.missing)

                StickerView {
                    required property var modelData

                    sticker: modelData
                    unit: area.height / 1080
                    popIn: true
                    x: modelData.x * area.width - width / 2
                    y: modelData.y * area.height - height / 2
                }
            }
        }
    }
}
