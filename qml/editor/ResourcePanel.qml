// Right side of the editor: what can be dragged onto the canvas.
// Stickers (imported pictures), Widgets (data stickers), Off screen (stickers
// whose screen is missing). Click a sticker or widget to set it up below the
// preview before placing it: dragging it, or Add, then uses those settings.
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.services
import ".."

Rectangle {
    id: root

    required property var editor
    property string tab: "stickers"
    property string skin: "diecut"
    property bool browsing: false
    property url folder: "file://" + Quickshell.env("HOME") + "/Pictures"
    property var preview: null  // info of the tile under the mouse
    property var template: null  // the clicked tile, being set up: {id, kind, skin, props}
    property string picked: ""  // key of that tile
    property int picks: 0

    function pick(info, key) {
        picks += 1;
        template = {
            id: "new-" + picks,  // a new id resets the text field
            kind: info.kind,
            skin: info.kind === "image" ? skin : info.skin,
            scale: 1,
            rotation: 0,
            z: 0,
            props: Object.assign(JSON.parse(JSON.stringify(info.props)),
                                 { seed: Math.random().toString(36).slice(2, 8) })  // cut-out letters
        };
        picked = key;
    }
    // What to place: the template without its id (an id means a placed sticker).
    function newSticker() {
        return { kind: template.kind, skin: template.skin, props: template.props };
    }
    function editTemplate(changes) {
        template = Object.assign({}, template, changes);
        if (changes.skin && template.kind === "image")
            skin = changes.skin;  // the next picture starts with it
    }
    onTabChanged: {
        template = null;
        picked = "";
    }

    // The picked tile, set up; else the one under the mouse.
    readonly property var previewSticker: {
        if (template)
            return template;
        if (!preview)
            return null;
        if (preview.id)
            return editor.draft.find(s => s.id === preview.id) || null;
        return {
            id: "preview",
            kind: preview.kind,
            skin: preview.kind === "image" ? skin : preview.skin,
            scale: 1,
            rotation: 0,
            z: 0,
            props: preview.props
        };
    }

    readonly property var widgets: [
        { label: "Post-it · events", kind: "data", skin: "postit", props: { source: "events" } },
        { label: "Calendar", kind: "data", skin: "calendar", props: { source: "month", interval: 600 } },
        { label: "Clock · analog", kind: "widget", skin: "clock", props: { style: "analog" } },
        { label: "Clock · label", kind: "widget", skin: "clock", props: { style: "label" } },
        { label: "Clock · ransom", kind: "widget", skin: "clock", props: { style: "ransom" } },
        { label: "Clock · marker", kind: "widget", skin: "clock", props: { style: "marker" } },
        { label: "Washi tape", kind: "widget", skin: "tape", props: { pattern: "stripes" } },
        { label: "Ransom note", kind: "text", skin: "ransom", props: { text: "HELLO THERE" } }
    ]

    color: "#262626"

    // Drag from a tile: the editor draws the ghost and drops it on the canvas.
    component Tile: Rectangle {
        id: tile

        property var info
        property string key  // "" = cannot be set up (off-screen stickers)
        readonly property bool isPicked: key !== "" && key === root.picked
        property url thumb
        property var sample: null  // a sticker drawn live, for tiles without a picture
        property string label
        property bool removable: false
        signal removeRequested
        signal recutRequested

        width: 120
        height: 110
        radius: 6
        color: tileArea.containsMouse ? "#3a3a3a" : "#303030"
        border.color: isPicked ? "#4fa3ff" : "transparent"
        border.width: 2

        Item {
            id: thumbArea
            anchors.fill: parent
            anchors.margins: 8
            anchors.bottomMargin: tile.label ? 26 : 8

            Image {
                anchors.fill: parent
                source: tile.thumb
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 200
                mipmap: true
            }
            StickerView {
                anchors.centerIn: parent
                sticker: tile.sample
                unit: implicitWidth > 0
                    ? Math.min(1, thumbArea.width / implicitWidth, thumbArea.height / implicitHeight) : 1
            }
        }
        Text {
            visible: tile.label !== ""
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            width: parent.width - 8
            x: 4
            text: tile.label
            color: "#cfcfcf"
            font.pixelSize: 11
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            onContainsMouseChanged: if (containsMouse) root.preview = tile.info
            onPressed: mouse => root.editor.dragStart(tile.isPicked ? root.newSticker() : tile.info, tile.thumb, mapToItem(root.editor.surface, mouse.x, mouse.y))
            onClicked: if (tile.key !== "") root.pick(tile.info, tile.key)
            onPositionChanged: mouse => root.editor.dragMove(mapToItem(root.editor.surface, mouse.x, mouse.y))
            onReleased: mouse => root.editor.dragEnd(mapToItem(root.editor.surface, mouse.x, mouse.y))
        }
        Rectangle {
            // Scissors: make a flat background transparent.
            visible: tile.removable && (tileArea.containsMouse || recutArea.containsMouse || closeArea.containsMouse)
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 4
            width: 22
            height: 22
            radius: 11
            color: recutArea.containsMouse ? "#2d7dd2" : "#000000aa"

            Text {
                anchors.centerIn: parent
                text: "✂"
                color: "white"
                font.pixelSize: 13
            }
            MouseArea {
                id: recutArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: tile.recutRequested()
            }
            Tip {
                text: "Remove a flat, light background"
                shown: recutArea.containsMouse
                below: true
            }
        }
        Rectangle {
            visible: tile.removable && (tileArea.containsMouse || recutArea.containsMouse || closeArea.containsMouse)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            width: 22
            height: 22
            radius: 11
            color: closeArea.containsMouse ? "#c0392b" : "#000000aa"

            Text {
                anchors.centerIn: parent
                text: "×"
                color: "white"
                font.pixelSize: 15
            }
            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: tile.removeRequested()
            }
            Tip {
                text: "Delete picture"
                shown: closeArea.containsMouse
                below: true
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Btn { text: "Stickers"; active: root.tab === "stickers"; onClicked: root.tab = "stickers" }
            Btn { text: "Widgets"; active: root.tab === "widgets"; onClicked: root.tab = "widgets" }
            Btn {
                text: "Off screen (" + root.editor.offScreen.length + ")"
                active: root.tab === "offscreen"
                onClicked: root.tab = "offscreen"
            }
            Item { Layout.fillWidth: true }
            Btn {
                visible: root.tab === "stickers"
                text: root.browsing ? "Done" : "+ Image…"
                active: root.browsing
                onClicked: root.browsing = !root.browsing
            }
        }

        // Picture browser: click a folder to enter it, a picture to import it.
        RowLayout {
            visible: root.tab === "stickers" && root.browsing
            spacing: 4
            Btn {
                text: "Up"
                onClicked: root.folder = files.parentFolder
            }
            Text {
                Layout.fillWidth: true
                text: decodeURIComponent(String(root.folder).replace(/^file:\/\//, ""))
                color: "#9a9a9a"
                font.pixelSize: 11
                elide: Text.ElideLeft
            }
        }

        FolderListModel {
            id: files
            folder: root.folder
            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif"]
            caseSensitive: false
            showDirsFirst: true
            showDotAndDotDot: false
            showHidden: false
        }

        GridView {
            id: browser
            visible: root.tab === "stickers" && root.browsing
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 3
            cellHeight: cellWidth
            model: files

            delegate: Rectangle {
                required property string fileName
                required property url fileUrl
                required property bool fileIsDir

                width: browser.cellWidth - 6
                height: browser.cellHeight - 6
                radius: 6
                color: pick.containsMouse ? "#3a3a3a" : "#303030"

                Image {
                    visible: !parent.fileIsDir
                    anchors.fill: parent
                    anchors.margins: 6
                    anchors.bottomMargin: 22
                    source: parent.fileIsDir ? "" : parent.fileUrl
                    sourceSize.width: 220
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                Text {
                    visible: parent.fileIsDir
                    anchors.centerIn: parent
                    text: "▸"
                    color: "#8a8a8a"
                    font.pixelSize: 28
                }
                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    x: 4
                    width: parent.width - 8
                    text: parent.fileName
                    color: "#cfcfcf"
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                }
                MouseArea {
                    id: pick
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (parent.fileIsDir) {
                            root.folder = parent.fileUrl;
                        } else {
                            root.editor.importImage(decodeURIComponent(String(parent.fileUrl).replace(/^file:\/\//, "")));
                            root.browsing = false;
                        }
                    }
                }
            }
        }

        Flickable {
            visible: !(root.tab === "stickers" && root.browsing)
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: grid.height
            interactive: !root.editor.dragging

            Flow {
                id: grid
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.tab === "stickers" ? root.editor.assets : []
                    Tile {
                        required property var modelData
                        thumb: Board.assetUrl(modelData.asset)
                        info: ({ kind: "image", skin: root.skin, props: { asset: modelData.asset } })
                        key: modelData.asset
                        removable: true
                        onRemoveRequested: root.editor.removeAsset(modelData.asset)
                        onRecutRequested: root.editor.recutAsset(modelData.asset)
                    }
                }
                Repeater {
                    model: root.tab === "widgets" ? root.widgets : []
                    Tile {
                        required property var modelData
                        label: modelData.label
                        key: modelData.label
                        sample: ({ id: "sample", kind: modelData.kind, skin: modelData.skin, scale: 1, rotation: 0, z: 0, props: modelData.props })
                        info: modelData
                    }
                }
                Repeater {
                    model: root.tab === "offscreen" ? root.editor.offScreen : []
                    Tile {
                        required property var modelData
                        label: modelData.missing ? "missing: " + modelData.props.asset : modelData.monitor
                        thumb: modelData.kind === "image" ? Board.assetUrl(modelData.props.asset) : ""
                        sample: modelData.kind === "image" ? null : Object.assign({}, modelData, { rotation: 0, scale: 1 })
                        info: ({ id: modelData.id })
                    }
                }
            }
        }

        Rectangle {
            id: previewBox
            Layout.fillWidth: true
            Layout.preferredHeight: root.template ? 190 : 240
            radius: 6
            color: "#1b1b1b"
            border.color: root.template ? "#4fa3ff" : "transparent"

            StickerView {
                id: previewView
                anchors.centerIn: parent
                sticker: root.previewSticker ? Object.assign({}, root.previewSticker, { rotation: 0, scale: 1 }) : null
                unit: implicitWidth > 0
                    ? Math.min(1, previewBox.width * 0.85 / implicitWidth, previewBox.height * 0.85 / implicitHeight) : 1
            }
            Text {
                visible: !root.previewSticker
                anchors.centerIn: parent
                text: "Click a sticker to set it up before placing it"
                color: "#6a6a6a"
                font.pixelSize: 12
            }
            MouseArea {
                // The set-up sticker can be dragged from here too.
                anchors.fill: parent
                enabled: root.template !== null
                preventStealing: true
                cursorShape: enabled ? Qt.OpenHandCursor : Qt.ArrowCursor
                onPressed: mouse => root.editor.dragStart(root.newSticker(), "", mapToItem(root.editor.surface, mouse.x, mouse.y))
                onPositionChanged: mouse => root.editor.dragMove(mapToItem(root.editor.surface, mouse.x, mouse.y))
                onReleased: mouse => root.editor.dragEnd(mapToItem(root.editor.surface, mouse.x, mouse.y))
            }
            Btn {
                visible: root.template !== null
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                text: "Add"
                tip: "Place it in the middle of the screen"
                onClicked: root.editor.place(root.newSticker())
            }
        }

        StickerControls {
            Layout.fillWidth: true
            sticker: root.template
            focusBack: root.editor.surface
            onEdited: changes => root.editTemplate(changes)
        }

        Text {
            Layout.fillWidth: true
            text: "Click a sticker to set it up, then drag it onto a screen or press Add · On the canvas: drag to move · Corner: size · Knob: turn · Del: remove · [ ] or PgDn/PgUp: down/up · End/Home: back/front · Ctrl+D: duplicate · Ctrl+Z / Ctrl+Shift+Z: undo / redo"
            color: "#8a8a8a"
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }
}
