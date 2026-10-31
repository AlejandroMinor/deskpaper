// A light band across a sticker: a still gloss, or a rainbow that now and then
// sweeps across (holo). Each sticker gets its own place and timing, so they do
// not shine together.
//   maskItem  layered Item whose alpha clips the band (die-cut silhouette);
//             null = the band covers the whole rectangle
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property Item maskItem: null
    property bool rainbow: false
    property bool animated: false
    property real strength: rainbow ? Look.holoStrength : Look.glossStrength

    readonly property Gradient gloss: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.30; color: "#00ffffff" }
        GradientStop { position: 0.45; color: "#ffffffff" }
        GradientStop { position: 0.55; color: "#00ffffff" }
    }
    readonly property Gradient holo: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.350; color: "#00ff5f9e" }
        GradientStop { position: 0.395; color: "#ffff5f9e" }
        GradientStop { position: 0.440; color: "#ffffd65f" }
        GradientStop { position: 0.485; color: "#ff5fffb0" }
        GradientStop { position: 0.530; color: "#ff5fc8ff" }
        GradientStop { position: 0.575; color: "#ffb45fff" }
        GradientStop { position: 0.620; color: "#ffff5f9e" }
        GradientStop { position: 0.650; color: "#00ff5f9e" }
    }

    Item {
        id: band
        anchors.fill: parent
        clip: true

        Rectangle {
            id: stripe
            width: root.width * 3
            height: Math.max(root.width, root.height) * 3
            y: (root.height - height) / 2
            // Still: somewhere across the sticker. Animated: off it, waiting.
            x: root.animated ? -root.width * 2.4 : -root.width * (0.7 + 0.6 * root.place)
            rotation: 25
            gradient: root.rainbow ? root.holo : root.gloss
        }
    }

    readonly property real place: Math.random()

    NumberAnimation {
        id: sweep
        target: stripe
        property: "x"
        from: -root.width * 2.4  // read at start
        to: root.width * 0.2
        duration: Look.holoSweep
        easing.type: Easing.InOutSine
    }
    Timer {
        // First sweep at a random moment, then a random rest after each one.
        running: root.animated && root.width > 0
        repeat: true
        interval: 500 + root.place * Look.holoRest
        onTriggered: {
            sweep.restart();
            interval = Look.holoSweep + Look.holoRest * (0.4 + Math.random() * 0.8);
        }
    }

    // live: a hidden layer stops updating, and the band moves.
    ShaderEffectSource {
        id: bandTexture
        anchors.fill: parent
        sourceItem: band
        hideSource: true
        live: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: bandTexture
        opacity: root.strength
        maskEnabled: root.maskItem !== null
        maskSource: root.maskItem
    }
}
