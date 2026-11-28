import QtQuick

// A slot cut into a card (text fields, meter tracks). Light from the top left:
// the slot's top/left inner walls are in shade, its bottom/right walls catch light.
Rectangle {
    color: Theme.bgAlt
    Rectangle { width: parent.width; height: Theme.borderThin; color: Theme.borderShade; z: 1 }
    Rectangle { width: Theme.borderThin; height: parent.height; color: Theme.borderShade; z: 1 }
    Rectangle { y: parent.height - Theme.borderThin; width: parent.width; height: Theme.borderThin; color: Theme.highlight; z: 1 }
    Rectangle { x: parent.width - Theme.borderThin; width: Theme.borderThin; height: parent.height; color: Theme.highlight; z: 1 }
}
