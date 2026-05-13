// Presenter for the main screen: loads recent reading books and handles logout.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal logoutRequested()
    signal recentBooksLoaded()

    property bool   isLoading:  false
    property string userName:   TokenManager.firstName + " " + TokenManager.lastName
    property string userEmail:  TokenManager.email

    property var recentBooks: []

    function loadMainData(userId) {
        if (!TokenManager.hasValidToken()) return
        isLoading = true

        LibraryService.loadUserBooks(TokenManager.userId,
            { first: 5, after: "" },
            function(data) {
                var reading = []
                for (var i = 0; i < data.nodes.length; i++) {
                    var ub = data.nodes[i]
                    if (ub.status === "reading") {
                        var authorNames = []
                        for (var j = 0; j < (ub.book.authors || []).length; j++) {
                            var a = ub.book.authors[j]
                            authorNames.push(a.first_name + " " + a.last_name)
                        }
                        var genreNames = []
                        for (var k = 0; k < (ub.book.genres || []).length; k++) {
                            genreNames.push(ub.book.genres[k].genre_name)
                        }
                        reading.push({
                            bookId:       ub.book.book_id,
                            title:        ub.book.title,
                            author:       authorNames.join(", "),
                            genre:        genreNames.join(", "),
                            year:         ub.book.year_of_publishing || 0,
                            readProgress: ub.book.page_count > 0
                                ? Math.round((ub.last_read_page / ub.book.page_count) * 100)
                                : 0,
                            coverPath:    (ub.book.book_cover && ub.book.book_cover.file_path)
                                          ? ub.book.book_cover.file_path : ""
                        })
                    }
                }
                recentBooks = reading
                isLoading   = false
                recentBooksLoaded()
            },
            function(msg) {
                isLoading = false
                recentBooksLoaded()
            }
        )
    }

    function logout() {
        AuthService.logout(
            function()    { logoutRequested() },
            function(msg) { logoutRequested() }
        )
    }
}
