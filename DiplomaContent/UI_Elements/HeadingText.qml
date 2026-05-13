import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    width: label.implicitWidth
    height: label.implicitHeight

    property alias text: label.text
    property alias size: label.font.pointSize
    property color glowColor: "#DAF1DE"
    property color outlineColor: "#0B2B26"
    property color offsetColor: "#235347"
    property color solidShadowColor: "#051F20"
    property bool glowEnabled: false

    property real glowRadius: 0
    property real maxGlowRadius: 25
    property bool hovered: false
    signal clicked()
    //define of presenter

    //outline
    Text {
        id: outlineLabel
        anchors.centerIn: parent
        text: root.text
        font.family: "Montserrat"
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: label.font.pointSize
        Repeater {
            model: 70
            Text {
                x: index % 5 - 2    // 5 col, offset=2
                y: Math.floor(index / 5) - 3
                text: outlineLabel.text
                font: outlineLabel.font
                color: outlineColor
                z: -4
            }
        }
    }

    //solid shadow
    Text {
        id: solidLabel
        anchors.centerIn: parent
        text: root.text
        font.family: "Montserrat"
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: label.font.pointSize
        Repeater {
            model: 90
            Text {
                x: index % 5 - 2    // 5 col, offset=2
                y: Math.floor(index / 5) - 3
                text: solidLabel.text
                font: solidLabel.font
                color: solidShadowColor
                z: -4
            }
        }
    }

    // colored offset (for text volume)
    Text {
        id: offsetLabel
        anchors.centerIn: parent
        text: root.text
        font.family: "Montserrat"
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: label.font.pointSize
        Repeater {
            model: 30
            Text {
                x: index % 3 - 1
                y: Math.floor(index / 3) - 1
                text: offsetLabel.text
                font: offsetLabel.font
                color: offsetColor
                z: -3
            }
        }
    }

    //Main text
    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: "#daf1de"
        font.family: "Montserrat"
        horizontalAlignment: Text.AlignHCenter
        z: 1
    }


    // glow
    MultiEffect {
        id: glowFx
        source: label
        anchors.fill: label
        visible: glowEnabled && glowRadius > 0
        blurEnabled: true
        blur: Math.min(glowRadius / Math.max(root.maxGlowRadius, 1), 1.0)
        blurMax: 32
        colorization: 1.0
        colorizationColor: glowColor
        z: 0
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: glowEnabled
        onEntered: hovered = true
        onExited: hovered = false

        onClicked: {
           root.clicked()
        }
    }

    onHoveredChanged: {
        glowRadius = hovered ? maxGlowRadius : 0
    }

    Behavior on glowRadius {
        NumberAnimation {
            duration: hovered ? 300 : 400
            easing.type: hovered ? Easing.OutCubic : Easing.InCubic
        }
    }
}
