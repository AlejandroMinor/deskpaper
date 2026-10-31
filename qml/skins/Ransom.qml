// A ransom note: every letter cut from a different magazine.
//   props.text  the message (kind "text")
// The look of each letter is seeded (Look.clippingSeed), so it stays put. Lines
// break between words, never inside one.
import QtQuick
import qs.services

Item {
    id: root

    property var sticker
    property var payload

    readonly property string message: sticker && sticker.props.text ? sticker.props.text : ""
    // One look per letter, then grouped back into words.
    readonly property var words: {
        const split = message.split(/\s+/).filter(w => w).map(w => Array.from(w));
        const looks = Look.clippings([].concat(...split), Look.clippingSeed(sticker), 26);
        let i = 0;
        return split.map(w => looks.slice(i, i += w.length));
    }

    implicitWidth: Math.min(Look.ransomWidth, flow.implicitWidth)
    implicitHeight: flow.implicitHeight
    layer.enabled: true
    layer.effect: Shadow { sticker: root.sticker }

    Flow {
        id: flow
        width: Look.ransomWidth
        spacing: 4  // between lines; words get their own gap

        Repeater {
            model: root.words

            Row {
                id: word
                required property var modelData
                spacing: 3
                rightPadding: 14

                Repeater {
                    model: word.modelData
                    Clipping {
                        required property var modelData
                        look: modelData
                    }
                }
            }
        }
    }
}
