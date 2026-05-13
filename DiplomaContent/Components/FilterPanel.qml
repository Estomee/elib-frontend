import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements
import DiplomaContent.Api

// ─────────────────────────────────────────────────────────────
// FilterPanel — панель фильтрации каталога книг
// Поля соответствуют BookFilter из GraphQL API
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    signal searchRequested(var filters)
    signal resetRequested()

    // ─── Справочные данные из БД ─────────────────────────────
    property var _genres:      []
    property var _languages:   []
    property var _typesOfWork: []

    // ─── Чтение текущих фильтров ──────────────────────────────
    function currentFilters() {
        return {
            titleContains:    searchField.text.trim(),
            author:           authorField.text.trim(),
            genre:            genreCombo.currentIndex  > 0 ? genreCombo.currentText  : "",
            language:         langCombo.currentIndex   > 0 ? langCombo.currentText   : "",
            typeOfWork:       typeCombo.currentIndex   > 0 ? typeCombo.currentText   : "",
            yearOfPublishing: yearField.text.trim() !== "" ? parseInt(yearField.text) : 0
        }
    }

    // ─── Debounce для текстовых полей (350 мс) ───────────────
    // Предотвращает шквал запросов при быстрой печати
    Timer {
        id: searchDebounce
        interval: 350
        repeat: false
        onTriggered: root.searchRequested(root.currentFilters())
    }

    // ─── Загрузка справочников из БД ─────────────────────────
    Component.onCompleted: {
        BookService.loadGenres(
            function(data) { root._genres = data || [] },
            function(msg)  { console.warn("[FilterPanel] genres:", msg) }
        )
        BookService.loadLanguages(
            function(data) { root._languages = data || [] },
            function(msg)  { console.warn("[FilterPanel] languages:", msg) }
        )
        BookService.loadTypesOfWork(
            function(data) { root._typesOfWork = data || [] },
            function(msg)  { console.warn("[FilterPanel] typesOfWork:", msg) }
        )
    }

    height: 70
    width: parent ? parent.width : 1200

    // ─── Фон панели ──────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#0B2B26"
        radius: 16
        border.color: "#051F20"
        border.width: 2
    }

    // ─── Поля фильтрации ─────────────────────────────────────
    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Поиск по названию — с debounce
        MainTextField {
            id: searchField
            width: 220; height: 46
            hint: "Поиск по названию"; hintTextSize: 12; mainTextSize: 13
            onTextChanged: searchDebounce.restart()
            Keys.onReturnPressed: { searchDebounce.stop(); root.searchRequested(root.currentFilters()) }
        }

        // Автор — с debounce
        MainTextField {
            id: authorField
            width: 170; height: 46
            hint: "Автор"; hintTextSize: 12; mainTextSize: 13
            onTextChanged: searchDebounce.restart()
        }

        // Жанр — из БД
        MainComboBox {
            id: genreCombo
            width: 160; height: 46
            textSize: 12; hint: "Жанр"
            model: ["Все жанры"].concat(root._genres.map(function(g) { return g.genre_name }))
            onActivated: root.searchRequested(root.currentFilters())
        }

        // Язык — из БД
        MainComboBox {
            id: langCombo
            width: 130; height: 46
            textSize: 12; hint: "Язык"
            model: ["Все"].concat(root._languages.map(function(l) { return l.lang_name }))
            onActivated: root.searchRequested(root.currentFilters())
        }

        // Тип произведения — из БД
        MainComboBox {
            id: typeCombo
            width: 150; height: 46
            textSize: 12; hint: "Тип"
            model: ["Все типы"].concat(root._typesOfWork.map(function(t) { return t.type_name }))
            onActivated: root.searchRequested(root.currentFilters())
        }

        // Год издания
        MainTextField {
            id: yearField
            width: 100; height: 46
            hint: "Год"; hintTextSize: 12; mainTextSize: 13
            validator: IntValidator { bottom: 1000; top: 2100 }
            Keys.onReturnPressed: { searchDebounce.stop(); root.searchRequested(root.currentFilters()) }
        }

        Item { width: 1 }

        // Кнопка "Найти"
        MainButton {
            width: 120; height: 46
            buttonText: "Найти"; buttonTextSize: 11
            onClicked: { searchDebounce.stop(); root.searchRequested(root.currentFilters()) }
        }

        // Кнопка "Сбросить"
        MainButton {
            width: 120; height: 46
            buttonText: "Сбросить"; buttonTextSize: 11
            onClicked: {
                searchDebounce.stop()
                searchField.text = ""
                authorField.text = ""
                yearField.text   = ""
                genreCombo.currentIndex = 0
                langCombo.currentIndex  = 0
                typeCombo.currentIndex  = 0
                root.resetRequested()
            }
        }
    }
}
