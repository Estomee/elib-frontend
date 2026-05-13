// Presenter for book management: loads, updates, and deletes books including file upload to S3.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal booksLoaded()
    signal bookDeleted()
    signal bookUpdated()
    signal operationFailed(string message)

    property bool isLoading: false

    property var books:              []
    property var availableAuthors:   []
    property var availableGenres:    []
    property var availableLanguages: []
    property var availableTypesOfWork: []
    property var availablePublishers:  []

    function loadBooks(searchText) {
        if (!TokenManager.hasValidToken()) return
        isLoading = true

        BookService.loadBooks(
            { first: 50, after: "" },
            searchText ? { title: searchText } : null,
            function(data) {
                var nodes = []
                for (var i = 0; i < data.nodes.length; i++) {
                    var b = data.nodes[i]
                    nodes.push({
                        bookId:       b.book_id,
                        title:        b.title,
                        authors:      b.authors,
                        genres:       b.genres,
                        year:         b.year_of_publishing,
                        isbn:         b.isbn,
                        description:  b.description,
                        pages:        b.page_count,
                        editionNumber: b.edition_number,
                        languageName: b.language  ? b.language.lang_name  : "",
                        languageCode: b.language  ? b.language.lang_code  : "",
                        languageId:   b.language  ? b.language.lang_id    : "",
                        typeOfWork:   b.type_of_work ? b.type_of_work.type_name : "",
                        typeOfWorkId: b.type_of_work ? b.type_of_work.work_id   : "",
                        publisher:        b.publisher ? b.publisher.name         : "",
                        publisherId:      b.publisher ? b.publisher.publisher_id : "",
                        coverStorageKey:    b.book_cover    ? b.book_cover.storage_key    : "",
                        coverUrl:           b.book_cover    ? b.book_cover.file_path      : "",
                        contentStorageKey:  b.book_content  ? b.book_content.storage_key  : "",
                        contentFileName:    b.book_content  ? b.book_content.file_name     : "",
                        contentMimeType:    b.book_content  ? b.book_content.mime_type     : "",
                        contentFileSize:    b.book_content  ? b.book_content.file_size     : 0
                    })
                }
                books     = nodes
                isLoading = false
                booksLoaded()
            },
            function(msg) {
                isLoading = false
                operationFailed(msg)
            }
        )
    }

    function loadReferenceData() {
        BookService.loadAuthors(
            function(data) { availableAuthors = data },
            function(msg)  { operationFailed(msg) }
        )
        BookService.loadGenres(
            function(data) { availableGenres = data.filter(function(g) { return g.parent_genre_id !== g.genre_id }) },
            function(msg)  { operationFailed(msg) }
        )
        BookService.loadLanguages(
            function(data) { availableLanguages = data },
            function(msg)  { operationFailed(msg) }
        )
        BookService.loadTypesOfWork(
            function(data) { availableTypesOfWork = data },
            function(msg)  { operationFailed(msg) }
        )
        BookService.loadPublishers(
            function(data) { availablePublishers = data },
            function(msg)  { operationFailed(msg) }
        )
    }

    function deleteBook(bookId) {
        isLoading = true

        BookService.deleteBook(bookId,
            function() {
                books     = books.filter(function(b) { return b.bookId !== bookId })
                isLoading = false
                bookDeleted()
            },
            function(msg) {
                isLoading = false
                operationFailed(msg)
            }
        )
    }

    function updateBook(bookId, input) {
        isLoading = true

        function _fail(msg) { isLoading = false; operationFailed(msg) }

        function _doUpdate(coverStorageKey, contentStorageKey, contentMime, contentSize) {
            var upInput = {
                book_id:            parseInt(bookId),
                title:              input.title        || null,
                description:        input.description  || null,
                isbn:               input.isbn         || null,
                year_of_publishing: input.year   > 0   ? input.year   : null,
                page_count:         input.pages  > 0   ? input.pages  : null,
                publisher_id:       input.publisherId  > 0 ? parseInt(input.publisherId)  : null,
                language_id:        input.languageId   > 0 ? parseInt(input.languageId)   : null,
                type_of_work_id:    input.typeOfWorkId > 0 ? parseInt(input.typeOfWorkId) : null,
                author_ids:         (input.authorIds    || []).map(function(id){ return parseInt(id,10) }),
                genre_ids:          (input.genreIds     || []).map(function(id){ return parseInt(id,10) }),
                new_genre_names:    input.newGenreNames || []
            }
            if (coverStorageKey) {
                upInput.cover_storage_key = coverStorageKey
                upInput.cover_mime_type   = input.coverMimeType || "image/jpeg"
                upInput.cover_file_size   = input.coverFileSize || null
            }
            if (contentStorageKey) {
                upInput.content_storage_key = contentStorageKey
                upInput.content_mime_type   = contentMime || "application/octet-stream"
                upInput.content_file_size   = contentSize || null
            }

            BookService.updateBook(bookId, upInput,
                function(data) { isLoading = false; bookUpdated() },
                function(msg)  { _fail(msg) }
            )
        }

        function _uploadBookFile(coverKey) {
            var ext  = input.newBookFilePath.toLowerCase()
            var mime = ext.indexOf(".pdf")  >= 0 ? "application/pdf"
                     : ext.indexOf(".epub") >= 0 ? "application/epub+zip"
                     : "application/octet-stream"
            BookService.getUploadUrl(mime,
                function(result) {
                    FileUploader.uploadFile(
                        result.presigned_url, input.newBookFilePath, mime,
                        function(p) {},
                        function() { _doUpdate(coverKey, result.storage_key, mime, null) },
                        function(msg) { _fail("Ошибка загрузки файла книги: " + msg) }
                    )
                },
                function(msg) { _fail("Не удалось получить URL для файла книги: " + msg) }
            )
        }

        if (input.newCoverPath && input.newCoverPath !== "") {
            var coverMime = input.newCoverPath.toLowerCase().indexOf(".png") >= 0
                ? "image/png" : "image/jpeg"
            BookService.getUploadUrl(coverMime,
                function(result) {
                    FileUploader.uploadFile(
                        result.presigned_url, input.newCoverPath, coverMime,
                        function(p) {},
                        function() {
                            if (input.newBookFilePath && input.newBookFilePath !== "")
                                _uploadBookFile(result.storage_key)
                            else
                                _doUpdate(result.storage_key, null, null, null)
                        },
                        function(msg) { _fail("Ошибка загрузки обложки: " + msg) }
                    )
                },
                function(msg) { _fail("Не удалось получить URL для обложки: " + msg) }
            )
        } else if (input.newBookFilePath && input.newBookFilePath !== "") {
            _uploadBookFile(null)
        } else {
            _doUpdate(null, null, null, null)
        }
    }
}
