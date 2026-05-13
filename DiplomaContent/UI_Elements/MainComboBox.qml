import QtQuick
import QtQuick.Controls.Basic

// ─────────────────────────────────────────────────────────────
// MainComboBox — стилизованный выпадающий список
// Поддерживает статическую модель (массив строк) и ListModel
// ─────────────────────────────────────────────────────────────
ComboBox {
    id: root

    property real textSize: 13
    property string hint: ""

    width: 200
    height: 45
    font.family: "Montserrat"
    font.pixelSize: textSize

    // ─── Контент кнопки ──────────────────────────────────────
    contentItem: Text {
        leftPadding: 14
        rightPadding: root.indicator.width + 12
        text: root.currentIndex === -1 ? root.hint : root.displayText
        font: root.font
        color: root.currentIndex === -1 ? "#8EB69B" : "#DAF1DE"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    // ─── Стрелка вниз ────────────────────────────────────────
    indicator: Item {
        x: root.width - width - 12
        y: (root.height - height) / 2
        width: 16
        height: 16

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.moveTo(2, 4)
                ctx.lineTo(8, 12)
                ctx.lineTo(14, 4)
                ctx.strokeStyle = "#8EB69B"
                ctx.lineWidth = 2.5
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.stroke()
            }
        }
    }

    // ─── Фон кнопки ──────────────────────────────────────────
    background: Rectangle {
        color: root.pressed ? "#0B2B26" : (root.hovered ? "#163832" : "#235347")
        border.color: "#051F20"
        border.width: 2
        radius: root.height * 0.29
        Behavior on color { ColorAnimation { duration: 150 } }

        // Объём
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 5
            color: "#163832"
            border.color: "#051F20"
            border.width: 2
            radius: parent.radius
            z: -1
        }
    }

    // ─── Выпадающий список ───────────────────────────────────
    popup: Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight, 240)
        padding: 0

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
            NumberAnimation { property: "y"; from: root.height; to: root.height + 4; duration: 150; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 }
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: "#163832"
            border.color: "#051F20"
            border.width: 2
            radius: 12
        }
    }

    // ─── Элемент списка ──────────────────────────────────────
    delegate: ItemDelegate {
        id: delegateItem
        width: root.width
        height: 40
        padding: 0

        contentItem: Text {
            text: modelData !== undefined ? modelData : model[root.textRole]
            font: root.font
            color: delegateItem.highlighted ? "#DAF1DE" : "#8EB69B"
            verticalAlignment: Text.AlignVCenter
            leftPadding: 14
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: delegateItem.highlighted ? "#235347" : "transparent"
            radius: 8
        }

        highlighted: root.highlightedIndex === index
    }
}
