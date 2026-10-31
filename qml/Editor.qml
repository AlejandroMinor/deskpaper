// The sticker editor: canvas on the left, resources on the right. Edits a
// draft; Apply sends it to `deskpaper board set`.
//   deskpaper   (or: qs -p qml ipc call editor toggle)
import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import "editor"

FloatingWindow {
    id: win

    property var draft: []
    property var undoStack: []  // earlier drafts, newest last
    property var redoStack: []
    property var assets: []
    property var wallpapers: ({})
    property string selected: ""
    property string only: ""  // one screen, or "" for all of them
    property bool dirty: false
    property bool confirmClose: false
    property string message: ""
    property var dragInfo: null
    readonly property bool dragging: dragInfo !== null
    readonly property Item surface: body  // coordinates of drags from the panel
    readonly property var offScreen: draft.filter(s => s.missing || !Quickshell.screens.some(m => m.name === s.monitor))

    title: "deskpaper"
    implicitWidth: 1280
    implicitHeight: 780
    visible: false
    color: "#1e1e1e"

    function openEditor() {
        draft = JSON.parse(JSON.stringify(Board.stickers));
        undoStack = [];
        redoStack = [];
        dirty = false;
        confirmClose = false;
        selected = "";
        message = "";
        refreshAssets();
        run.start(["wallpapers"], (code, out) => {
            try {
                wallpapers = JSON.parse(out);
            } catch (e) {
                wallpapers = {};
            }
        });
        visible = true;
    }
    function closeEditor() {
        if (dirty && !confirmClose) {
            confirmClose = true;
            message = "Unsaved changes: close again to discard them";
            return;
        }
        visible = false;
    }
    function toggle() {
        if (visible)
            closeEditor();
        else
            openEditor();
    }
    function refreshAssets() {
        assetsRun.start(["assets"], (code, out) => {
            try {
                assets = JSON.parse(out);
            } catch (e) {
                assets = [];
            }
        });
    }

    // Draft edits: every change goes through here (one undo step each) and
    // replaces the array so the canvas redraws.
    function setDraft(next) {
        undoStack = undoStack.concat([draft]).slice(-50);
        redoStack = [];
        draft = next;
        dirty = true;
        confirmClose = false;
    }
    function undo() {
        if (!undoStack.length)
            return;
        redoStack = redoStack.concat([draft]);
        draft = undoStack[undoStack.length - 1];
        undoStack = undoStack.slice(0, -1);
        dirty = true;
    }
    function redo() {
        if (!redoStack.length)
            return;
        undoStack = undoStack.concat([draft]);
        draft = redoStack[redoStack.length - 1];
        redoStack = redoStack.slice(0, -1);
        dirty = true;
    }
    function update(id, changes) {
        setDraft(draft.map(s => s.id === id ? Object.assign({}, s, changes) : s));
    }
    function newId() {
        return "s" + Date.now().toString(36) + Math.floor(Math.random() * 36).toString(36);
    }
    function duplicate(id) {
        const s = draft.find(s => s.id === id);
        if (!s)
            return;
        const copy = JSON.parse(JSON.stringify(s));
        copy.id = newId();
        copy.x = Math.min(1, s.x + 0.03);
        copy.y = Math.min(1, s.y + 0.03);
        copy.z = draft.reduce((m, t) => Math.max(m, t.z), 0) + 1;
        setDraft(draft.concat([copy]));
        selected = copy.id;
    }
    function commit(id, dScale, dRot) {
        const s = draft.find(s => s.id === id);
        if (s)
            update(id, {
                scale: Math.min(20, Math.max(0.05, s.scale * dScale)),
                rotation: Math.round((s.rotation + dRot) * 10) / 10
            });
    }
    function moveTo(id, cx, cy) {
        const hit = canvas.screenAt(cx, cy);
        if (hit)
            update(id, { monitor: hit.name, x: hit.fx, y: hit.fy });
        else
            draft = draft.slice();  // dropped outside every screen: snap back
    }
    function remove(id) {
        setDraft(draft.filter(s => s.id !== id));
        selected = "";
    }
    // Moves a sticker in the pile of its screen: "up" or "down" one place, or
    // to the "front" or "back". Renumbers that pile, so equal z never hides a move.
    function restack(id, where) {
        const s = draft.find(s => s.id === id);
        if (!s)
            return;
        const pile = draft.map((t, i) => ({ t: t, i: i }))
            .filter(e => e.t.monitor === s.monitor)
            .sort((a, b) => a.t.z - b.t.z || a.i - b.i)
            .map(e => e.t.id);
        const from = pile.indexOf(id);
        const to = where === "front" ? pile.length - 1 : where === "back" ? 0
            : Math.max(0, Math.min(pile.length - 1, from + (where === "up" ? 1 : -1)));
        if (to === from)
            return;
        pile.splice(from, 1);
        pile.splice(to, 0, id);
        setDraft(draft.map(t => t.monitor === s.monitor ? Object.assign({}, t, { z: pile.indexOf(t.id) + 1 }) : t));
    }

    // Dragging from the resource panel.
    function dragStart(info, thumb, p) {
        const placed = info.id ? draft.find(s => s.id === info.id) : null;
        ghost.sticker = placed ? Object.assign({}, placed, { missing: false }) : {
            id: "ghost",
            kind: info.kind,
            skin: info.skin,
            scale: 1,
            rotation: 0,
            z: 0,
            props: info.props
        };
        dragInfo = info;
        dragMove(p);
    }
    function dragMove(p) {
        ghost.cx = p.x;
        ghost.cy = p.y;
        // Preview at the size it will have on the screen under the cursor.
        const c = canvas.mapFromItem(body, p.x, p.y);
        const hit = canvas.screenAt(c.x, c.y);
        const r = canvas.rectOf(hit ? hit.name : (canvas.shown.length ? canvas.shown[0].name : ""));
        if (r)
            ghost.unit = r.h / 1080;
    }
    function dragEnd(p) {
        const info = dragInfo;
        dragInfo = null;
        const c = canvas.mapFromItem(body, p.x, p.y);
        const hit = canvas.screenAt(c.x, c.y);
        if (!info || !hit)
            return;
        if (info.id) {  // an off-screen sticker
            update(info.id, { monitor: hit.name, x: hit.fx, y: hit.fy });
            selected = info.id;
            return;
        }
        add(info, hit.name, hit.fx, hit.fy);
    }
    // A new sticker from the panel, on top of the others.
    function add(info, monitor, x, y) {
        const top = draft.reduce((m, s) => Math.max(m, s.z), 0);
        const s = {
            id: newId(),
            kind: info.kind,
            skin: info.skin,
            monitor: monitor,
            x: x,
            y: y,
            scale: 1,
            rotation: 0,
            z: top + 1,
            props: JSON.parse(JSON.stringify(info.props))
        };
        setDraft(draft.concat([s]));
        selected = s.id;
    }
    // Add button: the middle of the screen shown alone, or of the first one.
    function place(info) {
        const name = only || (canvas.shown.length ? canvas.shown[0].name : "");
        if (name)
            add(info, name, 0.5, 0.5);
    }

    function apply() {
        const clean = draft.map(s => {
            const c = Object.assign({}, s);
            delete c.missing;
            return c;
        });
        run.start(["board", "set"], (code, out, err) => {
            if (code === 0) {
                dirty = false;
                message = "Applied";
                Board.refresh();
            } else {
                message = err.trim() || "Apply failed";
            }
        }, JSON.stringify({ version: 1, stickers: clean }));
    }
    function removeAsset(asset) {
        const used = draft.filter(s => s.kind === "image" && s.props.asset === asset).length;
        if (used) {
            message = "That picture is on " + used + " sticker(s): remove them first";
            return;
        }
        run.start(["remove", asset], (code, out, err) => {
            message = code === 0 ? "Picture removed" : err.trim();
            refreshAssets();
        });
    }
    function recutAsset(asset) {
        run.start(["recut", asset], (code, out, err) => {
            if (code !== 0) {
                message = err.trim();
                return;
            }
            let changed = false;
            try {
                changed = JSON.parse(out).changed;
            } catch (e) {}
            message = changed ? "Background removed"
                : "Nothing to remove: only a flat, light background (like white) can go";
            if (changed) {
                Board.version++;
                refreshAssets();
            }
        });
    }
    function importImage(path) {
        run.start(["import", path], (code, out, err) => {
            message = code === 0 ? "Imported" : err.trim();
            refreshAssets();
        });
    }
    function localPath(url) {
        return decodeURIComponent(String(url).replace(/^file:\/\//, ""));
    }

    Run {
        id: run
    }
    Run {
        id: assetsRun
    }

    FileDialog {
        id: exportDialog
        title: "Export stickers"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "tar.gz"
        nameFilters: ["Backup (*.tar.gz)"]
        onAccepted: run.start(["export", win.localPath(selectedFile)], (code, out, err) => {
            win.message = code === 0 ? "Exported to " + out.trim() : err.trim();
        })
    }
    FileDialog {
        id: restoreDialog
        title: "Restore stickers (the current ones are kept aside)"
        nameFilters: ["Backup (*.tar.gz)"]
        onAccepted: run.start(["restore", "--replace", win.localPath(selectedFile)], (code, out, err) => {
            if (code === 0) {
                Board.refresh();
                win.message = "Restored";
                reopen.start();
            } else {
                win.message = err.trim();
            }
        })
    }
    Timer {
        // Board.refresh is async: reload the draft once it has landed.
        id: reopen
        interval: 500
        onTriggered: win.openEditor()
    }

    IpcHandler {
        target: "editor"
        function toggle(): void {
            win.toggle();
        }
        function open(): void {
            if (!win.visible) {
                win.openEditor();
                return;
            }
            // Already open, maybe on another workspace: show it again where
            // you are, keeping the draft.
            win.visible = false;
            Qt.callLater(() => win.visible = true);
        }
    }

    Item {
        id: body
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier, shift = event.modifiers & Qt.ShiftModifier;
            if (event.key === Qt.Key_Escape)
                win.closeEditor();
            else if (ctrl && event.key === Qt.Key_Z && !shift)
                win.undo();
            else if (ctrl && (event.key === Qt.Key_Y || (event.key === Qt.Key_Z && shift)))
                win.redo();
            else if (!win.selected)
                return;
            else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace)
                win.remove(win.selected);
            else if (ctrl && event.key === Qt.Key_D)
                win.duplicate(win.selected);
            else if (event.key === Qt.Key_BracketLeft || event.key === Qt.Key_PageDown)
                win.restack(win.selected, "down");
            else if (event.key === Qt.Key_BracketRight || event.key === Qt.Key_PageUp)
                win.restack(win.selected, "up");
            else if (event.key === Qt.Key_End)
                win.restack(win.selected, "back");
            else if (event.key === Qt.Key_Home)
                win.restack(win.selected, "front");
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                color: "#2a2a2a"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Btn {
                        text: "All"
                        active: win.only === ""
                        onClicked: win.only = ""
                    }
                    Repeater {
                        model: Quickshell.screens
                        Btn {
                            required property var modelData
                            text: modelData.name
                            active: win.only === modelData.name
                            onClicked: win.only = modelData.name
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        text: win.message
                        color: "#d0d0d0"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    Btn {
                        text: "Export…"
                        onClicked: exportDialog.open()
                    }
                    Btn {
                        text: "Restore…"
                        onClicked: restoreDialog.open()
                    }
                    Btn {
                        text: "Apply"
                        enabled: win.dirty
                        onClicked: win.apply()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    EditorCanvas {
                        id: canvas
                        editor: win
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                    }
                    SelectionBar {
                        editor: win
                        Layout.fillWidth: true
                    }
                }
                ResourcePanel {
                    editor: win
                    Layout.preferredWidth: 420
                    Layout.fillHeight: true
                }
            }
        }

        // What will land where you drop it: the real skin at the real size.
        StickerView {
            id: ghost
            property real cx: 0
            property real cy: 0
            visible: win.dragging
            opacity: 0.85
            z: 100
            x: cx - width / 2
            y: cy - height / 2
        }
    }
}
