import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Pdf
import DiplomaContent.UI_Elements
import DiplomaContent.Presenters
import DiplomaContent.Components
import DiplomaContent.Network

// ─────────────────────────────────────────────────────────────
// UploadBooksView — форма загрузки новой книги
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    signal uploadSuccess()

    property string _coverPath: ""  // локальный путь к обложке

    function reload() {
        if (TokenManager.hasValidToken()) presenter.loadReferenceData()
    }

    Component.onCompleted: reload()

    UploadBooksPresenter {
        id: presenter

        onUploadSuccess: {
            statusText.show("Книга успешно загружена в библиотеку!", "success")
            _resetForm()
            root.uploadSuccess()
        }
        onUploadFailed: function(msg) {
            statusText.show(msg, "error")
        }
        onUploadProgressChanged: {
            progressBar.value = presenter.uploadProgress
        }
    }

    // ─── Диалоги выбора файлов ───────────────────────────────
    FileDialog {
        id: bookFileDialog
        title: "Выберите файл книги"
        nameFilters: ["Книги (*.pdf *.epub)", "PDF (*.pdf)", "EPUB (*.epub)"]
        onAccepted: {
            var localPath = selectedFile.toString().replace("file:///", "")
            bookFilePath.text = localPath

            var ext = localPath.split(".").pop().toLowerCase()
            if (ext === "pdf") {
                // Точный подсчёт через PdfDocument; результат — в onStatusChanged выше
                _pdfPageCounter.source = ""
                _pdfPageCounter.source = selectedFile
            } else if (ext === "epub") {
                // Оценка: 1 страница ≈ 1500 символов; для UTF-8 + HTML-разметка ≈ 3500 байт/стр.
                var bytes = FileUploader.fileSize(localPath)
                if (bytes > 0)
                    pagesField.text = Math.max(1, Math.round(bytes / 3500)).toString()
            }
        }
    }
    FileDialog {
        id: coverFileDialog
        title: "Выберите обложку"
        nameFilters: ["Изображения (*.jpg *.jpeg *.png)"]
        onAccepted: {
            root._coverPath = selectedFile.toString().replace("file:///", "")
            coverPreview.source = selectedFile
        }
    }

    // Используется только для чтения pageCount у PDF после выбора файла
    PdfDocument {
        id: _pdfPageCounter
        onStatusChanged: {
            if (status === PdfDocument.Ready && pageCount > 0) {
                pagesField.text = pageCount.toString()
                source = ""   // освобождаем память
            }
        }
    }

    Rectangle { anchors.fill: parent; color: "#051F20" }

    NotificationToast {
        id: statusText
        anchors.top: root.top; anchors.topMargin: 10
        anchors.horizontalCenter: root.horizontalCenter
    }

    // ─── ScrollView обеспечивает прокрутку при малой высоте окна ──
    ScrollView {
        id: sv
        anchors.fill: parent; clip: true
        contentWidth: availableWidth        // горизонтальная прокрутка отключена
        contentHeight: uploadColumn.y + uploadColumn.implicitHeight + 60

        Column {
            id: uploadColumn
            width: Math.min(860, sv.availableWidth - 56)
            x: Math.round((sv.availableWidth - width) / 2)
            y: 28
            spacing: 24
            opacity: 0

                NumberAnimation {
                    id: uploadAppearAnim; target: uploadColumn; property: "opacity"
                    from: 0; to: 1; duration: 380; easing.type: Easing.OutCubic
                }
                Component.onCompleted: uploadAppearAnim.start()

                HeadingText { text: "Загрузка книги"; size: 26 }

                // ─ Верхний блок: обложка + основные поля ─────
                Row {
                    width: parent.width; spacing: 24

                    // ─ Левая колонка: обложка ─
                    Column {
                        width: 200; spacing: 14

                        Rectangle {
                            width: 200; height: 260; radius: 14
                            color: "#163832"; border.color: "#235347"; border.width: 2
                            clip: true

                            Image {
                                id: coverPreview
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                mipmap: true
                                visible: source !== ""
                            }

                            Column {
                                anchors.centerIn: parent; spacing: 10
                                visible: coverPreview.source === ""
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Обложка"; font.family: "Montserrat"; font.pixelSize: 14; color: "#8EB69B" }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "JPG / PNG"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B"; opacity: 0.6 }
                            }
                        }

                        MainButton {
                            width: 200; height: 42
                            buttonText: "Выбрать обложку"; buttonTextSize: 10
                            onClicked: coverFileDialog.open()
                        }
                    }

                    // ─ Правая колонка: метаданные ─
                    Column {
                        width: parent.width - 200 - 24; spacing: 14

                        // Название
                        Column {
                            width: parent.width; spacing: 6
                            Text { text: "Название *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            MainTextField { id: titleField; width: parent.width; height: 48; hint: "Название книги"; hintTextSize: 13; mainTextSize: 14; maximumLength: 200 }
                        }

                        // Описание
                        Column {
                            width: parent.width; spacing: 6
                            Text { text: "Описание *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                            Rectangle {
                                width: parent.width; height: 90; radius: 14
                                color: "#235347"; border.color: "#051F20"; border.width: 2
                                ScrollView {
                                    anchors.fill: parent; anchors.margins: 10
                                    TextArea {
                                        id: descField
                                        font.family: "Montserrat"; font.pixelSize: 13; color: "#DAF1DE"
                                        background: null; wrapMode: TextArea.Wrap
                                        placeholderText: "Краткое описание книги..."; placeholderTextColor: "#8EB69B"
                                    }
                                }
                            }
                        }

                        // ISBN + Год
                        Row {
                            width: parent.width; spacing: 12
                            Column {
                                width: (parent.width - 12) * 0.6; spacing: 6
                                Text { text: "ISBN"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                                MainTextField {
                                    id: isbnField; width: parent.width; height: 46
                                    hint: "978-X-XXXXXX-XX-X"; hintTextSize: 12; mainTextSize: 13; maximumLength: 17
                                    property bool _fmt: false
                                    onTextChanged: {
                                        if (_fmt) return; _fmt = true
                                        var digits = text.replace(/[^0-9]/g, "").slice(0, 13)
                                        var f = digits.slice(0, Math.min(3, digits.length))
                                        if (digits.length > 3)  f += "-" + digits.slice(3, 4)
                                        if (digits.length > 4)  f += "-" + digits.slice(4, 10)
                                        if (digits.length > 10) f += "-" + digits.slice(10, 12)
                                        if (digits.length > 12) f += "-" + digits.slice(12, 13)
                                        text = f; _fmt = false
                                    }
                                }
                            }
                            Column {
                                width: (parent.width - 12) * 0.4; spacing: 6
                                Text { text: "Год издания *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                                MainTextField { id: yearField; width: parent.width; height: 46; hint: "Год"; hintTextSize: 13; mainTextSize: 13; validator: IntValidator { bottom: 1000; top: 2100 } }
                            }
                        }

                        // Издатель + Страницы
                        Row {
                            width: parent.width; spacing: 12
                            Column {
                                width: (parent.width - 12) * 0.6; spacing: 6
                                Text { text: "Издатель *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                                PublisherChipSelector {
                                    id: publisherChip
                                    width: parent.width
                                    availablePublishers: presenter.availablePublishers
                                }
                            }
                            Column {
                                width: (parent.width - 12) * 0.4; spacing: 6
                                Text { text: "Страниц"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                                MainTextField { id: pagesField; width: parent.width; height: 46; hint: "Кол-во"; hintTextSize: 13; mainTextSize: 13; validator: IntValidator { bottom: 1; top: 9999 } }
                            }
                        }
                    }
                }

                // ─ Авторы (чипы) ──────────────────────────────
                Column {
                    width: parent.width; spacing: 8
                    Text { text: "Авторы *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    // TODO: передать availableAuthors из presenter когда подключён backend
                    AuthorChipsSelector {
                        id: authorChips
                        width: parent.width
                        availableAuthors: presenter.availableAuthors
                    }
                }

                // ─ Жанры ──────────────────────────────────────
                Column {
                    width: parent.width; spacing: 8
                    Text { text: "Жанры *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    GenreChipsInput {
                        id: genreInput
                        width: parent.width
                        availableGenres: presenter.availableGenres
                    }
                }

                // ─ Язык книги (чип-селектор) ──────────────────
                Column {
                    width: parent.width; spacing: 8
                    Text { text: "Язык книги *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    // TODO: заполнять availableItems из GraphQL query languages()
                    //       selectedId → languageId в mutation BookInput
                    //       isNew → создать новую Language перед сохранением книги
                    SingleChipSelector {
                        id: langChip
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

                // ─ Тип произведения (чип-селектор) ────────────
                Column {
                    width: parent.width; spacing: 8
                    Text { text: "Тип произведения *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    // TODO: заполнять availableItems из GraphQL query typesOfWork()
                    //       selectedId → typeOfWorkId в mutation BookInput
                    //       isNew → создать новый TypeOfWork перед сохранением книги
                    SingleChipSelector {
                        id: typeChip
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

                // ─ Файл книги ─────────────────────────────────
                Column {
                    width: parent.width; spacing: 8
                    Text { text: "Файл книги * (.pdf или .epub)"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    Row {
                        width: parent.width; spacing: 12
                        MainTextField {
                            id: bookFilePath; width: parent.width - 170; height: 46
                            hint: "Путь к файлу..."; hintTextSize: 13; mainTextSize: 12; readOnly: true
                        }
                        MainButton {
                            width: 160; height: 46; buttonText: "Выбрать файл"; buttonTextSize: 10
                            onClicked: bookFileDialog.open()
                        }
                    }
                }

                // ─ Прогресс загрузки ──────────────────────────
                Rectangle {
                    width: parent.width; height: 50
                    color: "#163832"; radius: 14; border.color: "#235347"; border.width: 1
                    visible: presenter.isUploading

                    Row {
                        anchors.fill: parent; anchors.margins: 14; spacing: 16
                        Rectangle {
                            width: parent.width - 160; height: 14; radius: 7; color: "#0B2B26"
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                id: progressBar; property real value: 0
                                width: parent.width * value; height: parent.height; radius: 7; color: "#8EB69B"
                                Behavior on width { NumberAnimation { duration: 180 } }
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter; width: 150
                            text: Math.round(progressBar.value * 100) + "% — " + presenter.uploadStatus
                            font.family: "Montserrat"; font.pixelSize: 12; color: "#DAF1DE"; elide: Text.ElideRight
                        }
                    }
                }

                // ─ Кнопки ─────────────────────────────────────
                Row {
                    width: parent.width; spacing: 16

                    MainButton {
                        width: 200; height: 52
                        buttonText: presenter.isUploading ? "Загрузка..." : "Загрузить книгу"
                        buttonTextSize: 12; enabled: !presenter.isUploading
                        onClicked: {
                            if (titleField.text.trim() === "")       { statusText.show("Введите название книги", "error"); return }
                            if (descField.text.trim() === "")        { statusText.show("Введите описание", "error"); return }
                            if (yearField.text.trim() === "")        { statusText.show("Введите год издания", "error"); return }
                            if (publisherChip.selectedName === "")    { statusText.show("Выберите или добавьте издательство", "error"); return }
                            if (langChip.selectedName === "")        { statusText.show("Выберите язык книги", "error"); return }
                            if (typeChip.selectedName === "")        { statusText.show("Выберите тип произведения", "error"); return }
                            if (bookFilePath.text.trim() === "")     { statusText.show("Выберите файл книги", "error"); return }
                            if (authorChips.selectedAuthorIds.length === 0 && authorChips.newAuthors.length === 0) {
                                statusText.show("Добавьте хотя бы одного автора", "error"); return
                            }
                            presenter.uploadBook(
                                {
                                    title:        titleField.text,
                                    description:  descField.text,
                                    isbn:         isbnField.text,
                                    year:         yearField.text,
                                    publisherId:      publisherChip.selectedPublisherId,
                                    newPublisherName: publisherChip.newPublisherName,
                                    pageCount:    pagesField.text,
                                    editionNumber: 1,
                                    languageId:      langChip.isNew ? 0 : parseInt(langChip.selectedId),
                                    newLanguageName: langChip.isNew ? langChip.selectedName : null,
                                    newLanguageCode: langChip.isNew ? langChip.selectedCode : null,
                                    typeOfWorkId:    typeChip.isNew ? 0 : parseInt(typeChip.selectedId),
                                    newTypeOfWorkName: typeChip.isNew ? typeChip.selectedName : null,
                                    authorIds:     authorChips.selectedAuthorIds,
                                    newAuthors:    authorChips.newAuthors,
                                    genreIds:      genreInput.selectedIds,
                                    newGenreNames: genreInput.newGenreNames
                                },
                                root._coverPath,
                                bookFilePath.text
                            )
                        }
                    }

                    MainButton {
                        width: 130; height: 52; buttonText: "Очистить"; buttonTextSize: 11
                        onClicked: _resetForm()
                    }
                }

                Item { width: 1; height: 24 }
        }
    }

    function _resetForm() {
        titleField.text              = ""
        descField.text               = ""
        isbnField.text               = ""
        yearField.text               = ""
        genreInput.reset()
        publisherChip.reset()
        pagesField.text              = ""
        bookFilePath.text            = ""
        root._coverPath              = ""
        coverPreview.source          = ""
        progressBar.value            = 0
        authorChips.reset()
        langChip.reset()
        typeChip.reset()
    }
}
