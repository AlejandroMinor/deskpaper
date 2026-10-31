// A sticker's controls, in groups: Skin · Caption/Title/Text · Look (the
// skin's own options) · Effects · Arrange. Used for the selected sticker (under
// the canvas) and for a new one before it is placed (in the panel).
//   sticker   {id, kind, skin, props}
//   arrange   show Arrange (placed stickers only)
//   focusBack  takes the keyboard back when the text is done (Esc, Return)
//   edited(changes)  {skin} or {props}: the caller applies them
import QtQuick
import qs.services

Flow {
    id: root

    property var sticker: null
    property bool arrange: false
    property Item focusBack: null
    signal edited(var changes)
    signal restack(string where)
    signal duplicate
    signal remove

    readonly property bool isImage: !!sticker && sticker.kind === "image"
    readonly property string textProp: textKey(sticker)
    readonly property var looks: sticker && Look.skinOptions[sticker.skin] || ({})
    // One corner button: paper skins curl, die-cuts peel.
    readonly property string cornerProp: !sticker ? ""
        : Look.curlSkins.includes(sticker.skin) ? "curl"
        : Look.peelSkins.includes(sticker.skin) ? "peel" : ""

    // Which prop holds the text, by skin: none for a plain die-cut.
    function textKey(s) {
        return !s ? "" : s.kind === "text" ? "text"
            : s.skin === "postit" ? "title"
            : Look.captionSkins.includes(s.skin) ? "caption" : "";
    }
    function setProp(key, value) {
        const props = Object.assign({}, sticker.props);
        if (value || key === "text")  // a text sticker keeps its (empty) text
            props[key] = value;
        else
            delete props[key];
        edited({ props: props });
    }

    // Load the text once per sticker: rebinding while typing moves the cursor.
    // textKey, not textProp: that binding may not have caught up yet.
    onStickerChanged: {
        if (sticker && field.sid !== sticker.id) {
            const key = textKey(sticker);
            field.sid = sticker.id;
            field.text = key && sticker.props[key] ? sticker.props[key] : "";
        } else if (!sticker) {
            field.sid = "";
        }
    }

    spacing: 22
    visible: sticker !== null

    // A titled column of controls.
    component Group: Column {
        property string title
        default property alias content: body.data
        spacing: 5

        Text {
            text: parent.title.toUpperCase()
            color: "#7a7a7a"
            font.pixelSize: 10
            font.letterSpacing: 1
        }
        Column {
            id: body
            spacing: 4
        }
    }

    // One option: its name, then its choices (words, or swatches for colors).
    component Choice: Row {
        id: choice
        property string key
        property var choices: []
        readonly property string current: !root.sticker ? ""
            : root.sticker.props[key] || Look.optionDefaults[key] || choices[0]
        spacing: 3

        Text {
            width: 58
            height: 28
            verticalAlignment: Text.AlignVCenter
            text: choice.key
            color: "#9a9a9a"
            font.pixelSize: 12
        }
        Repeater {
            model: choice.choices

            Rectangle {
                required property string modelData
                readonly property bool isColor: choice.key === "color"
                readonly property bool chosen: choice.current === modelData

                y: isColor ? 3 : 0
                width: isColor ? 22 : word.implicitWidth + 14
                height: isColor ? 22 : 28
                radius: isColor ? 11 : 5
                color: isColor ? modelData : chosen ? "#4a4a4a" : "#2e2e2e"
                border.color: chosen ? "#4fa3ff" : "#505050"
                border.width: chosen ? 2 : 1

                Text {
                    id: word
                    visible: !parent.isColor
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: "#e6e6e6"
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.setProp(choice.key, parent.modelData)
                }
            }
        }
    }

    Group {
        visible: root.isImage
        title: "Skin"

        Flow {
            width: Math.min(root.width, 330)
            spacing: 3
            Repeater {
                model: root.isImage ? Look.imageSkins : []
                Btn {
                    required property string modelData
                    text: modelData
                    active: root.sticker.skin === modelData
                    onClicked: root.edited({ skin: modelData })
                }
            }
        }
    }

    Group {
        visible: root.textProp !== ""
        title: root.textProp

        Rectangle {
            width: Math.min(root.width, 240)
            height: 30
            radius: 6
            color: "#1b1b1b"
            border.color: field.activeFocus ? "#4fa3ff" : "#505050"

            TextInput {
                id: field
                property string sid: ""
                anchors.fill: parent
                anchors.margins: 7
                color: "#e6e6e6"
                font.pixelSize: 13
                clip: true
                maximumLength: 40
                onTextEdited: root.setProp(root.textProp, text)
                Keys.onEscapePressed: if (root.focusBack) root.focusBack.forceActiveFocus()
                Keys.onReturnPressed: if (root.focusBack) root.focusBack.forceActiveFocus()
            }
        }
    }

    Group {
        visible: Object.keys(root.looks).length > 0
        title: "Look"

        Repeater {
            model: Object.keys(root.looks)
            Choice {
                required property string modelData
                key: modelData
                choices: root.looks[modelData]
            }
        }
    }

    Group {
        title: "Effects"

        Repeater {
            model: Object.keys(Look.stickerOptions)
            Choice {
                required property string modelData
                key: modelData
                choices: Look.stickerOptions[modelData]
            }
        }
        Btn {
            visible: root.cornerProp !== ""
            text: "Corner"
            tip: root.cornerProp === "peel" ? "Peel the corner back" : "Lift the corner"
            active: root.cornerProp !== "" && !!root.sticker.props[root.cornerProp]
            onClicked: root.setProp(root.cornerProp, !root.sticker.props[root.cornerProp])
        }
    }

    Group {
        visible: root.arrange
        title: "Arrange"

        Row {
            spacing: 3
            Btn { text: "Back"; tip: "Behind every other sticker (End)"; onClicked: root.restack("back") }
            Btn { text: "Down"; tip: "One place down ([)"; onClicked: root.restack("down") }
            Btn { text: "Up"; tip: "One place up (])"; onClicked: root.restack("up") }
            Btn { text: "Front"; tip: "In front of every other sticker (Home)"; onClicked: root.restack("front") }
        }
        Row {
            spacing: 3
            Btn { text: "Duplicate"; tip: "Ctrl+D"; onClicked: root.duplicate() }
            Btn { text: "Remove"; danger: true; tip: "Del"; onClicked: root.remove() }
        }
    }
}
