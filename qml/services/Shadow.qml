// The soft shadow every skin casts on the desktop.
//   sticker  its props.shadow (Look.shadowLevels) sets how strong; normal by default
import QtQuick.Effects
import qs.services

MultiEffect {
    property var sticker
    readonly property real level: {
        const name = sticker && sticker.props.shadow;
        return name in Look.shadowLevels ? Look.shadowLevels[name] : 1;
    }

    shadowEnabled: level > 0
    shadowOpacity: Math.min(1, Look.shadowOpacity * level)
    shadowBlur: Look.shadowBlur
    shadowVerticalOffset: Look.shadowOffset * Math.sqrt(level)
    shadowHorizontalOffset: Look.shadowOffset / 3 * Math.sqrt(level)
}
