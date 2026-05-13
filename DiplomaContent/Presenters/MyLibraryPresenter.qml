// Presenter for the user's personal library: loads server and local books, manages removal and reading progress.
import QtQuick
import DiplomaContent.Database
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal booksLoaded()
    signal loadFailed(string message)
    signal bookRemovedSuccess()
    signal bookRemovedFailed(string message)
    signal localBookAdded()

    property bool isLoading: false

    property var readingBooks:  []
    property var finishedBooks: []

    property var _serverBookMap: ({})

    function loadLibrary(userId) {
        if (!TokenManager.hasValidToken()) return
        isLoading = true

        LibraryService.loadUserBooks(TokenManager.userId, { first: 100, after: "" },
            function(data) {
                var reading  = []
                var finished = []
                var map      = {}

                for (var i = 0; i < data.nodes.length; i++) {
                    var ub  = data.nodes[i]
                    var b   = ub.book
                    var authorNames = []
                    for (var j = 0; j < b.authors.length; j++) {
                        var a = b.authors[j]
                        authorNames.push(a.first_name + " " + a.last_name)
                    }
                    var genreNames = []
                    for (var k = 0; k < b.genres.length; k++) {
                        genreNames.push(b.genres[k].genre_name)
                    }
                    var entry = {
                        bookId:       String(b.book_id),
                        userBookId:   ub.user_book_id,
                        title:        b.title,
                        author:       authorNames.join(", "),
                        genre:        genreNames.join(", "),
                        year:         b.year_of_publishing || 0,
                        readProgress: b.page_count > 0
                            ? Math.round((ub.last_read_page / b.page_count) * 100)
                            : 0,
                        lastPage:     ub.last_read_page,
                        totalPages:   b.page_count,
                        isLocal:      false,
                        localPath:    "",
                        coverPath:    b.book_cover ? b.book_cover.file_path : ""
                    }
                    map[String(b.book_id)] = ub.user_book_id
                    if (ub.status === "finished")
                        finished.push(entry)
                    else
                        reading.push(entry)
                }

                var localBooks = LocalBookDatabase.getAllBooks()
                for (var l = 0; l < localBooks.length; l++) {
                    reading.push(localBooks[l])
                }

                _serverBookMap = map
                readingBooks   = reading
                finishedBooks  = finished
                isLoading      = false
                booksLoaded()
            },
            function(msg) {
                var localBooks = LocalBookDatabase.getAllBooks()
                readingBooks   = localBooks
                finishedBooks  = []
                isLoading      = false
                booksLoaded()
                loadFailed(msg)
            }
        )
    }

    function removeBook(bookId) {
        var strId = String(bookId)
        if (_serverBookMap.hasOwnProperty(strId)) {
            LibraryService.removeBookFromLibrary(_serverBookMap[strId],
                function() { bookRemovedSuccess() },
                function(msg) { bookRemovedFailed(msg) }
            )
        } else {
            LocalBookDatabase.removeBook(bookId)
            bookRemovedSuccess()
        }
    }

    function addLocalBook(meta, filePath) {
        var bookId = "local_" + Date.now()
        LocalBookDatabase.addOrUpdateBook(
            bookId,
            meta.title  || "Без названия",
            meta.author || "Неизвестный автор",
            meta.genre  || "",
            parseInt(meta.year) || 0,
            filePath.toString())
        localBookAdded()
    }

    function getLocalProgress(localPath) {
        return LocalBookDatabase.getProgress(localPath.toString())
    }

    function updateProgress(bookId, lastPage) {
        var strId = String(bookId)
        if (_serverBookMap.hasOwnProperty(strId)) {
            LibraryService.updateReadingProgress(_serverBookMap[strId], lastPage, null, null)
        }
    }
}
