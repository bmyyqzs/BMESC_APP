import QtQuick 2.15

// BM premium palette, centralised from vesc_premium_mobility_prototype.html (:root tokens).
// Instantiated once in main.qml and passed down to the shell / home flow as `theme`.
// Existing BM pages keep their own (matching) constants for now; they can adopt this
// object as they are reworked in later phases.
QtObject {
    readonly property color bg: "#050609"
    readonly property color page: "#090b0d"
    readonly property color panel: "#10131a"
    readonly property color surface: "#13171a"
    readonly property color raised: "#191e22"
    readonly property color line: "#262c30"
    readonly property color text: "#f4f1ea"
    readonly property color muted: "#9aa3b2"
    readonly property color gold: "#c69c6e"
    readonly property color gold2: "#dfbd91"
    readonly property color blue: "#4db4ff"
    readonly property color danger: "#ff4d6d"
    readonly property color success: "#64d6b0"
}
