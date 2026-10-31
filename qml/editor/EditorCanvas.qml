// The editor's canvas: the screens as they stand, and the draft's stickers
// drawn with the same StickerView as the desktop.
import QtQuick
import Quickshell
import ".."

Item {
    id: root

    required property var editor

    readonly property var shown: Quickshell.screens.filter(s => !editor.only || s.name === editor.only)
    readonly property var bounds: {
        if (!shown.length)
            return { x: 0, y: 0, w: 1, h: 1 };
        const x = Math.min(...shown.map(s => s.x)), y = Math.min(...shown.map(s => s.y));
        return {
            x: x,
            y: y,
            w: Math.max(...shown.map(s => s.x + s.width)) - x,
            h: Math.max(...shown.map(s => s.y + s.height)) - y
        };
    }
    readonly property real factor: 0.92 * Math.min(width / bounds.w, height / bounds.h)
    readonly property real ox: (width - bounds.w * factor) / 2
    readonly property real oy: (height - bounds.h * factor) / 2

    // A screen's place on the canvas, or null when it is not shown.
    function rectOf(name) {
        const s = shown.find(s => s.name === name);
        if (!s)
            return null;
        return {
            x: ox + (s.x - bounds.x) * factor,
            y: oy + (s.y - bounds.y) * factor,
            w: s.width * factor,
            h: s.height * factor
        };
    }
    // The screen under a canvas point, with the point as fractions of it.
    function screenAt(px, py) {
        for (const s of shown) {
            const r = rectOf(s.name);
            if (px >= r.x && px <= r.x + r.w && py >= r.y && py <= r.y + r.h)
                return { name: s.name, fx: (px - r.x) / r.w, fy: (py - r.y) / r.h };
        }
        return null;
    }

    MouseArea {
        anchors.fill: parent
        onPressed: {
            root.editor.selected = "";
            root.editor.surface.forceActiveFocus();  // Del and [ ] work again
        }
    }

    Repeater {
        model: root.shown

        Rectangle {
            required property var modelData
            readonly property var r: root.rectOf(modelData.name)

            x: r.x
            y: r.y
            width: r.w
            height: r.h
            color: "#2a2d33"
            border.color: "#6a6f78"
            border.width: 1

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: root.editor.wallpapers[parent.modelData.name] ? "file://" + root.editor.wallpapers[parent.modelData.name] : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 800
                asynchronous: true
            }

            Text {
                x: 8
                y: 6
                text: parent.modelData.name
                color: "#9aa0a8"
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    Repeater {
        model: root.editor.draft

        Item {
            id: wrap

            required property var modelData
            readonly property var r: root.rectOf(modelData.monitor)
            readonly property bool selected: root.editor.selected === modelData.id
            // Live changes while a handle is dragged; committed on release.
            property real dScale: 1
            property real dRot: 0

            visible: r !== null && !modelData.missing
            z: modelData.z
            width: view.implicitWidth * view.scale * dScale
            height: view.implicitHeight * view.scale * dScale
            x: r ? r.x + modelData.x * r.w - width / 2 : 0
            y: r ? r.y + modelData.y * r.h - height / 2 : 0

            StickerView {
                id: view
                anchors.centerIn: parent
                sticker: wrap.modelData
                unit: wrap.r ? wrap.r.h / 1080 : 1
                transform: [
                    Scale {
                        origin.x: view.width / 2
                        origin.y: view.height / 2
                        xScale: wrap.dScale
                        yScale: wrap.dScale
                    },
                    Rotation {
                        origin.x: view.width / 2
                        origin.y: view.height / 2
                        angle: wrap.dRot
                    }
                ]
            }

            MouseArea {
                anchors.fill: parent
                property bool moved: false
                drag.target: wrap
                onPressed: {
                    moved = false;
                    root.editor.selected = wrap.modelData.id;
                    root.editor.surface.forceActiveFocus();
                }
                onPositionChanged: moved = true
                onReleased: {
                    if (moved)
                        root.editor.moveTo(wrap.modelData.id, wrap.x + wrap.width / 2, wrap.y + wrap.height / 2);
                }
            }

            // The frame and handles live on the overlay, above every sticker,
            // so a sticker higher in the pile never covers them.
            Item {
                id: handles
                parent: overlay
                visible: wrap.selected && wrap.visible
                x: wrap.x
                y: wrap.y
                width: wrap.width
                height: wrap.height
                rotation: (wrap.modelData.rotation || 0) + wrap.dRot  // follows the sticker

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#4fa3ff"
                    border.width: 2
                }

                // Scale: drag the corner away from or toward the center.
                Rectangle {
                    id: scaler
                    width: 14
                    height: 14
                    radius: 7
                    color: "#4fa3ff"
                    x: parent.width - 7
                    y: parent.height - 7

                    MouseArea {
                        id: scaleArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.SizeFDiagCursor
                        property real d0: 1
                        function dist(mouse) {
                            const p = mapToItem(wrap, mouse.x, mouse.y);
                            return Math.max(1, Math.hypot(p.x - wrap.width / 2, p.y - wrap.height / 2));
                        }
                        onPressed: mouse => d0 = dist(mouse) / wrap.dScale
                        onPositionChanged: mouse => wrap.dScale = Math.max(0.1, dist(mouse) / d0)
                        onReleased: root.editor.commit(wrap.modelData.id, wrap.dScale, 0)
                    }
                    Tip {
                        text: "Drag to resize"
                        shown: scaleArea.containsMouse && !scaleArea.pressed
                        rotation: -handles.rotation  // upright on a turned sticker
                    }
                }

                // Rotate: drag the knob above the sticker around its center.
                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: "#ffb84f"
                    x: parent.width / 2 - 7
                    y: -28

                    MouseArea {
                        id: turnArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.SizeAllCursor
                        property real a0: 0
                        function angle(mouse) {
                            const p = mapToItem(wrap, mouse.x, mouse.y);
                            return Math.atan2(p.y - wrap.height / 2, p.x - wrap.width / 2) * 180 / Math.PI + 90;
                        }
                        onPressed: mouse => a0 = angle(mouse)
                        onPositionChanged: mouse => wrap.dRot = angle(mouse) - a0
                        onReleased: root.editor.commit(wrap.modelData.id, 1, wrap.dRot)
                    }
                    Tip {
                        text: "Drag to turn"
                        shown: turnArea.containsMouse && !turnArea.pressed
                        rotation: -handles.rotation
                    }
                }

                // Remove: the red cross on the top-right corner.
                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: removeArea.containsMouse ? "#e74c3c" : "#c0392b"
                    border.color: "white"
                    border.width: 1.5
                    x: parent.width - 11
                    y: -11

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    MouseArea {
                        id: removeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.editor.remove(wrap.modelData.id)
                    }
                    Tip {
                        text: "Remove (Del)"
                        shown: removeArea.containsMouse
                        rotation: -handles.rotation
                    }
                }
            }
        }
    }

    Item {
        id: overlay
        anchors.fill: parent
        z: 1e6  // over every sticker, whatever its z
    }
}
