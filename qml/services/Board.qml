pragma Singleton
// The stickers, as `deskpaper board get` gives them. QML never writes the
// board: the editor sends it to `deskpaper board set`.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // The launcher beside qml/, so it runs without being installed.
    readonly property string bin: Quickshell.env("DESKPAPER_BIN") || Quickshell.shellDir + "/../deskpaper"
    property var stickers: []
    property string dir: ""
    property int version: 0  // bumped when pictures change in place (recut)

    function assetUrl(name) {
        return dir && name ? "file://" + dir + "/assets/" + name + "?v=" + version : "";
    }
    function cutUrl(name) {
        return name ? assetUrl(name.replace(/\.png$/, ".cut.png")) : "";
    }
    function cardUrl(name) {
        return name ? assetUrl(name.replace(/\.png$/, ".card.png")) : "";
    }
    function refresh() {
        getter.running = false;
        getter.running = true;
    }

    Process {
        id: getter
        command: [root.bin, "board", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const board = JSON.parse(text);
                    root.dir = board.root || root.dir;
                    root.stickers = board.stickers || [];
                } catch (e) {
                    root.stickers = [];
                }
            }
        }
    }

    // Edits by hand (or another machine's restore) show up without a restart.
    FileView {
        path: root.dir ? root.dir + "/board.json" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: root.refresh()
    }

    Component.onCompleted: refresh()
}
