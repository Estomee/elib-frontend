import QtQuick
import QtQuick.Controls.Basic

// ─────────────────────────────────────────────────────────────
// NotificationToast — всплывающее уведомление (slide-in сверху)
// Использование: toast.show("Сообщение", "success")
// Типы: "success" | "error" | "warning" | "info"
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    property string message: ""
    property string type: "info"
    property int autoDismissMs: 3500

    readonly property color _typeColor: {
        switch (type) {
            case "success": return "#4CAF50"
            case "error":   return "#F44336"
            case "warning": return "#FF9800"
            default:        return "#8EB69B"
        }
    }
    readonly property string _typeIcon: {
        switch (type) {
            case "success": return "✓"
            case "error":   return "✕"
            case "warning": return "!"
            default:        return "i"
        }
    }

    // ─── API ─────────────────────────────────────────────────
    function show(msg, t) {
        root.message = msg || ""
        root.type    = t   || "info"
        // Для ошибок — дольше на экране
        root.autoDismissMs = (root.type === "error" ? 5000 : 3500)
        root.opacity = 0
        root.y = -(root.height + 8)
        root.visible = true
        slideIn.restart()
        fadeIn.restart()
        if (root.autoDismissMs > 0) dismissTimer.restart()
    }

    function hide() {
        dismissTimer.stop()
        slideOut.start()
        fadeOut.start()
    }

    // ─── Геометрия ───────────────────────────────────────────
    width:  Math.min(440, parent ? parent.width - 48 : 440)
    height: 60
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    y: -(height + 8)
    opacity: 0
    visible: false
    z: 2000

    // ─── Анимации ────────────────────────────────────────────
    NumberAnimation {
        id: slideIn
        target: root; property: "y"
        to: 20; duration: 360; easing.type: Easing.OutBack
    }
    NumberAnimation {
        id: slideOut
        target: root; property: "y"
        to: -(root.height + 8); duration: 280; easing.type: Easing.InCubic
    }
    NumberAnimation {
        id: fadeIn
        target: root; property: "opacity"
        from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: fadeOut
        target: root; property: "opacity"
        from: 1; to: 0; duration: 280; easing.type: Easing.InCubic
        onStopped: root.visible = false
    }
    Timer {
        id: dismissTimer
        interval: root.autoDismissMs
        onTriggered: root.hide()
    }

    // ─── Тень ────────────────────────────────────────────────
    Rectangle {
        anchors.fill: bg
        anchors.topMargin: 5
        color: "#051F20"
        radius: bg.radius
    }

    // ─── Тело уведомления ────────────────────────────────────
    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.bottomMargin: 5
        color: "#163832"
        radius: 16
        border.color: root._typeColor
        border.width: 2

        // Цветная левая полоска
        Rectangle {
            width: 5
            height: parent.height - 16
            anchors.left: parent.left
            anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            color: root._typeColor
            radius: 3
        }

        // Иконка
        Rectangle {
            id: iconCircle
            width: 26; height: 26; radius: 13
            color: root._typeColor
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: root._typeIcon
                font.family: "Montserrat"
                font.pixelSize: 14
                font.bold: true
                color: "#051F20"
            }
        }

        // Текст
        Text {
            anchors.left: iconCircle.right
            anchors.right: closeButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            text: root.message
            font.family: "Montserrat"
            font.pixelSize: 13
            color: "#DAF1DE"
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }

        // Кнопка закрытия
        Item {
            id: closeButton
            width: 32; height: 32
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                color: "#8EB69B"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.hide()
            }
        }
    }
}
