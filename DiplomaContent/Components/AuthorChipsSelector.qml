import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements

// ─────────────────────────────────────────────────────────────
// AuthorChipsSelector — компонент множественного выбора авторов
// Поддерживает: выбор существующего автора из списка,
// добавление нового автора через встроенную форму,
// удаление авторов через чип-кнопки (×)
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    // ─── Входные данные ──────────────────────────────────────
    // Формат: [{ author_id: 1, first_name: "Лев", last_name: "Толстой" }]
    property var availableAuthors: []

    // ─── Выходные данные (читать при submit формы) ───────────
    // TODO: передавать в GraphQL mutation createBook/updateBook
    property var selectedAuthorIds: []   // ID существующих авторов → authorIds: [Int!]!
    property var newAuthors: []          // данные новых авторов    → newAuthors: [NewAuthorInput!]

    // ─── Внутреннее состояние ────────────────────────────────
    property var _selectedItems: []      // [{authorId, displayName, isNew, newIdx?}]
    property bool _showNewForm: false

    height: _mainCol.implicitHeight

    // ─── Сброс компонента (вызывать при открытии формы) ──────
    function reset() {
        _selectedItems   = []
        selectedAuthorIds = []
        newAuthors        = []
        _showNewForm      = false
        _newFirstName.text  = ""
        _newLastName.text   = ""
        _newMiddleName.text = ""
        _newYearField.text  = ""
    }

    // ─── Предзаполнение при редактировании (передать список) ─
    // TODO: вызывать при открытии попапа редактирования книги
    // authors — массив { authorId, firstName, lastName, middleName }
    function preload(authors) {
        reset()
        for (var i = 0; i < authors.length; i++) {
            var a = authors[i]
            var name = a.first_name + " " + a.last_name
            _addExisting(a.author_id, name)
        }
    }

    // ─── Приватные методы ────────────────────────────────────
    function _addExisting(authorId, displayName) {
        for (var i = 0; i < _selectedItems.length; i++)
            if (_selectedItems[i].authorId === authorId) return
        var items = _selectedItems.slice()
        items.push({ authorId: authorId, displayName: displayName, isNew: false })
        _selectedItems = items
        var ids = selectedAuthorIds.slice()
        ids.push(authorId)
        selectedAuthorIds = ids
    }

    function _addNew(firstName, lastName, middleName, yearOfBirth) {
        var shortName = lastName + " " + firstName.charAt(0) + "."
                      + (middleName ? " " + middleName.charAt(0) + "." : "")
        var items = _selectedItems.slice()
        var newIdx = newAuthors.length
        items.push({ authorId: "new_" + newIdx, displayName: shortName + " (новый)", isNew: true, newIdx: newIdx })
        _selectedItems = items
        var na = newAuthors.slice()
        na.push({ first_name: firstName, last_name: lastName,
                  year_of_birth: parseInt(yearOfBirth) || 0 })
        newAuthors = na
    }

    function _removeItem(idx) {
        var item = _selectedItems[idx]
        var items = _selectedItems.slice()
        items.splice(idx, 1)
        _selectedItems = items

        if (!item.isNew) {
            selectedAuthorIds = selectedAuthorIds.filter(function(id) { return id !== item.authorId })
        } else {
            var na = newAuthors.slice()
            na.splice(item.newIdx, 1)
            newAuthors = na
            // Пересчитать newIdx у оставшихся новых авторов
            var counter = 0
            for (var i = 0; i < _selectedItems.length; i++) {
                if (_selectedItems[i].isNew) {
                    var updated = _selectedItems.slice()
                    updated[i] = JSON.parse(JSON.stringify(_selectedItems[i]))
                    updated[i].newIdx = counter++
                    _selectedItems = updated
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────
    Column {
        id: _mainCol
        width: parent.width
        spacing: 8

        // ─ Дропдаун существующих авторов ─────────────────────
        MainComboBox {
            id: _authorCombo
            width: parent.width
            height: 46
            hint: "Выберите автора из списка..."
            textSize: 13

            model: {
                var names = ["— выберите —"]
                for (var i = 0; i < root.availableAuthors.length; i++) {
                    var a = root.availableAuthors[i]
                    names.push(a.first_name + " " + a.last_name)
                }
                return names
            }

            onActivated: {
                if (currentIndex <= 0) return
                var author = root.availableAuthors[currentIndex - 1]
                var name   = author.first_name + " " + author.last_name
                root._addExisting(author.author_id, name)
                currentIndex = 0
            }
        }

        // ─ Чипы выбранных авторов ────────────────────────────
        Flow {
            width: parent.width
            spacing: 6
            visible: root._selectedItems.length > 0

            Repeater {
                model: root._selectedItems

                delegate: Rectangle {
                    id: _chipRect
                    height: 30
                    width: _chipLabel.implicitWidth + 36
                    radius: 8
                    color:        modelData.isNew ? "#1e3d14" : "#235347"
                    border.color: modelData.isNew ? "#4a7a28" : "#8EB69B"
                    border.width: 1

                    // Анимация удаления чипа
                    property bool _removing: false
                    property int  _capturedIndex: 0   // захватываем index в момент клика

                    SequentialAnimation {
                        id: _chipRemoveAnim
                        ParallelAnimation {
                            NumberAnimation { target: _chipRect; property: "opacity"; from: 1.0; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                            NumberAnimation { target: _chipRect; property: "scale";   from: 1.0; to: 0.85; duration: 150; easing.type: Easing.InCubic }
                        }
                        onStopped: {
                            if (_chipRect._removing) {
                                _chipRect._removing = false
                                root._removeItem(_chipRect._capturedIndex)
                            }
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        anchors.leftMargin:  10
                        anchors.rightMargin: 6
                        spacing: 6

                        Text {
                            id: _chipLabel
                            text: modelData.displayName
                            font.family: "Montserrat"; font.pixelSize: 11
                            color: "#DAF1DE"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Кнопка удаления с анимацией
                        Rectangle {
                            width: 16; height: 16; radius: 4
                            color: _removeArea.containsMouse ? "#7a1a1a" : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "×"; font.pixelSize: 14; color: "#DAF1DE"
                            }

                            MouseArea {
                                id: _removeArea
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    _chipRect._capturedIndex = index
                                    _chipRect._removing = true
                                    _chipRemoveAnim.start()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─ Кнопка «Добавить нового автора» ───────────────────
        Rectangle {
            width: parent.width; height: 34
            radius: 10
            color:        _addNewArea.containsMouse ? "#163832" : "transparent"
            border.color: "#235347"; border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: 12
                spacing: 8

                Text {
                    text: root._showNewForm ? "▲" : "+"
                    font.pixelSize: 14; color: "#8EB69B"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Добавить нового автора"
                    font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: _addNewArea
                anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root._showNewForm = !root._showNewForm
            }
        }

        // ─ Форма нового автора (разворачивается) ─────────────
        Rectangle {
            width: parent.width
            height: root._showNewForm ? _newFormCol.implicitHeight + 24 : 0
            radius: 12; clip: true
            color: "#0B2B26"; border.color: "#235347"; border.width: 1
            visible: height > 0
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Column {
                id: _newFormCol
                width: parent.width - 24; x: 12; y: 12
                spacing: 8

                Row {
                    width: parent.width; spacing: 8

                    Column {
                        width: (parent.width - 8) / 2; spacing: 4
                        Text { text: "Фамилия *"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                        MainTextField { id: _newLastName;  width: parent.width; height: 40; hint: "Фамилия";  hintTextSize: 11; mainTextSize: 12 }
                    }
                    Column {
                        width: (parent.width - 8) / 2; spacing: 4
                        Text { text: "Имя *"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                        MainTextField { id: _newFirstName; width: parent.width; height: 40; hint: "Имя";      hintTextSize: 11; mainTextSize: 12 }
                    }
                }

                Row {
                    width: parent.width; spacing: 8

                    Column {
                        width: (parent.width - 8) / 2; spacing: 4
                        Text { text: "Отчество"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                        MainTextField { id: _newMiddleName; width: parent.width; height: 40; hint: "Необязательно"; hintTextSize: 11; mainTextSize: 12 }
                    }
                    Column {
                        width: (parent.width - 8) / 2; spacing: 4
                        Text { text: "Год рождения *"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                        MainTextField {
                            id: _newYearField; width: parent.width; height: 40
                            hint: "Год"; hintTextSize: 11; mainTextSize: 12
                            validator: IntValidator { bottom: 1900; top: 2010 }
                        }
                    }
                }

                MainButton {
                    width: 140; height: 36
                    buttonText: "Добавить"; buttonTextSize: 10
                    onClicked: {
                        if (_newLastName.text.trim() === "" || _newFirstName.text.trim() === "") return
                        root._addNew(_newFirstName.text.trim(), _newLastName.text.trim(),
                                     _newMiddleName.text.trim(), _newYearField.text.trim())
                        _newFirstName.text  = ""
                        _newLastName.text   = ""
                        _newMiddleName.text = ""
                        _newYearField.text  = ""
                        root._showNewForm   = false
                    }
                }

                Item { width: 1; height: 2 }
            }
        }
    }
}
