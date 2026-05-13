// Admin book management view with editable table, cover/file replacement, and sort/filter support.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import DiplomaContent.UI_Elements
import DiplomaContent.Presenters
import DiplomaContent.Components
import DiplomaContent.Network
import DiplomaContent.Api

Item {
    id: root

    signal uploadRequested()

    property string _sortCol: ""
    property bool   _sortAsc: true
    property var    _allBooks: []

    function reload() {
        presenter.loadBooks("")
        presenter.loadReferenceData()
    }

    ManageBooksPresenter {
        id: presenter

        onBooksLoaded: {
            root._allBooks = presenter.books
            _rebuildModel(root._allBooks)
        }
        onBookDeleted: {
            statusText.show("Книга успешно удалена", "success")
            presenter.loadBooks("")
        }
        onBookUpdated: {
            statusText.show("Изменения сохранены", "success")
            presenter.loadBooks("")
        }
        onOperationFailed: function(msg) {
            statusText.show(msg, "error")
        }
    }

    Timer {
        id: coverLoadTimer
        interval: 120
        repeat: false
        property string pendingUrl: ""
        onTriggered: editCoverPreview.source = pendingUrl
    }

    FileDialog {
        id: editCoverDialog
        title: "Выберите новую обложку"
        nameFilters: ["Изображения (*.jpg *.jpeg *.png)"]
        onAccepted: {
            editCoverPreview.source = selectedFile
            var p = selectedFile.toString().replace("file:///", "")
            editPopup._newCoverPath = p
            editPopup._newCoverMime = p.toLowerCase().indexOf(".png") >= 0 ? "image/png" : "image/jpeg"
        }
    }

    FileDialog {
        id: editBookFileDialog
        title: "Выберите новый файл книги"
        nameFilters: ["Книги (*.pdf *.epub)"]
        onAccepted: {
            var p = selectedFile.toString().replace("file:///", "")
            editPopup._newBookFilePath = p
            var fn = p.split("/").pop().split("\\").pop()
            editBookFileNameText.text = fn
        }
    }

    ConfirmDialog {
        id: deleteDialog
        title: "Удалить книгу?"
        confirmText: "Удалить"
        confirmType: "danger"
        property string pendingId: ""
        onConfirmed: presenter.deleteBook(pendingId)
    }

    NotificationToast {
        id: statusText
        anchors.top: root.top
        anchors.topMargin: 10
        anchors.horizontalCenter: root.horizontalCenter
    }

    Item {
        id: editPopup
        visible: false
        anchors.fill: parent
        z: 200

        property string editingBookId:    ""
        property string _newCoverPath:    ""
        property string _newCoverMime:    ""
        property string _newBookFilePath: ""

        onVisibleChanged: {
            if (visible) { editFadeAnim.restart(); editScaleAnim.restart() }
            else {
                editLangChip.reset(); editTypeChip.reset()
                editGenreChips.reset(); editPublisherChip.reset()
                _newBookFilePath = ""
                editBookFileNameText.text = ""
            }
        }

        Rectangle {
            anchors.fill: parent; color: "#000000"; opacity: 0.6
            MouseArea { anchors.fill: parent; onClicked: editPopup.visible = false }
        }

        Rectangle {
            id: editCard
            anchors.centerIn: parent
            width: 560
            height: Math.min(editCardScroll.contentHeight + 80, root.height * 0.90)
            color: "#0B2B26"; radius: 20
            border.color: "#235347"; border.width: 2

            NumberAnimation { id: editFadeAnim;  target: editCard; property: "opacity"; from: 0; to: 1;    duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { id: editScaleAnim; target: editCard; property: "scale";   from: 0.90; to: 1; duration: 260; easing.type: Easing.OutBack }

            Text {
                id: editCardTitle
                anchors.top: parent.top; anchors.topMargin: 22
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Редактировать книгу"
                font.family: "Montserrat"; font.pixelSize: 18; font.bold: true; color: "#DAF1DE"
            }

            ScrollView {
                id: editCardScroll
                anchors.top: editCardTitle.bottom; anchors.topMargin: 16
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: editBtnRow.top; anchors.bottomMargin: 12
                clip: true

                Column {
                    id: editCol
                    width: editCard.width - 48
                    x: 24
                    spacing: 14

                    Column {
                        width: parent.width; spacing: 8

                        Text { text: "Обложка"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }

                        Row {
                            spacing: 16

                            Rectangle {
                                width: 110; height: 145; radius: 10
                                color: "#163832"; border.color: "#235347"; border.width: 2
                                clip: true

                                Image {
                                    id: editCoverPreview
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    mipmap: true
                                    asynchronous: true
                                    cache: false
                                    property bool everLoaded: false
                                    visible: everLoaded || status === Image.Ready
                                    opacity: (status === Image.Ready || everLoaded) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 180 } }
                                    onStatusChanged: if (status === Image.Ready) everLoaded = true
                                    onSourceChanged: everLoaded = false
                                }

                                Column {
                                    anchors.centerIn: parent; spacing: 6
                                    visible: editCoverPreview.source.toString() === ""
                                          || editCoverPreview.status === Image.Error
                                          || editCoverPreview.status === Image.Null
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Нет"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "обложки"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B"; opacity: 0.6 }
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 10

                                MainButton {
                                    width: 160; height: 40
                                    buttonText: "Изменить обложку"; buttonTextSize: 10
                                    onClicked: editCoverDialog.open()
                                }
                                Text {
                                    visible: editPopup._newCoverPath !== ""
                                    text: "Новый файл выбран"
                                    font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B"
                                    width: 160; wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width; spacing: 8

                        Text { text: "Файл книги"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }

                        Row {
                            width: parent.width; spacing: 12

                            Column {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 6

                                Text {
                                    id: editCurrentFileText
                                    font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B"; opacity: 0.8
                                    width: 200; elide: Text.ElideMiddle
                                }

                                Text {
                                    id: editBookFileNameText
                                    visible: text !== ""
                                    font.family: "Montserrat"; font.pixelSize: 11; color: "#DAF1DE"
                                    width: 200; elide: Text.ElideMiddle
                                }
                            }

                            MainButton {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 160; height: 40
                                buttonText: "Заменить файл"; buttonTextSize: 10
                                onClicked: editBookFileDialog.open()
                            }
                        }
                    }

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Название *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        MainTextField { id: editTitleField; width: parent.width; height: 50; hint: "Название"; hintTextSize: 13; mainTextSize: 14 }
                    }

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Авторы *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        AuthorChipsSelector {
                            id: editAuthorChips
                            width: parent.width
                            availableAuthors: presenter.availableAuthors
                        }
                    }

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Описание"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        Rectangle {
                            width: parent.width; height: 80; radius: 14
                            color: "#235347"; border.color: "#051F20"; border.width: 2
                            ScrollView {
                                anchors.fill: parent; anchors.margins: 10
                                TextArea {
                                    id: editDescField
                                    font.family: "Montserrat"; font.pixelSize: 13; color: "#DAF1DE"
                                    background: null; wrapMode: TextArea.Wrap
                                    placeholderText: "Описание..."; placeholderTextColor: "#8EB69B"
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Жанры"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        GenreChipsInput {
                            id: editGenreChips
                            width: parent.width
                            availableGenres: presenter.availableGenres
                        }
                    }

                    Row {
                        width: parent.width; spacing: 12

                        Column {
                            width: (parent.width - 12) * 0.6; spacing: 4
                            Text { text: "ISBN"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            MainTextField {
                                id: editIsbnField
                                width: parent.width; height: 46
                                hint: "978-X-XXXXXX-XX-X"; hintTextSize: 12; mainTextSize: 13
                                maximumLength: 17
                                property bool _fmt: false
                                onTextChanged: {
                                    if (_fmt) return; _fmt = true
                                    var d = text.replace(/[^0-9]/g, "").slice(0, 13)
                                    var f = d.slice(0, Math.min(3, d.length))
                                    if (d.length > 3)  f += "-" + d.slice(3, 4)
                                    if (d.length > 4)  f += "-" + d.slice(4, 10)
                                    if (d.length > 10) f += "-" + d.slice(10, 12)
                                    if (d.length > 12) f += "-" + d.slice(12, 13)
                                    text = f; _fmt = false
                                }
                            }
                        }
                        Column {
                            width: (parent.width - 12) * 0.4; spacing: 4
                            Text { text: "Год издания *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            MainTextField { id: editYearField; width: parent.width; height: 46; hint: "Год"; hintTextSize: 13; mainTextSize: 13; validator: IntValidator { bottom: 1000; top: 2100 } }
                        }
                    }

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Язык книги *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        SingleChipSelector {
                            id: editLangChip
                            width: parent.width
                            hasSecondField: true
                            hint: "Выберите язык..."
                            mainFieldHint: "Русский"
                            secondFieldHint: "ru"
                            addButtonLabel: "Добавить новый язык"
                            availableItems: presenter.availableLanguages.map(function(l) {
                                return { id: l.lang_id, displayName: l.lang_name, secondText: l.lang_code }
                            })
                        }
                    }

                    Column {
                        width: parent.width; spacing: 4
                        Text { text: "Тип произведения *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        SingleChipSelector {
                            id: editTypeChip
                            width: parent.width
                            hasSecondField: false
                            hint: "Выберите тип произведения..."
                            mainFieldHint: "Роман, Поэма, Драма..."
                            addButtonLabel: "Добавить новый тип"
                            availableItems: presenter.availableTypesOfWork.map(function(t) {
                                return { id: t.work_id, displayName: t.type_name }
                            })
                        }
                    }

                    Row {
                        width: parent.width; spacing: 12

                        Column {
                            width: (parent.width - 12) * 0.6; spacing: 4
                            Text { text: "Издатель *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            PublisherChipSelector {
                                id: editPublisherChip
                                width: parent.width
                                availablePublishers: presenter.availablePublishers
                            }
                        }
                        Column {
                            width: (parent.width - 12) * 0.4; spacing: 4
                            Text { text: "Страниц"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            MainTextField { id: editPagesField; width: parent.width; height: 46; hint: "Кол-во"; hintTextSize: 12; mainTextSize: 13; validator: IntValidator { bottom: 1; top: 9999 } }
                        }
                    }

                    Item { width: 1; height: 4 }
                }
            }

            Row {
                id: editBtnRow
                anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                MainButton {
                    width: 240; height: 48
                    buttonText: "Сохранить"; buttonTextSize: 11
                    onClicked: {
                        if (editTitleField.text.trim() === "") return
                        presenter.updateBook(editPopup.editingBookId, {
                            title:         editTitleField.text,
                            description:   editDescField.text,
                            isbn:          editIsbnField.text,
                            year:          parseInt(editYearField.text)  || 0,
                            pages:         parseInt(editPagesField.text) || 0,
                            publisherId:   editPublisherChip.selectedPublisherId,
                            languageId:    editLangChip.isNew  ? 0 : parseInt(editLangChip.selectedId)  || 0,
                            typeOfWorkId:  editTypeChip.isNew  ? 0 : parseInt(editTypeChip.selectedId)  || 0,
                            authorIds:     editAuthorChips.selectedAuthorIds,
                            genreIds:      editGenreChips.selectedIds,
                            newGenreNames:   editGenreChips.newGenreNames,
                            newCoverPath:    editPopup._newCoverPath,
                            coverMimeType:   editPopup._newCoverMime,
                            newBookFilePath: editPopup._newBookFilePath
                        })
                        editPopup.visible = false
                    }
                }
                MainButton {
                    width: 180; height: 48
                    buttonText: "Отмена"; buttonTextSize: 11
                    onClicked: editPopup.visible = false
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        Item {
            width: parent.width; height: 44
            HeadingText { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Управление книгами"; size: 26 }
            MainButton {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                width: 180; height: 44
                buttonText: "+ Загрузить книгу"; buttonTextSize: 11
                onClicked: uploadRequested()
            }
        }

        MainTextField {
            id: searchField
            width: 380; height: 46
            hint: "Поиск по названию или автору..."
            hintTextSize: 13; mainTextSize: 13
            onTextChanged: _filterBooks(text)
        }

        Rectangle {
            width: parent.width
            height: parent.height - 44 - 60 - 46 - 40
            color: "#163832"; radius: 16
            border.color: "#235347"; border.width: 1
            clip: true

            Column {
                anchors.fill: parent

                Rectangle {
                    width: parent.width; height: 44
                    color: "#0B2B26"; radius: 16
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 16; color: parent.color }

                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [
                                { label: "Название",  w: 0.26, key: "title"     },
                                { label: "Авторы",    w: 0.18, key: "author"    },
                                { label: "Жанр",      w: 0.12, key: "genre"     },
                                { label: "Год",       w: 0.07, key: "year"      },
                                { label: "Язык",      w: 0.09, key: "language"  },
                                { label: "Тип",       w: 0.10, key: "typeOfWork"},
                                { label: "Издатель",  w: 0.14, key: "publisher" },
                                { label: "",          w: 0.04, key: ""          }
                            ]
                            delegate: Item {
                                width: parent.width * modelData.w; height: parent.height
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left; anchors.leftMargin: 12; spacing: 4
                                    Text { text: modelData.label; font.family: "Montserrat"; font.pixelSize: 12; font.bold: true; color: modelData.key !== "" && root._sortCol === modelData.key ? "#DAF1DE" : "#8EB69B" }
                                    Text { visible: modelData.key !== "" && root._sortCol === modelData.key; text: root._sortAsc ? "↑" : "↓"; font.pixelSize: 11; color: "#DAF1DE" }
                                }
                                MouseArea {
                                    anchors.fill: parent; enabled: modelData.key !== ""
                                    cursorShape: modelData.key !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (root._sortCol === modelData.key) root._sortAsc = !root._sortAsc
                                        else { root._sortCol = modelData.key; root._sortAsc = true }
                                        _sortBooks()
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    width: parent.width; height: parent.height - 44; clip: true
                    ListView {
                        id: booksListView
                        model: booksModel

                        delegate: Item {
                            width: booksListView.width; height: 52

                            Rectangle {
                                anchors.fill: parent
                                color: rowHover.containsMouse ? "#1e4040" : (index % 2 === 0 ? "#163832" : "#1a3a3a")
                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea {
                                    id: rowHover
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        editTitleField.text = model.title       || ""
                                        editDescField.text  = model.description || ""
                                        editIsbnField.text  = model.isbn        || ""
                                        editYearField.text  = model.year > 0    ? model.year.toString()  : ""
                                        editPagesField.text = model.pages > 0   ? model.pages.toString() : ""

                                        editGenreChips.preloadFromArray(JSON.parse(model.genresJson || "[]"))
                                        editPublisherChip.reset()
                                        editPublisherChip.preload(model.publisherId || 0, model.publisher || "")
                                        editLangChip.preload(model.languageId  || "", model.languageName || "", model.languageCode || "")
                                        editTypeChip.preload(model.typeOfWorkId || "", model.typeOfWork  || "", "")

                                        editCoverPreview.source = ""
                                        coverLoadTimer.pendingUrl = model.coverUrl || ""
                                        coverLoadTimer.restart()
                                        editPopup._newCoverPath = ""
                                        editPopup._newCoverMime = ""

                                        editPopup._newBookFilePath = ""
                                        editBookFileNameText.text   = ""
                                        editCurrentFileText.text = model.contentFileName
                                            ? model.contentFileName
                                            : "Файл не привязан"

                                        editAuthorChips.reset()
                                        var parsedAuthors = JSON.parse(model.authorsJson || "[]")
                                        if (parsedAuthors.length > 0)
                                            editAuthorChips.preload(parsedAuthors)

                                        editPopup.editingBookId = model.bookId
                                        editPopup.visible = true
                                    }
                                }

                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#235347"; opacity: 0.4 }

                                Row {
                                    anchors.fill: parent
                                    TableCell { w: 0.26; val: model.title;     bold: true }
                                    TableCell { w: 0.18; val: model.authorsDisplay }
                                    TableCell { w: 0.12; val: model.genresDisplay  }
                                    TableCell { w: 0.07; val: model.year.toString() }
                                    TableCell { w: 0.09; val: model.languageCode || "—" }
                                    TableCell { w: 0.10; val: model.typeOfWork   || "—" }
                                    TableCell { w: 0.14; val: model.publisher    || "—" }

                                    Item {
                                        width: parent.width * 0.04; height: parent.height
                                        Rectangle {
                                            anchors.centerIn: parent; width: 28; height: 28; radius: 8
                                            color: delBtn.containsMouse ? "#7a1a1a" : "#5c1010"
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Text { anchors.centerIn: parent; text: "✕"; color: "#DAF1DE"; font.pixelSize: 12 }
                                            MouseArea {
                                                id: delBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    deleteDialog.pendingId = model.bookId
                                                    deleteDialog.message = "«" + model.title + "»\nбудет удалена безвозвратно."
                                                    deleteDialog.show("Удалить книгу?", deleteDialog.message)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent; visible: booksModel.count === 0
                            text: "Книги не найдены"; font.family: "Montserrat"; font.pixelSize: 16; color: "#8EB69B"
                        }
                    }
                }
            }
        }
    }

    component TableCell: Item {
        property real w: 0.1
        property string val: ""
        property bool bold: false
        width: parent ? parent.width * w : 100
        height: 52
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12
            text: val; font.family: "Montserrat"; font.pixelSize: 13; font.bold: bold
            color: "#DAF1DE"; elide: Text.ElideRight
        }
    }

    ListModel { id: booksModel }

    function _filterBooks(text) {
        root._allBooks = presenter.books.filter(function(b) {
            if (text === "") return true
            var t = text.toLowerCase()
            var authStr = b.authors ? b.authors.map(function(a){ return a.last_name }).join(" ") : ""
            return b.title.toLowerCase().includes(t) || authStr.toLowerCase().includes(t)
        })
        _rebuildModel(root._allBooks)
    }

    function _sortBooks() { _rebuildModel(root._allBooks) }

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
        booksModel.clear()
        for (var i = 0; i < sorted.length; i++) {
            var b = sorted[i]
            booksModel.append({
                bookId:          b.bookId          || "",
                title:           b.title           || "",
                year:            b.year            || 0,
                isbn:            b.isbn            || "",
                description:     b.description     || "",
                pages:           b.pages           || 0,
                editionNumber:   b.editionNumber   || 1,
                languageName:    b.languageName    || "",
                languageCode:    b.languageCode    || "",
                languageId:      b.languageId      || "",
                typeOfWork:      b.typeOfWork      || "",
                typeOfWorkId:    b.typeOfWorkId    || "",
                publisher:       b.publisher       || "",
                publisherId:     b.publisherId     || 0,
                        coverStorageKey:   b.coverStorageKey   || "",
                        coverUrl:          b.coverUrl          || "",
                        contentStorageKey: b.contentStorageKey || "",
                        contentFileName:   b.contentFileName   || "",
                        contentMimeType:   b.contentMimeType   || "",
                authorsDisplay:  b.authors && b.authors.length > 0
                    ? b.authors.slice(0,2).map(function(a){
                        return a.last_name + " " + (a.first_name ? a.first_name.charAt(0) + "." : "")
                      }).join(" · ")
                    : "—",
                genresDisplay:   b.genres && b.genres.length > 0
                    ? b.genres.slice(0,2).map(function(g){ return g.genre_name }).join(" · ")
                    : "—",
                authorsJson:     JSON.stringify(b.authors  || []),
                genresJson:      JSON.stringify(b.genres   || [])
            })
        }
    }

    Component.onCompleted: {
        if (!TokenManager.hasValidToken()) return
        presenter.loadBooks("")
        presenter.loadReferenceData()
    }
}
