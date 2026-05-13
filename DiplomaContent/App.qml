import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import DiplomaContent.Pages
import DiplomaContent.Navigation
import DiplomaContent.Services
import DiplomaContent.UI_Elements
import DiplomaContent.Network

ApplicationWindow {
    id: appWindow
    minimumHeight: 1024
    minimumWidth: 1280
    title: "Elib"
    visibility: Window.Maximized
    color: "#051F20"
    background: Rectangle { color: "#051F20" }

    // ─── Сплэш-скрин ─────────────────────────────────────────
    Rectangle {
        id: splashScreen
        anchors.fill: parent
        color: "#051F20"
        z: 2000

        Column {
            anchors.centerIn: parent
            spacing: 16

            HeadingText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Elib"
                size: 56
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Электронная библиотека"
                font.family: "Montserrat"; font.pixelSize: 16
                color: "#8EB69B"
            }
        }

        Timer {
            interval: 600; running: true
            onTriggered: {
                splashFadeOut.start()
            }
        }

        NumberAnimation {
            id: splashFadeOut
            target: splashScreen
            property: "opacity"
            to: 0; duration: 400
            easing.type: Easing.OutCubic
            onStopped: splashScreen.visible = false
        }
    }

    // ─── Основной стек навигации ──────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#051F20"
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: WelcomePage {}

        // ─── Анимация появления новой страницы ───────────────
        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0; to: 1
                    duration: 320
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "x"
                    from: appWindow.width * 0.06
                    to: 0
                    duration: 320
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ─── Анимация скрытия предыдущей страницы ────────────
        pushExit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1; to: 0
                duration: 220
                easing.type: Easing.InCubic
            }
        }

        // ─── Анимация возврата (pop) ──────────────────────────
        popEnter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0; to: 1
                duration: 280
                easing.type: Easing.OutCubic
            }
        }
        popExit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 220; easing.type: Easing.InCubic }
                NumberAnimation { property: "x"; from: 0; to: appWindow.width * 0.06; duration: 220; easing.type: Easing.InCubic }
            }
        }
    }

    // ─── Глобальный toast уведомлений ────────────────────────
    NotificationToast {
        id: globalToast
        anchors.horizontalCenter: parent.horizontalCenter
        z: 3000
    }

    // ─── Подписка на NotificationManager ─────────────────────
    Connections {
        target: NotificationManager
        function onNotificationReady(message, type) {
            globalToast.show(message, type)
        }
    }

    // ─── Глобальная обработка ошибок GraphQL ─────────────────
    Connections {
        target: GraphQLClient

        // Истёкший/недействительный токен — выход из системы
        function onUnauthorizedError() {
            TokenManager.clearTokens()
            NavigationModule.popToRoot()
            NotificationManager.warning("Сессия истекла. Войдите снова.")
        }

        // Сервер недоступен (3 подряд сетевые ошибки)
        function onServerUnavailable() {
            NotificationManager.error("Сервер недоступен. Проверьте подключение.")
        }

        // Сервер восстановлен — перезагружаем текущую страницу чтобы обновить обложки
        function onServerRestored() {
            NotificationManager.success("Соединение восстановлено")
            var current = NavigationModule.stackView ? NavigationModule.stackView.currentItem : null
            if (current && typeof current.refresh === "function")
                current.refresh()
        }
    }

    // ─── Загрузка шрифтов Montserrat ─────────────────────────
    FontLoader { source: "fonts/Montserrat-Regular.ttf" }
    FontLoader { source: "fonts/Montserrat-Medium.ttf" }
    FontLoader { source: "fonts/Montserrat-SemiBold.ttf" }
    FontLoader { source: "fonts/Montserrat-Bold.ttf" }
    FontLoader { source: "fonts/Montserrat-ExtraBold.ttf" }
    FontLoader { source: "fonts/Montserrat-Black.ttf" }
    FontLoader { source: "fonts/Montserrat-Light.ttf" }
    FontLoader { source: "fonts/Montserrat-Thin.ttf" }
    FontLoader { source: "fonts/Montserrat-Italic.ttf" }

    Component.onCompleted: {
        NavigationModule.stackView = stackView
    }
}
