// Presenter for book upload: orchestrates a three-phase upload (book file, cover, database record) via BookService.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal uploadSuccess()
    signal uploadFailed(string message)

    property bool   isUploading:    false
    property real   uploadProgress: 0.0
    property string uploadStatus:   ""

    property var availableAuthors:    []
    property var availablePublishers: []
    property var availableGenres:     []
    property var availableLanguages:  []
    property var availableTypesOfWork: []

    function loadReferenceData() {
        if (!HealthService.isChecked && !HealthService.isChecking)
            HealthService.check()
        BookService.loadAuthors(
            function(data) { availableAuthors = data },
            function(msg)  { uploadFailed(msg) }
        )
        BookService.loadPublishers(
            function(data) { availablePublishers = data },
            function(msg)  { uploadFailed(msg) }
        )
        BookService.loadGenres(
            function(data) { availableGenres = data.filter(function(g) { return g.parent_genre_id !== g.genre_id }) },
            function(msg)  { uploadFailed(msg) }
        )
        BookService.loadLanguages(
            function(data) { availableLanguages = data },
            function(msg)  { uploadFailed(msg) }
        )
        BookService.loadTypesOfWork(
            function(data) { availableTypesOfWork = data },
            function(msg)  { uploadFailed(msg) }
        )
    }

    function uploadBook(metadata, coverPath, bookPath) {
        if (HealthService.isChecked && !HealthService.isStorageReady) {
            uploadFailed("Файловое хранилище временно недоступно. Загрузка книг сейчас недоступна.")
            return
        }
        if (metadata.title.trim() === "") {
            uploadFailed("Введите название книги")
            return
        }
        if (!bookPath || bookPath.trim() === "") {
            uploadFailed("Выберите файл книги (.pdf или .epub)")
            return
        }

        isUploading    = true
        uploadProgress = 0.05
        uploadStatus   = "Подготовка к загрузке..."

        var bookContentType = (bookPath.toLowerCase().indexOf(".epub") >= 0)
            ? "application/epub+zip" : "application/pdf"
        var coverContentType = ""
        if (coverPath && coverPath !== "") {
            coverContentType = (coverPath.toLowerCase().indexOf(".png") >= 0)
                ? "image/png" : "image/jpeg"
        }

        var bookStorageKey  = ""
        var coverStorageKey = ""

        var bookFileSize  = FileUploader.fileSize(bookPath)
        var coverFileSize = (coverPath && coverPath !== "") ? FileUploader.fileSize(coverPath) : 0
        var coverImg      = (coverPath && coverPath !== "") ? FileUploader.imageSize(coverPath) : { width: 0, height: 0 }

        function _fail(msg) {
            isUploading = false; uploadStatus = ""; uploadProgress = 0.0
            uploadFailed(msg)
        }

        function _doCreateBook() {
            uploadStatus   = "Создание записи в базе данных..."
            uploadProgress = 0.92

            var input = {
                title:               metadata.title,
                isbn:                metadata.isbn        || "",
                description:         metadata.description || "",
                year_of_publishing:  parseInt(metadata.year)          || 0,
                publisher_id:          parseInt(metadata.publisherId)    || 0,
                new_publisher_name:    metadata.newPublisherName         || null,
                language_id:           parseInt(metadata.languageId)     || 0,
                new_language_name:     metadata.newLanguageName          || null,
                new_language_code:     metadata.newLanguageCode          || null,
                type_of_work_id:       parseInt(metadata.typeOfWorkId)   || 0,
                new_type_of_work_name: metadata.newTypeOfWorkName        || null,
                page_count:          parseInt(metadata.pageCount)      || 0,
                edition_number:      parseInt(metadata.editionNumber)  || 1,
                author_ids:          (metadata.authorIds || []).map(function(id) { return parseInt(id, 10) }),
                new_authors:         metadata.newAuthors || [],
                genre_ids:           (metadata.genreIds  || []).map(function(id) { return parseInt(id, 10) }),
                new_genre_names:     metadata.newGenreNames || [],
                cover_storage_key:   coverStorageKey     || null,
                cover_mime_type:     coverContentType    || null,
                cover_file_size:     coverFileSize       || null,
                cover_width:         coverImg.width      || null,
                cover_height:        coverImg.height     || null,
                content_storage_key: bookStorageKey,
                content_mime_type:   bookContentType,
                content_file_size:   bookFileSize > 0 ? bookFileSize : null
            }

            BookService.createBook(input,
                function(data) {
                    isUploading    = false
                    uploadStatus   = "Книга успешно загружена"
                    uploadProgress = 1.0
                    uploadSuccess()
                },
                function(msg) { _fail(msg) }
            )
        }

        function _uploadCoverThenCreate() {
            if (!coverPath || coverPath.trim() === "") {
                _doCreateBook()
                return
            }

            uploadStatus   = "Получение URL для обложки..."
            uploadProgress = 0.55

            BookService.getUploadUrl(coverContentType,
                function(result) {
                    coverStorageKey = result.storage_key
                    uploadStatus    = "Загрузка обложки..."
                    uploadProgress  = 0.60

                    FileUploader.uploadFile(
                        result.presigned_url, coverPath, coverContentType,
                        function(p) { uploadProgress = 0.60 + p * 0.28 },
                        function()  { _doCreateBook() },
                        function(msg) { _fail("Ошибка загрузки обложки: " + msg) }
                    )
                },
                function(msg) { _fail("Не удалось получить URL для обложки: " + msg) }
            )
        }

        uploadStatus   = "Получение URL для файла книги..."
        uploadProgress = 0.10

        BookService.getUploadUrl(bookContentType,
            function(result) {
                bookStorageKey = result.storage_key
                uploadStatus   = "Загрузка файла книги..."
                uploadProgress = 0.15

                FileUploader.uploadFile(
                    result.presigned_url, bookPath, bookContentType,
                    function(p) { uploadProgress = 0.15 + p * 0.38 },
                    function()  { _uploadCoverThenCreate() },
                    function(msg) { _fail("Ошибка загрузки файла книги: " + msg) }
                )
            },
            function(msg) { _fail("Не удалось получить URL для загрузки: " + msg) }
        )
    }
}
