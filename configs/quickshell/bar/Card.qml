import QtQuick
import ".."

// A parchment card lit from the top left, like Hyprland's windows (theirs is
// a diagonal gradient; this splits it by edge, which reads the same): the
// border is the lit color on the top/left edges and the shaded color on the
// bottom/right, with a 1px highlight lip just inside the lit edges.
// Children go in `content`, inset past the border.
Rectangle {
    id: card
    property color lit: Theme.border
    property color shade: Theme.borderShade
    property int edge: Theme.borderWidth
    default property alias content: inner.data

    radius: Theme.radius
    color: Theme.bgPrimary

    // Lit edges (top, left) and the lip inside them.
    Rectangle { x: 0; y: 0; width: card.width; height: card.edge; color: card.lit }
    Rectangle { x: 0; y: 0; width: card.edge; height: card.height; color: card.lit }
    Rectangle { x: card.edge; y: card.edge; width: card.width - 2 * card.edge; height: 1; color: Theme.highlight }
    Rectangle { x: card.edge; y: card.edge; width: 1; height: card.height - 2 * card.edge; color: Theme.highlight }

    // Shaded edges (bottom, right), drawn last so they own the far corners.
    Rectangle { x: 0; y: card.height - card.edge; width: card.width; height: card.edge; color: card.shade }
    Rectangle { x: card.width - card.edge; y: 0; width: card.edge; height: card.height; color: card.shade }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: card.edge
    }
}
