import QtQuick
import QtQuick.Controls.Basic

// ─────────────────────────────────────────────────────────────
// BookCard — карточка книги для каталога и личной библиотеки
// Hover: затемнение + «Читать» + «В библиотеку»
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    // ─── Свойства ────────────────────────────────────────────
    property string bookId:       ""
    property string title:        "Название книги"
    property string author:       "Автор"
    property string genre:        ""
    property string coverSource:  ""
    property int    year:         0
    property int    readProgress: 0   // 0–100, для личной библиотеки

    signal readClicked(string bookId)
    signal addToLibraryClicked(string bookId)

    width: 180
    height: 290

    // ─── Тень (объём) ────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 8
        color: "#051F20"
        radius: 16
        z: 0
    }

    // ─── Hover-обработчик (размещён ДО card → меньший z) ─────
    // Обеспечивает containsMouse для цвета карточки и overlay.
    // «В библиотеку» кнопка имеет больший z и перехватывает свой клик.
    MouseArea {
        id: hoverArea
        anchors.fill: card
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.readClicked(root.bookId)
    }

    // ─── Карточка ────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.fill: parent
        anchors.bottomMargin: 8
        color: hoverArea.containsMouse ? "#163832" : "#235347"
        radius: 16
        border.color: "#051F20"
        border.width: 2
        clip: true
        layer.enabled: true
        z: 1

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
        scale: hoverArea.pressed ? 0.97 : 1.0

        // ─ Обложка ─
        Rectangle {
            id: coverArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.58
            radius: 10
            color: "#0B2B26"
            clip: true
            layer.enabled: true

            // Изображение обложки
            Image {
                id: coverImage
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                source: root.coverSource !== "" ? root.coverSource : ""
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
                asynchronous: true
                cache: false
                visible: root.coverSource !== ""
                // После первой успешной загрузки держим opacity=1 даже во время повторной загрузки:
                // Qt продолжает рендерить старый кадр пока грузится новый — мигания нет.
                property bool everLoaded: false
                opacity: (status === Image.Ready || everLoaded) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                onStatusChanged: if (status === Image.Ready) everLoaded = true
                onSourceChanged: everLoaded = false
            }

            // Заглушка — только если нет источника или ошибка загрузки
            Item {
                anchors.fill: parent
                visible: root.coverSource === "" || coverImage.status === Image.Error

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 42; height: 54
                        radius: 5
                        color: "#235347"
                        border.color: "#051F20"
                        border.width: 1
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            Repeater {
                                model: 3
                                Rectangle {
                                    width: 26 - index * 4
                                    height: 3
                                    radius: 2
                                    color: "#8EB69B"
                                    opacity: 0.8 - index * 0.2
                                }
                            }
                        }
                    }
                }
            }

            // Overlay при наведении
            Rectangle {
                id: hoverOverlay
                anchors.fill: parent
                radius: coverArea.radius
                color: "#051F20"
                opacity: hoverArea.containsMouse ? 0.78 : 0
                z: 2
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    opacity: hoverArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    // Кнопка «Читать»
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Читать"
                        font.family: "Montserrat"
                        font.pixelSize: 16; font.bold: true
                        color: "#DAF1DE"
                    }
                }
            }
        }

        // ─ Прогресс-бар (если readProgress > 0) ─
        Rectangle {
            anchors.left: coverArea.left
            anchors.right: coverArea.right
            anchors.top: coverArea.bottom
            anchors.topMargin: 6
            height: 3
            color: "#163832"
            radius: 2
            visible: root.readProgress > 0

            Rectangle {
                width: parent.width * (root.readProgress / 100)
                height: parent.height
                color: "#8EB69B"
                radius: 2
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }

        // ─ Метаданные ─
        Column {
            anchors.top: coverArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            anchors.topMargin: root.readProgress > 0 ? 14 : 8
            spacing: 3

            Text {
                width: parent.width
                text: root.title
                font.family: "Montserrat"
                font.pixelSize: 12; font.bold: true
                color: "#DAF1DE"
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }

            Text {
                width: parent.width
                text: root.author
                font.family: "Montserrat"
                font.pixelSize: 10
                color: "#8EB69B"
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    var parts = root.genre.split(/[,;]/).map(function(g) { return g.trim() }).filter(function(g) { return g !== "" })
                    var display = parts.slice(0, 2).join(" · ")
                    if (root.year > 0 && display !== "") return display + "  " + root.year
                    if (root.year > 0) return root.year.toString()
                    return display
                }
                font.family: "Montserrat"
                font.pixelSize: 9
                color: "#8EB69B"
                opacity: 0.7
                elide: Text.ElideRight
                visible: (root.year > 0 || root.genre !== "")
            }
        }
    }
}
