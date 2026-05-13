import QtQuick

// ─────────────────────────────────────────────────────────────
// PageLoader — полноэкранный оверлей загрузки со спиннером
// Использование: pageLoader.loading = true / false
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    property bool loading: false
    property string loadingText: "Загрузка..."

    anchors.fill: parent
    visible: loading
    z: 999

    // ─── Подложка ────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#051F20"
        opacity: 0.80
    }

    // ─── Спиннер + текст ─────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 20

        // Вращающееся кольцо
        Item {
            id: spinnerItem
            width: 64; height: 64
            anchors.horizontalCenter: parent.horizontalCenter

            // Фоновое кольцо
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: "#163832"
                border.width: 6
            }

            // Вращающийся индикатор
            Item {
                id: rotatingDot
                anchors.fill: parent

                Rectangle {
                    width: 16; height: 16; radius: 8
                    color: "#8EB69B"
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0

                    layer.enabled: true
                }

                RotationAnimation on rotation {
                    from: 0; to: 360
                    duration: 900
                    loops: Animation.Infinite
                    running: root.visible
                }
            }

            // Второй индикатор (смещён на 180°)
            Item {
                anchors.fill: parent

                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: "#235347"
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                }

                rotation: 180

                RotationAnimation on rotation {
                    from: 180; to: 540
                    duration: 900
                    loops: Animation.Infinite
                    running: root.visible
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.loadingText
            font.family: "Montserrat"
            font.pixelSize: 14
            color: "#8EB69B"

            SequentialAnimation on opacity {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }
        }
    }

    // ─── Анимация появления ──────────────────────────────────
    Behavior on visible {
        SequentialAnimation {
            PropertyAction { }
            NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 200 }
        }
    }
}
