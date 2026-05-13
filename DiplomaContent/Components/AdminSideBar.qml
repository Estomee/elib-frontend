import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements

// ─────────────────────────────────────────────────────────────
// AdminSideBar — боковая навигационная панель админ-зоны
// Текущий раздел передаётся через свойство currentSection
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    // ─── Свойства ────────────────────────────────────────────
    property string currentSection: "dashboard"  // dashboard|books|users|upload|logs|employees|reference
    property string adminName:  "Администратор"
    property string adminEmail: ""

    signal sectionRequested(string section)
    signal logoutRequested()

    width: 260

    // ─── Фон сайдбара ────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#0B2B26"
        border.color: "#051F20"
        border.width: 1

        // Правая линия-разделитель
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: "#051F20"
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 0

        // ─ Логотип / заголовок ─
        Item {
            width: parent.width
            height: 90

            Rectangle {
                anchors.fill: parent
                color: "#051F20"
            }

            Column {
                anchors.centerIn: parent
                spacing: 4

                HeadingText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Elib Admin"
                    size: 18
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Панель управления"
                    font.family: "Montserrat"
                    font.pixelSize: 11
                    color: "#8EB69B"
                }
            }
        }

        // ─ Разделитель ─
        Rectangle { width: parent.width; height: 1; color: "#163832" }
        Item { width: 1; height: 12 }

        // ─ Навигационные кнопки ─
        Repeater {
            model: [
                { section: "dashboard",  label: "Главная",        icon: "⊞" },
                { section: "books",      label: "Книги",           icon: "📚" },
                { section: "users",      label: "Пользователи",   icon: "👥" },
                { section: "upload",     label: "Загрузка книг",  icon: "↑"  },
                { section: "logs",       label: "Системные логи", icon: "≡"  },
                { section: "employees",  label: "Сотрудники",     icon: "👤" },
                { section: "reference",  label: "Справочники",    icon: "⚙" }
            ]

            delegate: Item {
                width: root.width
                height: 52

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    radius: 12
                    color: {
                        if (root.currentSection === modelData.section)
                            return "#235347"
                        if (navItemArea.containsMouse)
                            return "#163832"
                        return "transparent"
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    // Активный индикатор
                    Rectangle {
                        visible: root.currentSection === modelData.section
                        width: 4; height: 28; radius: 2
                        color: "#8EB69B"
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        spacing: 14

                        Text {
                            text: modelData.icon
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.label
                            font.family: "Montserrat"
                            font.pixelSize: 14
                            font.bold: root.currentSection === modelData.section
                            color: root.currentSection === modelData.section ? "#DAF1DE" : "#8EB69B"
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: navItemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sectionRequested(modelData.section)
                    }
                }
            }
        }

        // ─ Распорка ─
        Item { width: 1; height: Math.max(0, root.height - 90 - 7 * 52 - 130) }

        // ─ Разделитель ─
        Rectangle { width: parent.width; height: 1; color: "#163832" }
        Item { width: 1; height: 12 }

        // ─ Инфо пользователя + выход ─
        Item {
            width: parent.width
            height: 100

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Text {
                    text: root.adminName
                    font.family: "Montserrat"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#DAF1DE"
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: root.adminEmail !== "" ? root.adminEmail : "admin@elib.local"
                    font.family: "Montserrat"
                    font.pixelSize: 11
                    color: "#8EB69B"
                    elide: Text.ElideRight
                    width: parent.width
                }

                // Кнопка выхода
                Item {
                    width: parent.width
                    height: 36

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: logoutHover.containsMouse ? "#163832" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            spacing: 10

                            Text { text: "⏻"; font.pixelSize: 16; color: "#8B2020"; anchors.verticalCenter: parent.verticalCenter }

                            Text {
                                text: "Выйти из системы"
                                font.family: "Montserrat"
                                font.pixelSize: 12
                                color: "#8B2020"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: logoutHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.logoutRequested()
                        }
                    }
                }
            }
        }
    }
}
