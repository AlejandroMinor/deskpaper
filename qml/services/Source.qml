// A data source: runs `deskpaper source NAME` every `interval` seconds and
// exposes its JSON. The skin only reads `payload`; where it comes from is
// Python's business.
import QtQuick
import Quickshell.Io

Item {
    id: root

    property string name: ""
    property int interval: 300
    property var payload: null

    Process {
        id: proc
        command: [Board.bin, "source", root.name]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.payload = JSON.parse(text);
                } catch (e) {
                    root.payload = { items: [], error: String(e) };
                }
            }
        }
    }

    Timer {
        interval: Math.max(10, root.interval) * 1000
        running: root.name !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
