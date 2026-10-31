// Runs one deskpaper command and calls back with (code, stdout, stderr).
//   start(args, done[, input])  input goes to stdin, then stdin is closed
import Quickshell.Io
import qs.services

Process {
    id: proc

    property var done: null
    property var input: null
    property int pending: 0
    property int code: 0

    function start(args, cb, stdinText) {
        command = [Board.bin].concat(args);
        done = cb;
        input = stdinText === undefined ? null : stdinText;
        stdinEnabled = input !== null;
        pending = 3;
        running = true;
    }
    function finish() {
        if (--pending === 0 && done)
            done(code, out.text, err.text);
    }

    onStarted: {
        if (input !== null) {
            write(input);
            stdinEnabled = false;  // closes stdin: the command reads to EOF
        }
    }
    onExited: exitCode => {
        code = exitCode;
        finish();
    }
    stdout: StdioCollector {
        id: out
        onStreamFinished: proc.finish()
    }
    stderr: StdioCollector {
        id: err
        onStreamFinished: proc.finish()
    }
}
