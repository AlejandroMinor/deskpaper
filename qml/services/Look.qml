pragma Singleton
// Every visual value of the skins, in one place.
// PROVISIONAL: none of these has been approved yet.
import QtQuick
import Quickshell

Singleton {
    readonly property real imageSide: 260      // long side of a picture at scale 1
    readonly property real shadowOpacity: 0.35
    readonly property real shadowBlur: 0.5
    readonly property real shadowOffset: 5
    readonly property var shadowLevels: ({ none: 0, soft: 0.5, normal: 1, strong: 1.8 })
    readonly property real cutBorder: 12        // die-cut border in the asset, px (assets.BORDER)
    readonly property var backings: ({ black: "#111111", white: "#ffffff" })

    readonly property color stampPaper: "#fbf7ee"
    readonly property real stampMargin: 14
    readonly property real stampHole: 4         // perforation radius
    readonly property real stampStep: 12        // distance between holes

    readonly property color polaroidPaper: "#fdfdfb"
    readonly property real polaroidSide: 12
    readonly property real polaroidBottom: 52
    readonly property real polaroidPhoto: 240

    readonly property color postitPaper: "#fff27a"
    readonly property color postitInk: "#2b2b2b"
    readonly property color tape: "#ccffffff"
    readonly property real postitSide: 230

    readonly property real glossStrength: 0.18
    readonly property real holoStrength: 0.38
    readonly property int holoSweep: 10000      // ms the rainbow takes to cross
    readonly property int holoRest: 10000       // ms between sweeps, on average
    readonly property real curlSize: 34         // lifted corner, paper skins
    readonly property real peelRatio: 0.32      // peeled corner of die-cuts, of the short side

    readonly property color ticketPaper: "#f1ead8"
    readonly property real ticketWidth: 320
    readonly property real ticketHeight: 120
    readonly property real ticketNotch: 11

    readonly property color calendarPaper: "#f4efe3"
    readonly property color calendarToday: "#e4572e"
    readonly property real calendarWidth: 250

    readonly property color newsPaper: "#ece6d6"
    readonly property color newsInk: "#1e1e1e"
    readonly property real newsWidth: 300

    readonly property real ransomWidth: 380

    readonly property real clockSide: 190
    readonly property color clockPaper: "#f4efe3"
    readonly property color labelTape: "#c62f2f"   // digital clock: label-maker strip
    readonly property color labelInk: "#f6f1ea"
    readonly property real labelText: 54
    readonly property real labelPad: 22
    readonly property real clockClippingText: 40  // smallest cut-out digit
    readonly property real clockText: 72          // marker and typewriter time
    readonly property color clockInk: "#f4efe3"
    readonly property real tapeLength: 220
    readonly property real tapeWidth: 40
    readonly property var tapeColors: ["#f28aa6", "#7fc8f8", "#f6d55c", "#8bd3a0", "#c3a6ff", "#1d1d1d"]

    // Options in the editor: prop → choices. Every sticker has stickerOptions;
    // skinOptions are a skin's own. The first choice, or optionDefaults, is
    // what a sticker without the prop shows.
    readonly property var stickerOptions: ({ shadow: ["none", "soft", "normal", "strong"] })
    readonly property var backing: ["none", "black", "white"]  // color behind a picture
    readonly property var outline: ["white", "black", "none"]  // die-cut border
    readonly property var skinOptions: ({
        tape: { pattern: ["stripes", "dots", "grid", "plain"], color: tapeColors },
        clock: { style: ["analog", "label", "ransom", "marker", "typewriter"] },
        diecut: { outline: outline, backing: backing },
        holo: { outline: outline, backing: backing },
        stamp: { backing: backing },
        polaroid: { backing: backing },
        ticket: { backing: backing },
        news: { backing: backing }
    })
    readonly property var optionDefaults: ({ shadow: "normal" })

    readonly property int popDuration: 420      // entrance on the desktop

    // Skins by what they take: a picture, a text prop, a lifted corner.
    readonly property var imageSkins: ["diecut", "holo", "stamp", "polaroid", "ticket", "news"]
    readonly property var captionSkins: ["stamp", "polaroid", "ticket", "news"]
    readonly property var curlSkins: ["polaroid", "postit"]
    readonly property var peelSkins: ["diecut", "holo"]

    // Bundled fonts (licenses next to them in fonts/).
    readonly property FontLoader marker: FontLoader { source: Qt.resolvedUrl("../fonts/PermanentMarker-Regular.ttf") }
    readonly property FontLoader hand: FontLoader { source: Qt.resolvedUrl("../fonts/Caveat.ttf") }
    readonly property FontLoader blackletter: FontLoader { source: Qt.resolvedUrl("../fonts/UnifrakturMaguntia.ttf") }
    readonly property FontLoader typewriter: FontLoader { source: Qt.resolvedUrl("../fonts/SpecialElite-Regular.ttf") }
    readonly property string markerFont: marker.name || "sans-serif"   // polaroid
    readonly property string handFont: hand.name || "sans-serif"       // post-it
    readonly property string newsMastFont: blackletter.name || "serif"  // newspaper masthead
    readonly property string newsFont: "Liberation Serif"                // newspaper text
    readonly property string typeFont: typewriter.name || "monospace"  // stamp

    // Letters cut from magazines (ransom note, ransom clock).
    readonly property var clippingPapers: ["#f4efe3", "#151515", "#e4572e", "#fff27a", "#3b6fb5", "#ffffff", "#c9a227", "#7bb661"]
    readonly property var clippingDarkPapers: ["#151515", "#3b6fb5", "#e4572e", "#7bb661"]
    readonly property var clippingFonts: [typeFont, markerFont, newsMastFont, newsFont, handFont, "DejaVu Sans Mono", "DejaVu Sans"]

    // What seeds a sticker's clippings: props.seed, set when it is set up in the
    // panel so it keeps the look of its preview; else its id.
    function clippingSeed(sticker) {
        return !sticker ? "" : sticker.props.seed || sticker.id || "";
    }

    // A look for each piece of text: paper, ink, font, size, tilt. Seeded (by
    // the sticker id, say) so it stays put. Sizes go from `size` to 1.5 times it.
    function clippings(pieces, seed, size) {
        let n = 0;
        for (const ch of seed)
            n = (n * 31 + ch.charCodeAt(0)) % 233280;
        const rnd = () => (n = (n * 9301 + 49297) % 233280) / 233280;
        const pick = list => list[Math.floor(rnd() * list.length)];
        return pieces.map(text => {
            const paper = pick(clippingPapers);
            let font = pick(clippingFonts);
            if (font === newsMastFont && /[IJ]/.test(text))
                font = newsFont;  // a blackletter I or J reads as another letter
            return {
                text: text,
                paper: paper,
                ink: clippingDarkPapers.includes(paper) ? "#f4efe3" : "#151515",
                font: font,
                size: size + Math.floor(rnd() * size / 2),
                bold: rnd() < 0.5,
                tilt: (rnd() - 0.5) * 16,
                lift: (rnd() - 0.5) * 8
            };
        });
    }
}
