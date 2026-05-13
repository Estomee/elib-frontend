import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements
import DiplomaContent.Presenters
import DiplomaContent.Network

// ─────────────────────────────────────────────────────────────
// SystemLogsView — журнал системных событий
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    SystemLogsPresenter {
        id: presenter

        onLogsLoaded: {
            _applyFilter()
        }
    }

    ManageUsersPresenter {
        id: usersPresenter
    }

    ManageEmployeesPresenter {
        id: empPresenter
    }

    // ─── Мини-профиль исполнителя действия ──────────────────
    // Открывается одним кликом по строке лога (если userId не "0")
    Item {
        id: userPopup
        visible: false
        anchors.fill: parent
        z: 200

        property var    user: null
        property string clickedUserId: ""

        onVisibleChanged: {
            if (visible) { upFadeAnim.restart(); upScaleAnim.restart() }
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"; opacity: 0.6
            MouseArea { anchors.fill: parent; onClicked: userPopup.visible = false }
        }

        Rectangle {
            id: upCard
            anchors.centerIn: parent
            width: 380; height: userPopupCol.implicitHeight + 48
            color: "#051F20"; radius: 20
            border.color: "#235347"; border.width: 2

            NumberAnimation { id: upFadeAnim;  target: upCard; property: "opacity"; from: 0;    to: 1.0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { id: upScaleAnim; target: upCard; property: "scale";   from: 0.90; to: 1.0; duration: 260; easing.type: Easing.OutBack  }

            Column {
                id: userPopupCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 28
                width: parent.width - 48
                spacing: 14

                Row {
                    width: parent.width; spacing: 16
                    Rectangle {
                        width: 56; height: 56; radius: 28
                        color: "#163832"; border.color: "#235347"; border.width: 2
                        Text {
                            anchors.centerIn: parent
                            text: userPopup.user ? (userPopup.user.firstName || "?")[0].toUpperCase() : "?"
                            font.family: "Montserrat"; font.pixelSize: 24; font.bold: true; color: "#DAF1DE"
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Text {
                            text: userPopup.user
                                  ? (userPopup.user.firstName + " " + userPopup.user.lastName)
                                  : "Пользователь #" + userPopup.clickedUserId + " не загружен"
                            font.family: "Montserrat"; font.pixelSize: 16; font.bold: true; color: "#DAF1DE"
                        }
                        Text {
                            text: userPopup.user ? ("@" + userPopup.user.username) : "Возможно удалён или не в текущей выборке"
                            font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B"
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: "#235347" }

                Repeater {
                    model: userPopup.user ? [
                        { label: "Email",    val: userPopup.user.email                   },
                        // TODO: роли удалены — теперь только "Сотрудник" / "Пользователь"
                        { label: "Тип",      val: userPopup.user.userType || "—"         },
                        { label: "Рег.",     val: userPopup.user.regDate                 }
                    ] : []
                    delegate: Row {
                        width: parent.width; spacing: 12
                        Text { width: 80; text: modelData.label + ":"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        Text { text: modelData.val || "—"; font.family: "Montserrat"; font.pixelSize: 12; font.bold: true; color: "#DAF1DE" }
                    }
                }

                MainButton {
                    width: parent.width; height: 40
                    buttonText: "Закрыть"; buttonTextSize: 11
                    onClicked: userPopup.visible = false
                }
                Item { width: 1; height: 4 }
            }
        }
    }

    property string _sortCol: ""
    property bool   _sortAsc: true

    Column {
        anchors.fill: parent; anchors.margins: 28
        spacing: 20

        // Шапка + фильтры
        Item {
            width: parent.width; height: 44

            HeadingText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: "Системные логи"; size: 26
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                spacing: 12

                // Фильтр по уровню
                MainComboBox {
                    id: levelFilter
                    width: 160; height: 44
                    model: ["Все уровни", "info", "warning", "error"]
                    textSize: 13
                    onCurrentTextChanged: {
                        var lvl = currentText === "Все уровни" ? "all" : currentText
                        presenter.loadLogs(lvl, "", "")
                    }
                }

                MainButton {
                    width: 130; height: 44
                    buttonText: "Обновить"
                    buttonTextSize: 11
                    onClicked: presenter.loadLogs("all", "", "")
                }
            }
        }

        // Счётчик
        Text {
            text: "Всего записей: " + presenter.totalLogs
            font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"
        }

        // Таблица логов
        Rectangle {
            width: parent.width
            height: parent.height - 44 - 30 - 60
            color: "#163832"; radius: 16; border.color: "#235347"; border.width: 1; clip: true

            Column {
                anchors.fill: parent

                // Заголовок
                Rectangle {
                    width: parent.width; height: 44; color: "#0B2B26"; radius: 16
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 16; color: parent.color }

                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [
                                { label: "Время",      w: 0.18, key: "timestamp", center: false },
                                { label: "Уровень",    w: 0.10, key: "level",     center: true  },
                                { label: "ID польз.",  w: 0.08, key: "userId",    center: false },
                                { label: "Действие",   w: 0.48, key: "action",    center: false },
                                { label: "IP-адрес",   w: 0.16, key: "ip",        center: false }
                            ]
                            delegate: Item {
                                width: parent.width * modelData.w; height: parent.height
                                Row {
                                    id: _logHdrRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: modelData.center
                                       ? Math.round((parent.width - _logHdrRow.implicitWidth) / 2)
                                       : 12
                                    spacing: 4
                                    Text {
                                        text: modelData.label
                                        font.family: "Montserrat"; font.pixelSize: 12; font.bold: true
                                        color: root._sortCol === modelData.key ? "#DAF1DE" : "#8EB69B"
                                    }
                                    Text {
                                        visible: root._sortCol === modelData.key
                                        text: root._sortAsc ? "↑" : "↓"
                                        font.pixelSize: 11; color: "#DAF1DE"
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root._sortCol === modelData.key) root._sortAsc = !root._sortAsc
                                        else { root._sortCol = modelData.key; root._sortAsc = true }
                                        _sortLogs()
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    width: parent.width; height: parent.height - 44; clip: true

                    ListView {
                        id: logsListView
                        model: logsModel

                        delegate: Item {
                            width: logsListView.width; height: 46

                            readonly property color levelColor: {
                                switch (model.level) {
                                    case "error":   return "#F44336"
                                    case "warning": return "#FF9800"
                                    default:        return "#8EB69B"
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: rowArea.containsMouse ? "#1e4040" : (index % 2 === 0 ? "#163832" : "#1a3a3a")
                                Behavior on color { ColorAnimation { duration: 100 } }

                                // Цветная метка уровня
                                Rectangle {
                                    width: 3; height: parent.height
                                    color: levelColor
                                    opacity: 0.7
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 1; color: "#235347"; opacity: 0.3
                                }

                                Row {
                                    anchors.fill: parent

                                    // Время
                                    Item {
                                        width: parent.width * 0.18; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left; anchors.leftMargin: 12
                                            text: model.timestamp
                                            font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B"
                                        }
                                    }

                                    // Уровень (бейдж)
                                    Item {
                                        width: parent.width * 0.10; height: parent.height
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 64; height: 22; radius: 11
                                            color: {
                                                switch (model.level) {
                                                    case "error":   return "#3a0a0a"
                                                    case "warning": return "#2a1a00"
                                                    default:        return "#0a2a1a"
                                                }
                                            }
                                            border.color: levelColor; border.width: 1

                                            Text {
                                                anchors.centerIn: parent; text: model.level
                                                font.family: "Montserrat"; font.pixelSize: 10; font.bold: true
                                                color: levelColor
                                            }
                                        }
                                    }

                                        // User ID — отображение; клик обрабатывается rowArea
                                    Item {
                                        width: parent.width * 0.08; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12
                                            text: model.userId === "—" ? "—" : "#" + model.userId
                                            font.family: "Montserrat"; font.pixelSize: 12
                                            color: model.userId !== "—" && rowArea.containsMouse ? "#DAF1DE" : "#8EB69B"
                                            font.underline: model.userId !== "—" && rowArea.containsMouse
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                        }
                                    }

                                    // Действие
                                    Item {
                                        width: parent.width * 0.48; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12
                                            text: model.action
                                            font.family: "Montserrat"; font.pixelSize: 12; color: "#DAF1DE"; elide: Text.ElideRight
                                        }
                                    }

                                    // IP
                                    Item {
                                        width: parent.width * 0.16; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12
                                            text: model.ip; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B"
                                        }
                                    }
                                }

                                // Клик по строке → показать профиль исполнителя
                                // TODO: при подключении backend — искать пользователя по userId через GraphQL
                                MouseArea {
                                    id: rowArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: model.userId !== "—" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (model.userId === "—") return
                                        var found = null
                                        for (var i = 0; i < usersPresenter.users.length; i++) {
                                            if (usersPresenter.users[i].userId.toString() === model.userId.toString()) {
                                                found = usersPresenter.users[i]; break
                                            }
                                        }
                                        if (found && found.userType === "Сотрудник") {
                                            for (var j = 0; j < empPresenter.employees.length; j++) {
                                                if (empPresenter.employees[j].userId.toString() === model.userId.toString()) {
                                                    var pos = empPresenter.employees[j].positionTitle
                                                    found = Object.assign({}, found, {
                                                        userType: pos ? "Сотрудник (" + pos + ")" : "Сотрудник"
                                                    })
                                                    break
                                                }
                                            }
                                        }
                                        userPopup.clickedUserId = model.userId
                                        userPopup.user = found
                                        userPopup.visible = true
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent; visible: logsModel.count === 0
                            text: "Логи не найдены"
                            font.family: "Montserrat"; font.pixelSize: 16; color: "#8EB69B"
                        }
                    }
                }
            }
        }
    }

    ListModel { id: logsModel }

    function _applyFilter() {
        root._currentFiltered = presenter.logs
        _sortLogs()
    }

    property var _currentFiltered: []

    function _sortLogs() {
        var arr = root._currentFiltered.slice()
        if (root._sortCol !== "") {
            var col = root._sortCol; var asc = root._sortAsc
            arr.sort(function(a, b) {
                var va = (a[col] || "").toString().toLowerCase()
                var vb = (b[col] || "").toString().toLowerCase()
                if (va < vb) return asc ? -1 : 1
                if (va > vb) return asc ? 1 : -1
                return 0
            })
        }
        logsModel.clear()
        for (var i = 0; i < arr.length; i++) logsModel.append(arr[i])
    }

    Component.onCompleted: {
        if (!TokenManager.hasValidToken()) return
        presenter.loadLogs("all", "", "")
        usersPresenter.loadUsers("")
        empPresenter.loadEmployees("")
    }

    function reload() {
        presenter.loadLogs("all", "", "")
        usersPresenter.loadUsers("")
        empPresenter.loadEmployees("")
    }
}
