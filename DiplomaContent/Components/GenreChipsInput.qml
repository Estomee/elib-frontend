import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements

// ─────────────────────────────────────────────────────────────
// GenreChipsInput — ввод жанров: выбор из списка + ввод вручную
// API: genres (строка "Роман, Детектив"), reset(), loadFromString(str)
// При передаче availableGenres показывает выпадающий список
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    // ── Публичный API ─────────────────────────────────────────
    // TODO: при подключении backend — заполнять из GraphQL query genres()
    property var    availableGenres: []   // [{genreId, genreName}]
    property string genres: ""            // computed comma-separated names; читать при submit
    property var    selectedIds: []       // computed genre ID array (id > 0); читать при submit
    property var    newGenreNames: []     // computed array of manually typed names (id == 0)

    height: _gcCol.implicitHeight

    // ── Сброс ─────────────────────────────────────────────────
    function reset() {
        _gcModel.clear()
        _gcInput.text  = ""
        _showNewForm   = false
        genres         = ""
        selectedIds    = []
        newGenreNames  = []
    }

    // ── Предзаполнение из строки "Роман, Детектив, ..." ───────
    function loadFromString(str) {
        reset()
        if (!str || str.trim() === "") return
        var parts = str.split(/[,;]/)
        for (var i = 0; i < parts.length; i++) {
            var g = parts[i].trim()
            if (g !== "") _addGenreByName(g)
        }
    }

    // ── Предзаполнение из массива [{genre_id, genre_name}] ───
    function preloadFromArray(arr) {
        reset()
        if (!arr) return
        for (var i = 0; i < arr.length; i++)
            _addGenreById(arr[i].genre_id, arr[i].genre_name)
    }

    property bool _showNewForm: false    // разворачивает форму добавления нового жанра

    // ── Внутренние ────────────────────────────────────────────
    ListModel { id: _gcModel }

    function _addGenreByName(name) {
        if (!name || name.trim() === "") return
        var n = name.trim()
        for (var j = 0; j < _gcModel.count; j++) {
            if (_gcModel.get(j).name.toLowerCase() === n.toLowerCase()) return
        }
        _gcModel.append({ name: n, genreId: 0 })
        _syncGenres()
    }

    function _addGenreById(id, name) {
        if (!name || name.trim() === "") return
        var n = name.trim()
        for (var j = 0; j < _gcModel.count; j++) {
            if (_gcModel.get(j).name.toLowerCase() === n.toLowerCase()) return
        }
        _gcModel.append({ name: n, genreId: id })
        _syncGenres()
    }

    function _addGenre() {
        _addGenreByName(_gcInput.text.trim())
        _gcInput.text = ""
    }

    function _syncGenres() {
        var names    = []
        var ids      = []
        var newNames = []
        for (var i = 0; i < _gcModel.count; i++) {
            var item = _gcModel.get(i)
            names.push(item.name)
            if (item.genreId > 0)
                ids.push(item.genreId)
            else
                newNames.push(item.name)
        }
        genres        = names.join(", ")
        selectedIds   = ids
        newGenreNames = newNames
    }

    // ─────────────────────────────────────────────────────────
    Column {
        id: _gcCol
        width: parent.width; spacing: 8

        // ── Чипы выбранных жанров ────────────────────────────
        Flow {
            width: parent.width; spacing: 6
            visible: _gcModel.count > 0

            Repeater {
                model: _gcModel

                delegate: Rectangle {
                    id: _gcChip
                    property int _capturedIdx: 0
                    height: 28; radius: 8
                    width: _gcLabel.implicitWidth + 32
                    color: "#235347"; border.color: "#8EB69B"; border.width: 1

                    SequentialAnimation {
                        id: _gcRemoveAnim
                        ParallelAnimation {
                            NumberAnimation { target: _gcChip; property: "opacity"; from: 1.0; to: 0.0; duration: 130; easing.type: Easing.InCubic }
                            NumberAnimation { target: _gcChip; property: "scale";   from: 1.0; to: 0.85; duration: 130; easing.type: Easing.InCubic }
                        }
                        onStopped: {
                            _gcChip.opacity = 1.0; _gcChip.scale = 1.0
                            _gcModel.remove(_gcChip._capturedIdx)
                            root._syncGenres()
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 10
                        spacing: 6

                        Text {
                            id: _gcLabel
                            text: model.name
                            font.family: "Montserrat"; font.pixelSize: 11; color: "#DAF1DE"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 14; height: 14; radius: 3
                            color: _gcX.containsMouse ? "#7a1a1a" : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 13; color: "#DAF1DE" }
                            MouseArea {
                                id: _gcX; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { _gcChip._capturedIdx = index; _gcRemoveAnim.start() }
                            }
                        }
                    }
                }
            }
        }

        // ── Кнопка-переключатель панели добавления ────────────
        Item {
            width: parent.width; height: 36

            Rectangle {
                width: _gcToggleRow.implicitWidth + 24; height: 34; radius: 10
                color: _gcToggleArea.containsMouse ? "#163832" : "transparent"
                border.color: "#235347"; border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    id: _gcToggleRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 12
                    spacing: 8

                    Text {
                        text: root._showNewForm ? "▲" : "+"
                        font.pixelSize: 14; color: "#8EB69B"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Добавить жанр"
                        font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: _gcToggleArea; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._showNewForm = !root._showNewForm
                }
            }
        }

        // ── Раскрывающаяся панель: dropdown + ввод нового жанра
        Rectangle {
            width: parent.width
            height: root._showNewForm ? _gcPanelCol.implicitHeight + 20 : 0
            clip: true; color: "#0B2B26"; radius: 12
            border.color: "#235347"; border.width: 1
            visible: height > 0
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Column {
                id: _gcPanelCol
                width: parent.width - 24; x: 12; y: 10; spacing: 8

                // Выпадающий список (только если есть справочник)
                MainComboBox {
                    id: _genreCombo
                    width: parent.width; height: 42
                    visible: root.availableGenres.length > 0
                    hint: "Выбрать жанр из списка..."
                    textSize: 12

                    model: {
                        var names = ["— выберите жанр —"]
                        for (var i = 0; i < root.availableGenres.length; i++)
                            names.push(root.availableGenres[i].genre_name)
                        return names
                    }

                    onActivated: {
                        if (currentIndex <= 0) return
                        var genre = root.availableGenres[currentIndex - 1]
                        root._addGenreById(genre.genre_id, genre.genre_name)
                        currentIndex = 0
                        root._showNewForm = false
                    }
                }

                // Ввод нового жанра вручную
                Row {
                    width: parent.width; height: 42; spacing: 8

                    MainTextField {
                        id: _gcInput
                        width: parent.width - 110; height: 42
                        hint: "Название нового жанра..."; hintTextSize: 12; mainTextSize: 13
                        Keys.onReturnPressed: { root._addGenre(); root._showNewForm = false }
                        Keys.onEnterPressed:  { root._addGenre(); root._showNewForm = false }
                    }

                    MainButton {
                        width: 102; height: 42; buttonText: "Добавить"; buttonTextSize: 10
                        onClicked: { root._addGenre(); root._showNewForm = false }
                    }
                }

                Item { width: 1; height: 2 }
            }
        }
    }
}
