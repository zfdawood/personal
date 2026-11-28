import QtQuick
import QtQuick.Shapes

// A low-poly card: an octagon (square corners cut at 45°, like Hyprland's
// windows) with a bevel of eight flat faces and a hard shadow down-right.
//
// Each face is shaded by one rule, the same one the wallpaper uses: how
// directly it faces the light at the top left (Lambert's cosine, mapped to
// [0, 1] and used to mix `shade` → `lit`). So the top-left diagonal is the
// brightest face, the bottom-right the darkest, and the top/left faces sit
// just below full light. No smoothing between faces: that's the low-poly part.
//
// Children go inside, past the bevel.
Item {
    id: card

    property int chamfer: Theme.chamfer
    property int bevel: Theme.borderWidth
    property color fill: Theme.bgPrimary
    property color lit: Theme.highlight
    property color shade: Theme.shadow
    property bool dropShadow: true
    property real fillAlpha: 1.0        // the flat face only; the bevel stays solid
    default property alias content: inner.data

    // Where the inner octagon's corners sit: the diagonal edge moved inward
    // by `bevel` crosses the inset straight edge at chamfer + bevel(√2 − 1).
    readonly property real innerCut: chamfer + bevel * (Math.SQRT2 - 1)

    function octagon(inset, cut) {
        const w = width, h = height, i = inset, k = cut
        return [
            Qt.point(k, i), Qt.point(w - k, i),           // top
            Qt.point(w - i, k), Qt.point(w - i, h - k),   // right
            Qt.point(w - k, h - i), Qt.point(k, h - i),   // bottom
            Qt.point(i, h - k), Qt.point(i, k),           // left
            Qt.point(k, i),
        ]
    }

    // Outward normals of the eight faces, in drawing order (top first).
    readonly property var normals: [
        [0, -1], [1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1]
    ]
    function faceColor(n) {
        const len = Math.hypot(n[0], n[1])
        const t = ((n[0] * -Math.SQRT1_2 + n[1] * -Math.SQRT1_2) / len + 1) / 2
        return Qt.rgba(shade.r + (lit.r - shade.r) * t,
                       shade.g + (lit.g - shade.g) * t,
                       shade.b + (lit.b - shade.b) * t, 1)
    }

    readonly property var outer: octagon(0, chamfer)

    // The shadow is the card's outline moved one unit down-right, minus the
    // card itself, so a see-through face never shows its own shadow. The
    // moved outline's top edge ends exactly on the card's top-right diagonal,
    // and its bottom-left diagonal runs along the card's, so what's left is
    // this L-shaped band (valid while the offset is at most the cut).
    readonly property var shadowBand: {
        const w = width, h = height, k = chamfer, s = Theme.shadowOffset
        return [
            Qt.point(w - k + s, s), Qt.point(w + s, k + s), Qt.point(w + s, h - k + s),
            Qt.point(w - k + s, h + s), Qt.point(k + s, h + s), Qt.point(k, h),
            Qt.point(w - k, h), Qt.point(w, h - k), Qt.point(w, k), Qt.point(w - k + s, s),
        ]
    }
    readonly property var innerPts: octagon(bevel, innerCut)

    // Hard shadow, down-right: the band the card doesn't cover.
    Shape {
        visible: card.dropShadow
        width: card.width + Theme.shadowOffset
        height: card.height + Theme.shadowOffset
        ShapePath {
            fillColor: Theme.shadow
            strokeColor: "transparent"
            PathPolyline { path: card.shadowBand }
        }
    }

    // One bevel face: the quad between outer edge i and inner edge i. (Inline
    // components can't see this file's ids, so each face is handed its
    // corners and color.)
    component Face: ShapePath {
        required property var corners
        required property color tone
        fillColor: tone
        strokeColor: "transparent"
        PathPolyline { path: corners }
    }
    function quad(i) {
        return [outer[i], outer[i + 1], innerPts[i + 1], innerPts[i], outer[i]]
    }

    // The eight bevel faces, then the flat face of the card. No antialiasing
    // (Shape's default renderer): diagonals step in whole pixels, crisply.
    Shape {
        anchors.fill: parent
        Face { corners: card.quad(0); tone: card.faceColor(card.normals[0]) }
        Face { corners: card.quad(1); tone: card.faceColor(card.normals[1]) }
        Face { corners: card.quad(2); tone: card.faceColor(card.normals[2]) }
        Face { corners: card.quad(3); tone: card.faceColor(card.normals[3]) }
        Face { corners: card.quad(4); tone: card.faceColor(card.normals[4]) }
        Face { corners: card.quad(5); tone: card.faceColor(card.normals[5]) }
        Face { corners: card.quad(6); tone: card.faceColor(card.normals[6]) }
        Face { corners: card.quad(7); tone: card.faceColor(card.normals[7]) }
        ShapePath {
            fillColor: Qt.rgba(card.fill.r, card.fill.g, card.fill.b, card.fillAlpha)
            strokeColor: "transparent"
            PathPolyline { path: card.innerPts }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: card.bevel
    }
}
