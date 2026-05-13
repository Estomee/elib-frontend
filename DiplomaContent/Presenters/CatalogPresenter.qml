// Presenter for the public book catalog: loads paginated books with filters and handles add-to-library.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal booksLoaded()
    signal loadFailed(string message)
    signal bookAddedToLibrary(bool isNew)
    signal addToLibraryFailed(string message)

    property bool   isLoading:   false
    property int    totalCount:  0
    property bool   hasNextPage: false
    property bool   hasPrevPage: false
    property string endCursor:   ""
    property string startCursor: ""

    property var books: []
    property var _currentFilters: ({})

    function loadBooks(filters, afterCursor) {
        if (!TokenManager.hasValidToken()) return
        isLoading = true
        _currentFilters = filters || {}

        var filter = {}
        if (filters && typeof filters === "object") {
            if (filters.titleContains)    filter.title            = filters.titleContains
            if (filters.author)           filter.author           = filters.author
            if (filters.genre)            filter.genre            = filters.genre
            if (filters.yearOfPublishing) filter.year_of_publishing = filters.yearOfPublishing
            if (filters.language)         filter.language         = filters.language
            if (filters.typeOfWork)       filter.type_of_work     = filters.typeOfWork
        }

        CatalogService.loadBooks(
            { first: 20, after: afterCursor || "" },
            filter,
            function(data) {
                var nodes = []
                for (var i = 0; i < data.nodes.length; i++) {
                    var b = data.nodes[i]
                    var authorNames = []
                    for (var j = 0; j < b.authors.length; j++) {
                        var a = b.authors[j]
                        authorNames.push(a.first_name + " " + a.last_name)
                    }
                    var genreNames = []
                    for (var k = 0; k < b.genres.length; k++) {
                        genreNames.push(b.genres[k].genre_name)
                    }
                    nodes.push({
                        bookId:      b.book_id,
                        title:       b.title,
                        description: b.description,
                        author:      authorNames.join(", "),
                        genre:       genreNames.join(", "),
                        year:        b.year_of_publishing,
                        coverPath:   (b.book_cover && b.book_cover.file_path) ? b.book_cover.file_path : ""
                    })
                }
                books      = nodes
                totalCount = data.total_count
                hasNextPage  = data.page_info ? data.page_info.has_next_page  : false
                hasPrevPage  = data.page_info ? data.page_info.has_previous_page : false
                endCursor    = data.page_info ? (data.page_info.end_cursor   || "") : ""
                startCursor  = data.page_info ? (data.page_info.start_cursor || "") : ""
                isLoading = false
                booksLoaded()
            },
            function(msg) {
                isLoading = false
                loadFailed(msg)
            }
        )
    }

    function nextPage()  { loadBooks(_currentFilters, endCursor)   }
    function prevPage()  { loadBooks(_currentFilters, startCursor)  }

    function addToLibrary(bookId) {
        CatalogService.addToLibrary(bookId,
            function(data) { bookAddedToLibrary(data && data.is_new === true) },
            function(msg)  { addToLibraryFailed(msg) }
        )
    }
}
