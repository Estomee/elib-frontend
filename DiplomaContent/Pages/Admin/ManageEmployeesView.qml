// Employee management view with add/edit popup and sortable table.
import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements
import DiplomaContent.Presenters
import DiplomaContent.Components
import DiplomaContent.Network

Item {
    id: root

    property var    _allEmployees: []
    property string _sortCol: ""
    property bool   _sortAsc: true

    ManageEmployeesPresenter {
        id: presenter

        onEmployeesLoaded: {
            root._allEmployees = presenter.employees
            _rebuildModel(root._allEmployees)
        }
        onEmployeeAdded: {
            statusText.show("Сотрудник добавлен", "success")
            presenter.loadEmployees("")
        }
        onEmployeeUpdated: {
            statusText.show("Данные сотрудника обновлены", "success")
            presenter.loadEmployees("")
        }
        onEmployeeDeleted: {
            statusText.show("Сотрудник удалён", "success")
            presenter.loadEmployees("")
        }
        onOperationFailed: function(msg) {
            statusText.show(msg, "error")
        }
    }

    ConfirmDialog {
        id: deleteDialog
        title: "Удалить сотрудника?"
        confirmText: "Удалить"
        confirmType: "danger"
        property string pendingId: ""
        onConfirmed: presenter.deleteEmployee(pendingId)
    }

    NotificationToast {
        id: statusText
        anchors.top: root.top; anchors.topMargin: 10
        anchors.horizontalCenter: root.horizontalCenter
    }

    Item {
        id: empPopup
        visible: false
        anchors.fill: parent
        z: 200

        property string editingId: ""
        property bool   isEditMode: editingId !== ""

        onVisibleChanged: {
            if (visible) { empFadeAnim.restart(); empScaleAnim.restart() }
        }

        Rectangle {
            anchors.fill: parent; color: "#000000"; opacity: 0.6
            MouseArea { anchors.fill: parent; onClicked: empPopup.visible = false }
        }

        Rectangle {
            id: empCard
            anchors.centerIn: parent
            width: 520
            height: Math.min(empScroll.contentHeight + 80, root.height * 0.88)
            color: "#0B2B26"; radius: 20; border.color: "#235347"; border.width: 2

            NumberAnimation { id: empFadeAnim;  target: empCard; property: "opacity"; from: 0; to: 1;    duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { id: empScaleAnim; target: empCard; property: "scale";   from: 0.90; to: 1; duration: 260; easing.type: Easing.OutBack }

            Text {
                id: empCardTitle
                anchors.top: parent.top; anchors.topMargin: 22
                anchors.horizontalCenter: parent.horizontalCenter
                text: empPopup.isEditMode ? "Редактировать сотрудника" : "Добавить сотрудника"
                font.family: "Montserrat"; font.pixelSize: 18; font.bold: true; color: "#DAF1DE"
            }

            ScrollView {
                id: empScroll
                anchors.top: empCardTitle.bottom; anchors.topMargin: 16
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: empBtnRow.top; anchors.bottomMargin: 12
                clip: true

                Column {
                    width: empCard.width - 48; x: 24; spacing: 14

                    Text { text: "ФИО сотрудника *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }

                    Row {
                        width: parent.width; spacing: 10
                        Column {
                            width: (parent.width - 20) / 3; spacing: 4
                            Text { text: "Фамилия"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                            MainTextField { id: empLastName;   width: parent.width; height: 42; hint: "Фамилия";  hintTextSize: 11; mainTextSize: 13 }
                        }
                        Column {
                            width: (parent.width - 20) / 3; spacing: 4
                            Text { text: "Имя"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                            MainTextField { id: empFirstName;  width: parent.width; height: 42; hint: "Имя";      hintTextSize: 11; mainTextSize: 13 }
                        }
                        Column {
                            width: (parent.width - 20) / 3; spacing: 4
                            Text { text: "Отчество"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                            MainTextField { id: empMiddleName; width: parent.width; height: 42; hint: "Отчество"; hintTextSize: 11; mainTextSize: 13 }
                        }
                    }

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Email *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        MainTextField { id: empEmail; width: parent.width; height: 46; hint: "user@elib.ru"; hintTextSize: 12; mainTextSize: 13 }
                    }

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Телефон"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        MainTextField {
                            id: empPhone; width: parent.width; height: 46
                            hint: "+7 (999) 000-00-00"; hintTextSize: 12; mainTextSize: 13; maximumLength: 18
                            property bool _fmt: false
                            onTextChanged: {
                                if (_fmt) return; _fmt = true
                                var d = text.replace(/[^0-9+]/g, "")
                                if (d === "") { text = ""; _fmt = false; return }
                                var digits = d.replace(/\D/g, "")
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
                    }

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Должность *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        MainComboBox {
                            id: empPositionCombo
                            width: parent.width; height: 46; textSize: 13
                            hint: "— выбрать должность —"
                            model: {
                                var items = ["— выбрать —"]
                                for (var i = 0; i < presenter.availablePositions.length; i++)
                                    items.push(presenter.availablePositions[i].title)
                                return items
                            }
                        }
                    }

                    Row {
                        width: parent.width; spacing: 12
                        Column {
                            width: (parent.width - 12) / 2; spacing: 4
                            Text { text: "Дата найма *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            MainTextField {
                                id: empHireDate; width: parent.width; height: 46
                                hint: "ГГГГ-ММ-ДД"; hintTextSize: 12; mainTextSize: 13; maximumLength: 10
                                property bool _fmt: false
                                onTextChanged: {
                                    if (_fmt) return; _fmt = true
                                    var d = text.replace(/[^0-9]/g, "").slice(0, 8)
                                    var f = d.slice(0, Math.min(4, d.length))
                                    if (d.length > 4) f += "-" + d.slice(4, Math.min(6, d.length))
                                    if (d.length > 6) f += "-" + d.slice(6, 8)
                                    text = f; _fmt = false
                                }
                            }
                        }
                        Column {
                            width: (parent.width - 12) / 2; spacing: 4
                            Text { text: "Дата увольнения"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            MainTextField {
                                id: empTermDate; width: parent.width; height: 46
                                hint: "ГГГГ-ММ-ДД (необяз.)"; hintTextSize: 12; mainTextSize: 13; maximumLength: 10
                                property bool _fmt: false
                                onTextChanged: {
                                    if (_fmt) return; _fmt = true
                                    var d = text.replace(/[^0-9]/g, "").slice(0, 8)
                                    var f = d.slice(0, Math.min(4, d.length))
                                    if (d.length > 4) f += "-" + d.slice(4, Math.min(6, d.length))
                                    if (d.length > 6) f += "-" + d.slice(6, 8)
                                    text = f; _fmt = false
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width; spacing: 12
                        Column {
                            width: (parent.width - 12) * 0.45; spacing: 4
                            Text { text: "Серия паспорта *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            MainTextField { id: empPassSeries; width: parent.width; height: 46; hint: "0000"; hintTextSize: 12; mainTextSize: 13; maximumLength: 4; validator: RegularExpressionValidator { regularExpression: /^[0-9]*$/ } }
                        }
                        Column {
                            width: (parent.width - 12) * 0.55; spacing: 4
                            Text { text: "Номер паспорта *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            MainTextField { id: empPassNumber; width: parent.width; height: 46; hint: "000000"; hintTextSize: 12; mainTextSize: 13; maximumLength: 6; validator: RegularExpressionValidator { regularExpression: /^[0-9]*$/ } }
                        }
                    }

                    Item { width: 1; height: 4 }
                }
            }

            Row {
                id: empBtnRow
                anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 12

                MainButton {
                    width: 240; height: 48
                    buttonText: empPopup.isEditMode ? "Сохранить" : "Добавить"; buttonTextSize: 11
                    onClicked: {
                        if (empLastName.text.trim() === "" || empFirstName.text.trim() === "") {
                            statusText.show("Введите ФИО сотрудника", "error"); return
                        }
                        if (empEmail.text.trim() === "") {
                            statusText.show("Введите email", "error"); return
                        }
                        if (empHireDate.text.trim() === "") {
                            statusText.show("Введите дату найма", "error"); return
                        }
                        var _posIdx = empPositionCombo.currentIndex - 1
                        var _posId  = _posIdx >= 0 ? presenter.availablePositions[_posIdx].positionId : ""
                        var _posTitle = _posIdx >= 0 ? presenter.availablePositions[_posIdx].title : ""

                        var input = {
                            firstName:       empFirstName.text.trim(),
                            lastName:        empLastName.text.trim(),
                            middleName:      empMiddleName.text.trim(),
                            email:           empEmail.text.trim(),
                            phone:           empPhone.text.trim(),
                            positionId:      _posId,
                            positionTitle:   _posTitle,
                            hireDate:        empHireDate.text.trim(),
                            terminationDate: empTermDate.text.trim(),
                            passportSeries:  empPassSeries.text.trim(),
                            passportNumber:  empPassNumber.text.trim()
                        }
                        if (empPopup.isEditMode)
                            presenter.updateEmployee(empPopup.editingId, input)
                        else
                            presenter.addEmployee(input)
                        empPopup.visible = false
                    }
                }
                MainButton {
                    width: 160; height: 48; buttonText: "Отмена"; buttonTextSize: 11
                    onClicked: empPopup.visible = false
                }
            }
        }
    }

    Column {
        anchors.fill: parent; anchors.margins: 28; spacing: 20

        Item {
            width: parent.width; height: 44
            HeadingText { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Сотрудники"; size: 26 }
            MainButton {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                width: 200; height: 44; buttonText: "+ Добавить сотрудника"; buttonTextSize: 11
                onClicked: {
                    _clearForm()
                    empPopup.editingId = ""
                    empPopup.visible   = true
                }
            }
        }

        MainTextField {
            id: searchField; width: 380; height: 46
            hint: "Поиск по ФИО или email..."; hintTextSize: 13; mainTextSize: 13
            onTextChanged: _filterEmployees(text)
        }

        Rectangle {
            width: parent.width
            height: parent.height - 44 - 60 - 46 - 40
            color: "#163832"; radius: 16; border.color: "#235347"; border.width: 1; clip: true

            Column {
                anchors.fill: parent

                Rectangle {
                    width: parent.width; height: 44; color: "#0B2B26"; radius: 16
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 16; color: parent.color }
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [
                                { label: "ФИО",          w: 0.24, key: "lastName"        },
                                { label: "Email",        w: 0.20, key: "email"           },
                                { label: "Должность",    w: 0.16, key: "positionTitle"   },
                                { label: "Телефон",      w: 0.16, key: "phone"           },
                                { label: "Дата найма",   w: 0.12, key: "hireDate"        },
                                { label: "Увольнение",   w: 0.08, key: "terminationDate" },
                                { label: "",             w: 0.04, key: ""               }
                            ]
                            delegate: Item {
                                width: parent.width * modelData.w; height: parent.height
                                Row {
                                    id: _empHdrRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left; anchors.leftMargin: 12; spacing: 4
                                    Text {
                                        text: modelData.label
                                        font.family: "Montserrat"; font.pixelSize: 12; font.bold: true
                                        color: modelData.key !== "" && root._sortCol === modelData.key ? "#DAF1DE" : "#8EB69B"
                                    }
                                    Text {
                                        visible: modelData.key !== "" && root._sortCol === modelData.key
                                        text: root._sortAsc ? "↑" : "↓"
                                        font.pixelSize: 11; color: "#DAF1DE"
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: modelData.key !== ""
                                    cursorShape: modelData.key !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (root._sortCol === modelData.key) root._sortAsc = !root._sortAsc
                                        else { root._sortCol = modelData.key; root._sortAsc = true }
                                        _rebuildModel(root._allEmployees)
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    width: parent.width; height: parent.height - 44; clip: true
                    ListView {
                        id: empListView
                        model: empModel

                        delegate: Item {
                            width: empListView.width; height: 52

                            Rectangle {
                                anchors.fill: parent
                                color: rowArea.containsMouse ? "#1e4040" : (index % 2 === 0 ? "#163832" : "#1a3a3a")
                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea {
                                    id: rowArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        _clearForm()
                                        empFirstName.text  = model.firstName  || ""
                                        empLastName.text   = model.lastName   || ""
                                        empMiddleName.text = model.middleName || ""
                                        empEmail.text      = model.email      || ""
                                        empPhone.text      = model.phone      || ""
                                        empHireDate.text   = model.hireDate   || ""
                                        empTermDate.text   = model.terminationDate || ""
                                        empPassSeries.text = model.passportSeries  || ""
                                        empPassNumber.text = model.passportNumber  || ""

                                        var posIdx = 0
                                        for (var pi = 0; pi < presenter.availablePositions.length; pi++) {
                                            if (presenter.availablePositions[pi].positionId === model.positionId) {
                                                posIdx = pi + 1; break
                                            }
                                        }
                                        empPositionCombo.currentIndex = posIdx

                                        empPopup.editingId = model.employeeId
                                        empPopup.visible   = true
                                    }
                                }

                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#235347"; opacity: 0.4 }

                                Row {
                                    anchors.fill: parent
                                    Item {
                                        width: parent.width * 0.24; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12
                                            text: (model.lastName || "") + " " + (model.firstName || "") + (model.middleName ? " " + model.middleName : "")
                                            font.family: "Montserrat"; font.pixelSize: 13; font.bold: true; color: "#DAF1DE"; elide: Text.ElideRight
                                        }
                                    }
                                    EmpCell { w: 0.20; val: model.email         || "—" }
                                    EmpCell { w: 0.16; val: model.positionTitle || "—" }
                                    EmpCell { w: 0.16; val: model.phone         || "—" }
                                    EmpCell { w: 0.12; val: model.hireDate      || "—" }
                                    Item {
                                        width: parent.width * 0.08; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12
                                            text: model.terminationDate || "—"
                                            font.family: "Montserrat"; font.pixelSize: 13
                                            color: model.terminationDate ? "#c97a2a" : "#8EB69B"
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Item {
                                        width: parent.width * 0.04; height: parent.height
                                        Rectangle {
                                            anchors.centerIn: parent; width: 28; height: 28; radius: 8
                                            color: delArea.containsMouse ? "#7a1a1a" : "#5c1010"
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Text { anchors.centerIn: parent; text: "✕"; color: "#DAF1DE"; font.pixelSize: 12 }
                                            MouseArea {
                                                id: delArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    deleteDialog.pendingId = model.employeeId
                                                    var name = model.lastName + " " + model.firstName
                                                    deleteDialog.show("Удалить сотрудника?", "«" + name + "»\nбудет удалён из системы.")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent; visible: empModel.count === 0
                            text: "Сотрудники не найдены"; font.family: "Montserrat"; font.pixelSize: 16; color: "#8EB69B"
                        }
                    }
                }
            }
        }
    }

    component EmpCell: Item {
        property real w: 0.1
        property string val: ""
        width: parent ? parent.width * w : 100; height: 52
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12
            text: val; font.family: "Montserrat"; font.pixelSize: 13; color: "#DAF1DE"; elide: Text.ElideRight
        }
    }

    ListModel { id: empModel }

    function _clearForm() {
        empFirstName.text  = ""; empLastName.text   = ""; empMiddleName.text = ""
        empEmail.text      = ""; empPhone.text      = ""
        empHireDate.text   = ""; empTermDate.text   = ""
        empPassSeries.text = ""; empPassNumber.text = ""
        empPositionCombo.currentIndex = 0
    }

    function _filterEmployees(text) {
        root._allEmployees = presenter.employees.filter(function(e) {
            if (text === "") return true
            var t = text.toLowerCase()
            var full = (e.lastName + " " + e.firstName + " " + e.middleName).toLowerCase()
            return full.includes(t) || (e.email || "").toLowerCase().includes(t)
        })
        _rebuildModel(root._allEmployees)
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
        empModel.clear()
        for (var i = 0; i < sorted.length; i++) empModel.append(sorted[i])
    }

    Component.onCompleted: { if (TokenManager.hasValidToken()) presenter.loadEmployees("") }

    function reload() { presenter.loadEmployees("") }
}
