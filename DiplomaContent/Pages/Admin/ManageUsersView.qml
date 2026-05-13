import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements
import DiplomaContent.Presenters
import DiplomaContent.Components
import DiplomaContent.Network

// ─────────────────────────────────────────────────────────────
// ManageUsersView — вид управления пользователями
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    property string _sortCol: ""
    property bool   _sortAsc: true
    property var    _allUsers: []

    ManageUsersPresenter {
        id: presenter
        excludeEmployees: true

        onUsersLoaded: {
            root._allUsers = presenter.users
            _rebuildModel(root._allUsers)
        }
        onUserUpdated: {
            presenter.loadUsers("")
            profilePopup.visible = false
            profilePopup.editMode = false
        }
    }

    NotificationToast {
        id: statusText
        anchors.top: root.top; anchors.topMargin: 10
        anchors.horizontalCenter: root.horizontalCenter
    }

    // ─── Мини-профиль попап ───────────────────────────────────
    Item {
        id: profilePopup
        visible: false
        anchors.fill: parent
        z: 200

        property var  user:     null
        property bool editMode: false

        onVisibleChanged: {
            if (visible) { ppFadeAnim.restart(); ppScaleAnim.restart() }
            else editMode = false
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"; opacity: 0.6
            MouseArea { anchors.fill: parent; onClicked: profilePopup.visible = false }
        }

        // Карточка профиля
        Rectangle {
            id: ppCard
            anchors.centerIn: parent
            width: 440; height: profilePopupCol.implicitHeight + 48
            color: "#0B2B26"; radius: 20
            border.color: "#235347"; border.width: 2

            NumberAnimation { id: ppFadeAnim;  target: ppCard; property: "opacity"; from: 0;    to: 1.0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { id: ppScaleAnim; target: ppCard; property: "scale";   from: 0.90; to: 1.0; duration: 260; easing.type: Easing.OutBack  }

            Column {
                id: profilePopupCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 28
                width: parent.width - 48
                spacing: 16

                // Аватар + имя
                Row {
                    width: parent.width; spacing: 16

                    Rectangle {
                        width: 64; height: 64; radius: 32
                        color: "#163832"; border.color: "#235347"; border.width: 2
                        Text {
                            anchors.centerIn: parent
                            text: profilePopup.user ? (profilePopup.user.firstName || "?")[0].toUpperCase() : "?"
                            font.family: "Montserrat"; font.pixelSize: 28; font.bold: true; color: "#DAF1DE"
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Text {
                            text: profilePopup.user ? (profilePopup.user.firstName + " " + profilePopup.user.lastName) : ""
                            font.family: "Montserrat"; font.pixelSize: 18; font.bold: true; color: "#DAF1DE"
                        }
                        Text {
                            text: profilePopup.user ? ("@" + profilePopup.user.username) : ""
                            font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: "#235347" }

                // Детали (только при просмотре)
                Column {
                    width: parent.width; spacing: 10
                    visible: !profilePopup.editMode

                    Repeater {
                        model: [
                            { label: "Email",              key: "email"      },
                            { label: "Телефон",            key: "phone"      },
                            { label: "Дата регистрации",   key: "regDate"    },
                            { label: "Книг в библиотеке",  key: "booksCount" }
                        ]
                        delegate: Row {
                            width: parent.width; spacing: 12
                            Text {
                                width: 170
                                text: modelData.label + ":"
                                font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"
                            }
                            Text {
                                text: profilePopup.user ? (profilePopup.user[modelData.key] || "—").toString() : "—"
                                font.family: "Montserrat"; font.pixelSize: 13; font.bold: true; color: "#DAF1DE"
                            }
                        }
                    }
                }

                // Форма редактирования
                Column {
                    width: parent.width; spacing: 12
                    visible: profilePopup.editMode

                    MainTextField {
                        id: editFirstNameField
                        width: parent.width; height: 46
                        hint: "Имя"; hintTextSize: 13; mainTextSize: 14
                    }
                    MainTextField {
                        id: editLastNameField
                        width: parent.width; height: 46
                        hint: "Фамилия"; hintTextSize: 13; mainTextSize: 14
                    }
                    MainTextField {
                        id: editEmailField
                        width: parent.width; height: 46
                        hint: "Email"; hintTextSize: 13; mainTextSize: 14
                    }
                    MainTextField {
                        id: editPhoneField
                        width: parent.width; height: 46
                        hint: "+7 (999) 000-00-00"; hintTextSize: 12; mainTextSize: 14
                        maximumLength: 18
                        property bool _fmt: false
                        onTextChanged: {
                            if (_fmt) return; _fmt = true
                            var digits = text.replace(/\D/g, "")
                            if (digits === "") { text = ""; _fmt = false; return }
                            if (digits.startsWith("7") || digits.startsWith("8"))
                                digits = digits.slice(1)
                            digits = digits.slice(0, 10)
                            var f = "+7"
                            if (digits.length > 0) f += " (" + digits.slice(0, Math.min(3, digits.length))
                            if (digits.length >= 3) f += ") " + digits.slice(3, Math.min(6, digits.length))
                            if (digits.length >= 6) f += "-" + digits.slice(6, Math.min(8, digits.length))
                            if (digits.length >= 8) f += "-" + digits.slice(8, 10)
                            text = f; _fmt = false
                        }
                    }

                    // Новый пароль (необязательно)
                    MainTextField {
                        id: editUserPasswordField
                        width: parent.width; height: 46
                        hint: "Новый пароль (необязательно)"; hintTextSize: 12; mainTextSize: 14
                        echoMode: TextInput.Password
                    }
                }

                Rectangle { width: parent.width; height: 1; color: "#235347" }

                // Кнопки действий
                Row {
                    width: parent.width; spacing: 12

                    // Кнопка «Редактировать» / «Сохранить»
                    MainButton {
                        width: (parent.width - 12) * 0.6; height: 44
                        buttonTextSize: 11
                        buttonText: profilePopup.editMode ? "Сохранить" : "Редактировать"
                        onClicked: {
                            if (!profilePopup.editMode) {
                                editFirstNameField.text    = profilePopup.user ? profilePopup.user.firstName : ""
                                editLastNameField.text     = profilePopup.user ? profilePopup.user.lastName  : ""
                                editEmailField.text        = profilePopup.user ? profilePopup.user.email     : ""
                                editPhoneField.text        = profilePopup.user ? (profilePopup.user.phone || "") : ""
                                editUserPasswordField.text = ""
                                profilePopup.editMode = true
                            } else {
                                // Роль не меняется через этот попап — передаём существующую
                                presenter.updateUser(profilePopup.user.userId,
                                    editFirstNameField.text,
                                    editLastNameField.text,
                                    editEmailField.text,
                                    editPhoneField.text,
                                    profilePopup.user ? profilePopup.user.role : "",
                                    editUserPasswordField.text)
                            }
                        }
                    }

                    MainButton {
                        width: (parent.width - 12) * 0.4; height: 44
                        buttonTextSize: 11
                        buttonText: profilePopup.editMode ? "Отмена" : "Закрыть"
                        onClicked: {
                            if (profilePopup.editMode) profilePopup.editMode = false
                            else profilePopup.visible = false
                        }
                    }
                }

                Item { width: 1; height: 4 }
            }
        }
    }

    // ─── Основной контент ─────────────────────────────────────
    Column {
        anchors.fill: parent; anchors.margins: 28
        spacing: 20

        // Шапка
        Item {
            width: parent.width; height: 44
            HeadingText { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Пользователи"; size: 26 }
            Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: "Всего: " + usersModel.count
                font.family: "Montserrat"; font.pixelSize: 14; color: "#8EB69B"
            }
        }

        MainTextField {
            id: searchField
            width: 360; height: 46
            hint: "Поиск по имени или email..."
            hintTextSize: 13; mainTextSize: 13
            onTextChanged: _filterUsers(text)
        }

        Rectangle {
            width: parent.width
            height: parent.height - 44 - 60 - 46 - 40
            color: "#163832"; radius: 16
            border.color: "#235347"; border.width: 1
            clip: true

            Column {
                anchors.fill: parent

                // Заголовок таблицы
                Rectangle {
                    width: parent.width; height: 44; color: "#0B2B26"; radius: 16
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 16; color: parent.color }

                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [
                                { label: "Полное имя",  w: 0.28, key: "firstName",  center: false },
                                { label: "Email",       w: 0.26, key: "email",       center: false },
                                { label: "Телефон",     w: 0.18, key: "phone",       center: false },
                                { label: "Дата рег.",   w: 0.16, key: "regDate",     center: false },
                                { label: "Книги",       w: 0.12, key: "booksCount",  center: true  }
                            ]
                            delegate: Item {
                                width: parent.width * modelData.w; height: parent.height

                                Row {
                                    id: headerLabelRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: modelData.center
                                       ? Math.round((parent.width - headerLabelRow.implicitWidth) / 2)
                                       : 12
                                    spacing: 4
                                    Text {
                                        text: modelData.label
                                        font.family: "Montserrat"; font.pixelSize: 12; font.bold: true
                                        color: root._sortCol === modelData.key ? "#DAF1DE" : "#8EB69B"
                                    }
                                    Text {
                                        visible: root._sortCol === modelData.key
                                        text: root._sortAsc ? "↑" : "↓"; font.pixelSize: 11; color: "#DAF1DE"
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root._sortCol === modelData.key) root._sortAsc = !root._sortAsc
                                        else { root._sortCol = modelData.key; root._sortAsc = true }
                                        _rebuildModel(root._allUsers)
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    width: parent.width; height: parent.height - 44; clip: true

                    ListView {
                        id: usersListView
                        model: usersModel

                        delegate: Item {
                            width: usersListView.width; height: 52

                            Rectangle {
                                anchors.fill: parent
                                color: rowArea.containsMouse ? "#1e4040" : (index % 2 === 0 ? "#163832" : "#1a3a3a")
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 1; color: "#235347"; opacity: 0.4
                                }

                                Row {
                                    anchors.fill: parent

                                    // Полное имя
                                    Item {
                                        width: parent.width * 0.28; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12
                                            text: model.firstName + " " + model.lastName
                                            font.family: "Montserrat"; font.pixelSize: 13; font.bold: true; color: "#DAF1DE"; elide: Text.ElideRight
                                        }
                                    }

                                    // Email
                                    Item {
                                        width: parent.width * 0.26; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12
                                            text: model.email; font.family: "Montserrat"; font.pixelSize: 12; color: "#DAF1DE"; elide: Text.ElideRight
                                        }
                                    }

                                    // Телефон
                                    Item {
                                        width: parent.width * 0.18; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12
                                            anchors.right: parent.right; anchors.rightMargin: 8
                                            text: model.phone || "—"; font.family: "Montserrat"; font.pixelSize: 12; color: "#DAF1DE"; elide: Text.ElideRight
                                        }
                                    }

                                    // Дата регистрации
                                    Item {
                                        width: parent.width * 0.16; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12
                                            text: model.regDate; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B"
                                        }
                                    }

                                    // Кол-во книг
                                    Item {
                                        width: parent.width * 0.12; height: parent.height
                                        Text {
                                            anchors.centerIn: parent
                                            text: model.booksCount.toString(); font.family: "Montserrat"; font.pixelSize: 13; color: "#DAF1DE"
                                        }
                                    }
                                }

                                // Клик по строке — открыть мини-профиль
                                MouseArea {
                                    id: rowArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        profilePopup.user = {
                                            userId:     model.userId,
                                            firstName:  model.firstName,
                                            lastName:   model.lastName,
                                            username:   model.username,
                                            email:      model.email,
                                            phone:      model.phone || "",
                                            regDate:    model.regDate,
                                            role:       model.role,
                                            booksCount: model.booksCount
                                        }
                                        profilePopup.visible = true
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent; visible: usersModel.count === 0
                            text: "Пользователи не найдены"
                            font.family: "Montserrat"; font.pixelSize: 16; color: "#8EB69B"
                        }
                    }
                }
            }
        }
    }

    ListModel { id: usersModel }

    function _filterUsers(text) {
        root._allUsers = presenter.users.filter(function(u) {
            return text === ""
                || u.firstName.toLowerCase().includes(text.toLowerCase())
                || u.lastName.toLowerCase().includes(text.toLowerCase())
                || u.email.toLowerCase().includes(text.toLowerCase())
        })
        _rebuildModel(root._allUsers)
    }

    function _rebuildModel(arr) {
        var sorted = arr.slice()
        if (root._sortCol !== "") {
            var col = root._sortCol; var asc = root._sortAsc
            sorted.sort(function(a, b) {
                var va = a[col]; var vb = b[col]
                if (typeof va === "number" && typeof vb === "number") return asc ? va - vb : vb - va
                va = (va || "").toString().toLowerCase(); vb = (vb || "").toString().toLowerCase()
                if (va < vb) return asc ? -1 : 1; if (va > vb) return asc ? 1 : -1; return 0
            })
        }
        usersModel.clear()
        for (var i = 0; i < sorted.length; i++) usersModel.append(sorted[i])
    }

    Component.onCompleted: { if (TokenManager.hasValidToken()) presenter.loadUsers("") }

    function reload() { presenter.loadUsers("") }
}
