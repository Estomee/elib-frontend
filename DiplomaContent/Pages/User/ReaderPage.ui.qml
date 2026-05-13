// PDF and EPUB reader page with top/bottom toolbars, page flip animation, keyboard navigation, and progress saving.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import ".."
import DiplomaContent.UI_Elements
import DiplomaContent.Navigation
import DiplomaContent.Presenters

BasePage {
    id: readerPage
    focus: true

    property string bookId:          ""
    property string bookTitle:       "Книга"
    property string bookAuthor:      ""
    property int    startPage:       1
    property int    userBookId:      0
    property int    bookTotalPages:  0
    property bool   allowLocalFile:  true
    property string localFilePath:   ""

    readonly property int currentReadingPage:  presenter.currentPage
    readonly property int totalReadingPages:   presenter.totalPages

    property bool _programNav: false

    property int  _loadCounter: 0

    ReaderPresenter {
        id: presenter

        onBookFileReady: function(localPath, fileType) {
            _loadTimeoutTimer.stop()
            contentArea.fileType = fileType
            contentArea.filePath = localPath
            contentArea.visible  = true
            errorText.visible    = false
            pageLoader.loading   = false
        }
        onBookLoadFailed: function(message) {
            _loadTimeoutTimer.stop()
            pageLoader.loading = false
            if (message !== "") {
                errorText.text    = message
                errorText.visible = true
            }
        }
    }

    FileDialog {
        id: localFileDialog
        title: "Открыть книгу"
        nameFilters: ["Книги (*.pdf *.epub)", "PDF (*.pdf)", "EPUB (*.epub)"]
        onAccepted: presenter.openLocalFile(selectedFile)
    }

    Rectangle { anchors.fill: parent; color: "#051F20" }

    Item {
        id: topToolbar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 64
        z: 10

        Rectangle {
            anchors.fill: parent; color: "#0B2B26"
            Rectangle {
                anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#163832"
            }
        }

        MainButton {
            id: backBtn
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 16
            width: 110; height: 40
            buttonText: "← Назад"; buttonTextSize: 11
            onClicked: { _loadTimeoutTimer.stop(); _saveTimer.stop(); presenter.flushProgress(); NavigationModule.pop() }
        }

        Column {
            anchors.centerIn: parent
            spacing: 2
            width: parent.width * 0.46

            Text {
                width: parent.width
                text: readerPage.bookTitle
                font.family: "Montserrat"; font.pixelSize: 16; font.bold: true
                color: "#DAF1DE"; elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                width: parent.width
                text: readerPage.bookAuthor
                font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B"
                visible: readerPage.bookAuthor !== ""
                elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 16
            spacing: 8

            Row {
                id: zoomControls
                visible: contentArea.fileType === "pdf" &&
                         pdfLoader.status === Loader.Ready
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: zoomOutMa.containsMouse ? "#1e4040" : "#163832"
                    border.color: "#235347"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; text: "−"
                        font.pixelSize: 18; font.bold: true; color: "#DAF1DE"
                    }
                    MouseArea {
                        id: zoomOutMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (pdfLoader.item) pdfLoader.item.zoomOut()
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: pdfLoader.item
                          ? Math.round(pdfLoader.item.renderScale * 100) + "%"
                          : "100%"
                    font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B"
                    width: 48; horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: zoomInMa.containsMouse ? "#1e4040" : "#163832"
                    border.color: "#235347"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; text: "+"
                        font.pixelSize: 18; font.bold: true; color: "#DAF1DE"
                    }
                    MouseArea {
                        id: zoomInMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (pdfLoader.item) pdfLoader.item.zoomIn()
                    }
                }

                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: resetZoomMa.containsMouse ? "#1e4040" : "#163832"
                    border.color: "#235347"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; text: "⊡"
                        font.pixelSize: 14; color: "#DAF1DE"
                    }
                    MouseArea {
                        id: resetZoomMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (pdfLoader.item) pdfLoader.item.resetZoom()
                    }
                }
            }

        }
    }

    Item {
        id: contentArea
        anchors.top: topToolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomToolbar.top
        visible: false

        property string fileType: ""
        property string filePath: ""

        Item {
            anchors.fill: parent
            visible: contentArea.fileType === "pdf"

            Loader {
                id: pdfLoader
                anchors.fill: parent
                active: contentArea.fileType === "pdf"
                source: "PdfViewer.qml"

                onLoaded: {
                    item.filePath = Qt.binding(function() { return contentArea.filePath })
                }
            }

            Connections {
                target: pdfLoader.item
                enabled: pdfLoader.status === Loader.Ready
                ignoreUnknownSignals: true
                function onPageCountChanged() {
                    if (!pdfLoader.item || pdfLoader.item.pageCount === 0) return
                    presenter.totalPages = pdfLoader.item.pageCount
                    if (presenter.currentPage > 1 && presenter.currentPage <= presenter.totalPages)
                        pdfLoader.item.goToPage(presenter.currentPage - 1)
                }
                function onCurrentPageChanged() {
                    readerPage._programNav = false
                    if (pdfLoader.item) {
                        presenter.currentPage = pdfLoader.item.currentPage + 1
                        presenter.saveProgress("", presenter.currentPage)
                        _saveTimer.restart()
                    }
                }
            }

            Connections {
                target: presenter
                function onCurrentPageChanged() {
                    if (pdfLoader.item) {
                        var idx = presenter.currentPage - 1
                        if (pdfLoader.item.currentPage !== idx) {
                            if (readerPage._programNav) {
                                pageFlipAnim.targetPage = idx
                                pageFlipAnim.restart()
                            } else {
                                pdfLoader.item.goToPage(idx)
                            }
                        }
                    }
                }
            }

        }

        Loader {
            id: epubLoader
            anchors.fill: parent
            active: contentArea.fileType === "epub"
            source: "EpubViewer.qml"
            visible: contentArea.fileType === "epub"

            onLoaded: {
                item.startSectionIndex = (readerPage.startPage > 1) ? readerPage.startPage - 1 : -1
                item.filePath = Qt.binding(function() { return contentArea.filePath })
            }
        }

        Connections {
            target: epubLoader.item
            enabled: epubLoader.status === Loader.Ready
            ignoreUnknownSignals: true
            function onPageLocated(sectionIndex, percentage, spineLength) {
                if (spineLength > 0 && presenter.totalPages !== spineLength)
                    presenter.totalPages = spineLength
                var newPage = sectionIndex + 1
                if (newPage !== presenter.currentPage) {
                    presenter.currentPage = newPage
                    _saveTimer.restart()
                }
            }
        }
    }

    Item {
        id: placeholderArea
        anchors.top: topToolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomToolbar.top
        visible: !contentArea.visible && !pageLoader.loading

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: readerPage.allowLocalFile ? "Файл не выбран" : "Контент недоступен"
                font.family: "Montserrat"; font.pixelSize: 22; font.bold: true; color: "#DAF1DE"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: readerPage.allowLocalFile
                      ? "Нажмите «Открыть файл» или выберите книгу в библиотеке"
                      : "Файл книги временно недоступен."
                font.family: "Montserrat"; font.pixelSize: 14; color: "#8EB69B"
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                id: errorText
                visible: false; text: ""
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: "Montserrat"; font.pixelSize: 13
                color: "#F44336"; horizontalAlignment: Text.AlignHCenter
            }
            MainButton {
                visible: readerPage.allowLocalFile
                anchors.horizontalCenter: parent.horizontalCenter
                width: 220; height: 50
                buttonText: "Открыть локальный файл"; buttonTextSize: 11
                onClicked: localFileDialog.open()
            }
        }
    }

    Item {
        id: bottomToolbar
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 70
        z: 10

        Rectangle {
            anchors.fill: parent; color: "#0B2B26"
            Rectangle {
                anchors.top: parent.top; width: parent.width; height: 1; color: "#163832"
            }
        }

        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1
            anchors.left: parent.left; anchors.right: parent.right
            height: 3; color: "#163832"

            Rectangle {
                width: presenter.totalPages > 0
                       ? parent.width * (presenter.currentPage / presenter.totalPages)
                       : 0
                height: parent.height
                color: "#8EB69B"; radius: 2
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 16

            MainButton {
                width: 44; height: 40
                buttonText: "‹"; buttonTextSize: 18
                enabled: contentArea.fileType === "epub" || presenter.currentPage > 1
                onClicked: {
                    if (contentArea.fileType === "epub") {
                        if (epubLoader.item) epubLoader.item.prevSection()
                    } else {
                        readerPage._programNav = true; presenter.prevPage()
                    }
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                visible: contentArea.fileType !== "epub"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Стр."
                    font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"
                }

                MainTextField {
                    id: pageInput
                    width: 68; height: 38
                    hintTextSize: 12; mainTextSize: 13
                    horizontalAlignment: TextInput.AlignHCenter
                    validator: IntValidator { bottom: 1; top: 9999 }

                    Keys.onReturnPressed: {
                        var p = parseInt(text)
                        if (!isNaN(p) && p >= 1) {
                            readerPage._programNav = true
                            presenter.goToPage(p)
                        }
                        focus = false
                    }
                    Keys.onEscapePressed: {
                        text = presenter.currentPage.toString()
                        focus = false
                    }
                }

                Binding {
                    target: pageInput
                    property: "text"
                    value: presenter.currentPage.toString()
                    when: !pageInput.activeFocus
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: presenter.totalPages > 0 ? "из " + presenter.totalPages : "—"
                    font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"
                }
            }

            MainButton {
                width: 44; height: 40
                buttonText: "›"; buttonTextSize: 18
                enabled: contentArea.fileType === "epub" ||
                         presenter.totalPages === 0 ||
                         presenter.currentPage < presenter.totalPages
                onClicked: {
                    if (contentArea.fileType === "epub") {
                        if (epubLoader.item) epubLoader.item.nextSection()
                    } else {
                        readerPage._programNav = true; presenter.nextPage()
                    }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 20
            text: presenter.totalPages > 0
                  ? Math.round(presenter.currentPage / presenter.totalPages * 100) + "%"
                  : ""
            font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"
        }
    }

    Rectangle {
        id: flipOverlay
        anchors.top: topToolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomToolbar.top
        color: "#051F20"
        opacity: 0
        z: 8
        visible: contentArea.visible
    }

    SequentialAnimation {
        id: pageFlipAnim
        property int targetPage: 0
        NumberAnimation { target: flipOverlay; property: "opacity"; to: 0.75; duration: 80 }
        ScriptAction { script: { if (pdfLoader.item) pdfLoader.item.goToPage(pageFlipAnim.targetPage) } }
        NumberAnimation { target: flipOverlay; property: "opacity"; to: 0;    duration: 180; easing.type: Easing.OutCubic }
    }

    PageLoader {
        id: pageLoader
        loadingText: "Загрузка книги..."
    }

    Keys.enabled: true
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_PageUp) {
            if (contentArea.fileType === "epub") {
                if (epubLoader.item) epubLoader.item.prevSection()
            } else {
                readerPage._programNav = true; presenter.prevPage()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_PageDown) {
            if (contentArea.fileType === "epub") {
                if (epubLoader.item) epubLoader.item.nextSection()
            } else {
                readerPage._programNav = true; presenter.nextPage()
            }
            event.accepted = true
        } else if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
                if (pdfLoader.item) { pdfLoader.item.zoomIn(); event.accepted = true }
            } else if (event.key === Qt.Key_Minus) {
                if (pdfLoader.item) { pdfLoader.item.zoomOut(); event.accepted = true }
            } else if (event.key === Qt.Key_0) {
                if (pdfLoader.item) { pdfLoader.item.resetZoom(); event.accepted = true }
            }
        }
    }

    Timer {
        id: _saveTimer
        interval: 1500
        repeat: false
        onTriggered: presenter.flushProgress()
    }

    Timer {
        id: _loadTimeoutTimer
        interval: 120000
        repeat: false
        onTriggered: {
            pageLoader.loading = false
            errorText.text    = "Превышено время загрузки. Проверьте соединение и попробуйте ещё раз."
            errorText.visible = true
        }
    }

    on_LoadCounterChanged: {
        if (_loadCounter <= 0) return
        presenter.flushProgress()
        _saveTimer.stop()
        contentArea.visible  = false
        contentArea.fileType = ""
        contentArea.filePath = ""
        errorText.visible    = false
        presenter.totalPages = bookTotalPages
        if (localFilePath !== "") {
            presenter.openLocalFile(localFilePath)
        } else if (bookId !== "") {
            pageLoader.loading = true
            _loadTimeoutTimer.restart()
            presenter.openBook(bookId, userBookId, startPage)
        }
    }

    Component.onDestruction: {
        _saveTimer.stop()
        presenter.flushProgress()
    }

    Component.onCompleted: {
        if (localFilePath !== "") {
            presenter.openLocalFile(localFilePath)
        } else if (bookId !== "") {
            pageLoader.loading = true
            _loadTimeoutTimer.restart()
            presenter.openBook(bookId, userBookId, startPage)
        }
    }
}
