// Presenter for the book reader: downloads book files, opens local files, and persists reading progress.
import QtQuick
import DiplomaContent.Database
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal bookFileReady(string localPath, string fileType)
    signal bookLoadFailed(string message)
    signal progressSaved()

    property bool   isLoading:      false
    property string bookTitle:      ""
    property string bookAuthor:     ""
    property int    currentPage:    1
    property int    totalPages:     0
    property string fileType:       ""
    property string _localFilePath: ""
    property int    _userBookId:    0

    function openBook(bookId, userBookId, startPage) {
        isLoading      = true
        _userBookId    = userBookId || 0
        _localFilePath = ""
        currentPage    = startPage || 1

        var cacheDir = FileUploader.appCacheDir()
        var epubPath = cacheDir + "/book_" + bookId + ".epub"
        var pdfPath  = cacheDir + "/book_" + bookId + ".pdf"

        // Serve from local cache when available — no network needed.
        if (FileUploader.fileSize(epubPath) > 0) {
            fileType  = "epub"
            isLoading = false
            bookFileReady("file:///" + epubPath.replace(/\\/g, "/"), "epub")
            return
        }
        if (FileUploader.fileSize(pdfPath) > 0) {
            fileType  = "pdf"
            isLoading = false
            bookFileReady("file:///" + pdfPath.replace(/\\/g, "/"), "pdf")
            return
        }

        // Not cached — ask server for the proxy URL (includes ?type=pdf|epub for type detection).
        BookService.getBookFileUrl(bookId,
            function(url) {
                if (!url || url === "") {
                    isLoading = false
                    bookLoadFailed("Файл книги недоступен")
                    return
                }

                // Extract type from ?type= query param; fall back to URL extension.
                var typeMatch = url.match(/[?&]type=([^&]+)/)
                var ext       = typeMatch ? typeMatch[1].toLowerCase() : url.split("?")[0].split(".").pop().toLowerCase()
                fileType      = (ext === "epub") ? "epub" : "pdf"

                var localPath = fileType === "epub" ? epubPath : pdfPath
                var downloadUrl = url.split("?")[0]  // strip ?type= param before download

                // Download through server proxy with JWT auth — no direct Yandex Cloud needed.
                FileUploader.downloadFileAuth(downloadUrl, localPath, TokenManager.accessToken,
                    function() {
                        isLoading = false
                        bookFileReady("file:///" + localPath.replace(/\\/g, "/"), fileType)
                    },
                    function(errMsg) {
                        isLoading = false
                        bookLoadFailed("Не удалось загрузить файл книги: " + errMsg)
                    }
                )
            },
            function(msg) {
                isLoading = false
                bookLoadFailed(msg)
            }
        )
    }

    function openLocalFile(filePath) {
        isLoading      = true
        _userBookId    = 0
        var pathStr    = filePath.toString()
        if (pathStr.indexOf("file://") !== 0)
            pathStr = "file:///" + pathStr.replace(/\\/g, "/")
        var ext = pathStr.split(".").pop().toLowerCase()
        fileType = (ext === "epub") ? "epub" : "pdf"

        _localFilePath = pathStr
        var saved      = LocalBookDatabase.getProgress(pathStr)
        currentPage    = saved.page

        isLoading = false
        bookFileReady(pathStr, fileType)
    }

    function saveProgress(bookId, page) {
        currentPage = page
        if (_localFilePath !== "") {
            LocalBookDatabase.updateProgress(_localFilePath, page, totalPages)
        }
        progressSaved()
    }

    function flushProgress() {
        if (_userBookId > 0 && currentPage > 0) {
            LibraryService.updateReadingProgress(_userBookId, currentPage,
                function(data) {},
                function(msg)  {})
        }
    }

    function goToPage(page) {
        if (page >= 1 && (totalPages === 0 || page <= totalPages))
            currentPage = page
    }

    function nextPage() { goToPage(currentPage + 1) }
    function prevPage() { goToPage(currentPage - 1) }
}
