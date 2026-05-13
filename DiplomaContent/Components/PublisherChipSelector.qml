import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements

// ─────────────────────────────────────────────────────────────
// PublisherChipSelector — выбор одного издательства с чипом.
// Поддерживает выбор существующего из списка или ввод нового.
// API:
//   availablePublishers — [{publisherId, name}]
//   selectedPublisherId — ID существующего (0 если не выбрано / новое)
//   newPublisherName    — название нового издательства (если isNew)
//   isNew               — true когда введено новое название
//   selectedName        — отображаемое название выбранного
//   reset()
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    property var    availablePublishers:  []
    property int    selectedPublisherId:  0
    property string newPublisherName:     ""
    property bool   isNew:               false
    property string selectedName:        ""

    property bool _hasSelection: selectedName !== ""
    property bool _showNewForm:  false

    height: _col.implicitHeight

    function reset() {
        selectedPublisherId = 0
        newPublisherName    = ""
        isNew               = false
        selectedName        = ""
        _showNewForm        = false
        _newNameField.text  = ""
        _existingCombo.currentIndex = 0
    }

    function preload(id, name) {
        reset()
        if (!name || name === "") return
        selectedPublisherId = id || 0
        newPublisherName    = (id > 0) ? "" : name
        isNew               = (id <= 0)
        selectedName        = name
    }

    function _selectExisting(publisherId, name) {
        selectedPublisherId = publisherId
        newPublisherName    = ""
        isNew               = false
        selectedName        = name
        _showNewForm        = false
    }

    function _addNew(name) {
        selectedPublisherId = 0
        newPublisherName    = name
        isNew               = true
        selectedName        = name + " (новое)"
        _showNewForm        = false
    }

    // ─────────────────────────────────────────────────────────
    Column {
        id: _col
        width: parent.width
        spacing: 8

        // ── Ввод (скрыт когда уже выбрано) ───────────────────
        Column {
            width: parent.width
            spacing: 8
            visible: !root._hasSelection

            // Дропдаун существующих
            MainComboBox {
                id: _existingCombo
                width: parent.width; height: 46
                hint: "Выберите издательство из списка..."
                textSize: 13

                model: {
                    var names = ["— выберите —"]
                    for (var i = 0; i < root.availablePublishers.length; i++)
                        names.push(root.availablePublishers[i].name)
                    return names
                }

                onActivated: {
                    if (currentIndex <= 0) return
                    var pub = root.availablePublishers[currentIndex - 1]
                    root._selectExisting(pub.publisher_id, pub.name)
                    currentIndex = 0
                }
            }

            // Кнопка «Добавить новое»
            Rectangle {
                width: parent.width; height: 34; radius: 10
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
                        text: "Добавить новое издательство"
                        font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: _addNewArea; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._showNewForm = !root._showNewForm
                }
            }

            // Форма нового издательства
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

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Название *"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                        MainTextField {
                            id: _newNameField
                            width: parent.width; height: 40
                            hint: "Название издательства"; hintTextSize: 11; mainTextSize: 12
                            maximumLength: 100
                            Keys.onReturnPressed: _tryAddNew()
                        }
                    }

                    MainButton {
                        width: 140; height: 36
                        buttonText: "Добавить"; buttonTextSize: 10
                        onClicked: _tryAddNew()
                    }

                    Item { width: 1; height: 2 }
                }
            }
        }

        // ── Чип выбранного издательства ───────────────────────
        Row {
            visible: root._hasSelection
            spacing: 0

            Rectangle {
                id: _chipRect
                height: 30
                width: _chipLabel.implicitWidth + 36
                radius: 8
                color:        root.isNew ? "#1e3d14" : "#235347"
                border.color: root.isNew ? "#4a7a28" : "#8EB69B"
                border.width: 1

                SequentialAnimation {
                    id: _removeAnim
                    ParallelAnimation {
                        NumberAnimation { target: _chipRect; property: "opacity"; from: 1.0; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                        NumberAnimation { target: _chipRect; property: "scale";   from: 1.0; to: 0.85; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: {
                        _chipRect.opacity = 1.0; _chipRect.scale = 1.0
                        root.selectedPublisherId = 0
                        root.newPublisherName    = ""
                        root.isNew               = false
                        root.selectedName        = ""
                    }}
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 10; anchors.rightMargin: 6
                    spacing: 6

                    Text {
                        id: _chipLabel
                        text: root.selectedName
                        font.family: "Montserrat"; font.pixelSize: 11; color: "#DAF1DE"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 16; height: 16; radius: 4
                        color: _xArea.containsMouse ? "#7a1a1a" : "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 14; color: "#DAF1DE" }
                        MouseArea {
                            id: _xArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: _removeAnim.start()
                        }
                    }
                }
            }
        }
    }

    function _tryAddNew() {
        var name = _newNameField.text.trim()
        if (name === "") return
        root._addNew(name)
        _newNameField.text = ""
    }
}
