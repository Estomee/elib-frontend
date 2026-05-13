// EPUB viewer component using WebEngineView and epub.js loaded via epub_reader.html.
import QtQuick
import QtWebEngine

Item {
    id: root

    property string filePath: ""
    property int    startSectionIndex: -1
    property bool   _pageReady: false

    signal pageLocated(int sectionIndex, real percentage, int spineLength)

    function nextSection() { webView.runJavaScript("nextSection()") }
    function prevSection() { webView.runJavaScript("prevSection()") }

    function _openBook() {
        var url = root.filePath
        if (!url.startsWith("http") && !url.startsWith("file:"))
            url = "file:///" + url.replace(/\\/g, "/")
        webView.runJavaScript("openEpub(" + JSON.stringify(url) + ", " + root.startSectionIndex + ")")
    }

    onFilePathChanged: {
        if (filePath !== "" && _pageReady)
            _openBook()
    }

    WebEngineView {
        id: webView
        anchors.fill: parent
        url: Qt.resolvedUrl("epub_reader.html")

        settings.localContentCanAccessFileUrls:   true
        settings.localContentCanAccessRemoteUrls: true
        settings.allowRunningInsecureContent:     true

        onLoadingChanged: function(loadRequest) {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                root._pageReady = true
                if (root.filePath !== "")
                    root._openBook()
            }
        }

        onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceID) {
            if (message.indexOf("EPUB_LOC:") === 0) {
                var parts = message.substring(9).split(":")
                var idx = parseInt(parts[0]) || 0
                var pct = parseFloat(parts[1]) || 0.0
                var slen = parseInt(parts[2]) || 0
                root.pageLocated(idx, pct, slen)
            }
        }
    }
}
