import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements

// ─────────────────────────────────────────────────────────────
// ConfirmDialog — модальный диалог подтверждения действия
// Использование: dialog.show("Заголовок", "Вопрос")
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    property string title:       "Подтвердить"
    property string message:     "Вы уверены?"
    property string confirmText: "Подтвердить"
    property string cancelText:  "Отмена"
    property string confirmType: "default" // "default" | "danger"

    signal confirmed()
    signal cancelled()

    function show(t, msg, confirmLabel, confirmStyle) {
        root.title       = t           || "Подтвердить"
        root.message     = msg         || "Вы уверены?"
        root.confirmText = confirmLabel || "Подтвердить"
        root.confirmType = confirmStyle || "default"
        root.visible = true
        scaleIn.restart()
    }

    anchors.fill: parent
    visible: false
    z: 1500

    // ─── Тёмная подложка ─────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#051F20"
        opacity: 0.75

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.cancelled()
                root.visible = false
            }
        }
    }

    // ─── Диалоговое окно ─────────────────────────────────────
    Rectangle {
        id: dialogBox
        anchors.centerIn: parent
        width:  Math.min(440, parent.width * 0.85)
        height: dialogColumn.implicitHeight + 56
        color:  "#163832"
        radius: 22
        border.color: "#235347"
        border.width: 2
        z: 1

        // Тень
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 7
            color: "#051F20"
            radius: parent.radius
            z: -1
        }

        NumberAnimation {
            id: scaleIn
            target: dialogBox
            property: "scale"
            from: 0.82; to: 1.0
            duration: 260
            easing.type: Easing.OutBack
        }

        Column {
            id: dialogColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 30
            anchors.topMargin: 32
            spacing: 14

            HeadingText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.title
                size: 22
            }

            Text {
                width: parent.width
                text: root.message
                font.family: "Montserrat"
                font.pixelSize: 14
                color: "#8EB69B"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Item { width: 1; height: 10 }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                MainButton {
                    buttonText: root.cancelText
                    buttonTextSize: 11
                    width: 150; height: 60
                    onClicked: {
                        root.cancelled()
                        root.visible = false
                    }
                }

                // Кнопка подтверждения — стиль как у MainButton
                Item {
                    width: 150; height: 60

                    // Объём (тень снизу) — точно как в MainButton
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height * 1.17
                        radius: 30
                        color: root.confirmType === "danger" ? "#2a0505" : "#0B2B26"
                        border.color: "#051F20"; border.width: 2
                        z: -3
                    }

                    // Основная кнопка
                    Rectangle {
                        id: confirmFace
                        anchors.fill: parent
                        radius: 30
                        color: {
                            if (root.confirmType === "danger")
                                return confirmMa.pressed ? "#5c1010" : (confirmMa.containsMouse ? "#7a1a1a" : "#8B2020")
                            return confirmMa.pressed ? "#163832" : (confirmMa.containsMouse ? "#1e4040" : "#235347")
                        }
                        border.color: "#051f20"; border.width: 2
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.confirmText
                            font.family: "Montserrat"; font.pointSize: 11
                            color: "#DAF1DE"
                        }
                    }

                    scale: confirmMa.pressed ? 0.95 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 160; easing.type: confirmMa.pressed ? Easing.InQuad : Easing.OutBack }
                    }

                    MouseArea {
                        id: confirmMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.confirmed()
                            root.visible = false
                        }
                    }
                }
            }

            Item { width: 1; height: 2 }
        }
    }
}
