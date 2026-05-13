import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements

// ─────────────────────────────────────────────────────────────
// SingleChipSelector — компонент выбора одного значения с чипом
// Поддерживает выбор из существующих и создание нового элемента.
// Использование: язык книги (hasSecondField: true), тип произведения.
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    // ── Входные данные ────────────────────────────────────────
    // TODO: заполнять из GraphQL query (languages / typesOfWork)
    // Формат: [{ id: "1", displayName: "Русский", secondText: "ru" }]
    property var    availableItems:  []
    property string hint:            "Выберите из списка..."
    property string addButtonLabel:  "Добавить новый"
    property bool   hasSecondField:  false       // true для Language
    property string mainFieldHint:   "Название"
    property string secondFieldHint: "Код"

    // ── Выходные данные (читать при submit формы) ─────────────
    // TODO: передавать в GraphQL mutation:
    //   selectedId  → languageId / typeOfWorkId  (если !isNew)
    //   selectedName + selectedCode → newLanguage / newTypeOfWork (если isNew)
    property string selectedId:   ""
    property string selectedName: ""   // название выбранного/нового
    property string selectedCode: ""   // код (только для Language)
    property bool   isNew:        false

    // ── Внутреннее состояние ──────────────────────────────────
    property bool _hasSelection: selectedName !== ""
    property bool _showAddForm:  false

    height: _scsCol.implicitHeight

    // ── Сброс (вызывать при открытии формы / закрытии попапа) ─
    function reset() {
        selectedId   = ""
        selectedName = ""
        selectedCode = ""
        isNew        = false
        _showAddForm = false
        _newNameField.text = ""
        _newCodeField.text = ""
    }

    // ── Предзаполнение при редактировании ─────────────────────
    // TODO: вызывать с данными из GraphQL (language / typeOfWork книги)
    function preload(id, name, code) {
        reset()
        if (!name || name === "") return
        selectedId   = id   || ""
        selectedName = name
        selectedCode = code || ""
        isNew        = (!id || id === "")
    }

    // ─────────────────────────────────────────────────────────
    Column {
        id: _scsCol
        width: parent.width
        spacing: 8

        // ── Состояние: ничего не выбрано ──────────────────────
        Column {
            width: parent.width; spacing: 8
            visible: !root._hasSelection

            // Дропдаун существующих элементов
            MainComboBox {
                id: _existingCombo
                width: parent.width; height: 46
                hint: root.hint; textSize: 13

                // TODO: заменить на данные из GraphQL
                model: {
                    var names = ["— выбрать —"]
                    for (var i = 0; i < root.availableItems.length; i++)
                        names.push(root.availableItems[i].displayName)
                    return names
                }

                onActivated: {
                    if (currentIndex <= 0) return
                    var item = root.availableItems[currentIndex - 1]
                    root.selectedId   = item.id         || ""
                    root.selectedName = item.displayName
                    root.selectedCode = item.secondText || ""
                    root.isNew        = false
                    root._showAddForm = false
                    currentIndex = 0
                }
            }

            // Кнопка «Добавить новый»
            Rectangle {
                width: parent.width; height: 34; radius: 10
                color: _addNewArea.containsMouse ? "#163832" : "transparent"
                border.color: "#235347"; border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 12; spacing: 8
                    Text {
                        text: root._showAddForm ? "▲" : "+"
                        font.pixelSize: 14; color: "#8EB69B"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.addButtonLabel
                        font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: _addNewArea; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._showAddForm = !root._showAddForm
                }
            }

            // Форма нового элемента (разворачивается)
            Rectangle {
                width: parent.width
                height: root._showAddForm ? _addFormCol.implicitHeight + 24 : 0
                radius: 12; clip: true
                color: "#0B2B26"; border.color: "#235347"; border.width: 1
                visible: height > 0
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Column {
                    id: _addFormCol
                    width: parent.width - 24; x: 12; y: 12; spacing: 8

                    Row {
                        width: parent.width; spacing: 8

                        Column {
                            // Если второго поля нет — занять всю ширину
                            width: root.hasSecondField ? (parent.width - 8) * 0.65 : parent.width
                            spacing: 4
                            Text { text: "Название *"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                            MainTextField {
                                id: _newNameField; width: parent.width; height: 40
                                hint: root.mainFieldHint; hintTextSize: 11; mainTextSize: 12
                            }
                        }

                        Column {
                            width: (parent.width - 8) * 0.35; spacing: 4
                            visible: root.hasSecondField
                            Text { text: "Код *"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                            MainTextField {
                                id: _newCodeField; width: parent.width; height: 40
                                hint: root.secondFieldHint; hintTextSize: 11; mainTextSize: 12; maximumLength: 5
                            }
                        }
                    }

                    MainButton {
                        width: 120; height: 36; buttonText: "Добавить"; buttonTextSize: 10
                        onClicked: {
                            if (_newNameField.text.trim() === "") return
                            if (root.hasSecondField && _newCodeField.text.trim() === "") return
                            root.selectedId   = ""
                            root.selectedName = _newNameField.text.trim()
                            root.selectedCode = root.hasSecondField ? _newCodeField.text.trim() : ""
                            root.isNew        = true
                            root._showAddForm = false
                        }
                    }

                    Item { width: 1; height: 2 }
                }
            }
        }

        // ── Состояние: элемент выбран — показываем чип ────────
        Row {
            visible: root._hasSelection
            spacing: 0

            Rectangle {
                id: _scsChipRect
                height: 30
                width: _scsChipLabel.implicitWidth + 36
                radius: 8
                color:        root.isNew ? "#1e3d14" : "#235347"
                border.color: root.isNew ? "#4a7a28" : "#8EB69B"; border.width: 1

                // Анимация удаления чипа
                SequentialAnimation {
                    id: _scsRemoveAnim
                    ParallelAnimation {
                        NumberAnimation { target: _scsChipRect; property: "opacity"; from: 1.0; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                        NumberAnimation { target: _scsChipRect; property: "scale";   from: 1.0; to: 0.85; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: {
                        root.selectedId = ""; root.selectedName = ""; root.selectedCode = ""; root.isNew = false
                        _scsChipRect.opacity = 1.0; _scsChipRect.scale = 1.0
                    }}
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 10; anchors.rightMargin: 6; spacing: 6

                    Text {
                        id: _scsChipLabel
                        text: {
                            var label = root.selectedName
                            if (root.hasSecondField && root.selectedCode !== "")
                                label += " (" + root.selectedCode + ")"
                            if (root.isNew) label += " (новый)"
                            return label
                        }
                        font.family: "Montserrat"; font.pixelSize: 11; color: "#DAF1DE"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Кнопка удаления с анимацией
                    Rectangle {
                        width: 16; height: 16; radius: 4
                        color: _scsRemoveArea.containsMouse ? "#7a1a1a" : "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 14; color: "#DAF1DE" }
                        MouseArea {
                            id: _scsRemoveArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: _scsRemoveAnim.start()
                        }
                    }
                }
            }
        }
    }
}
