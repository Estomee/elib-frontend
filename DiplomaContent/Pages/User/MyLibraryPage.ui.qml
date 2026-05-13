// User library page with reading/finished tabs, local book upload, and book detail popup.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Pdf
import ".."
import DiplomaContent.Network
import DiplomaContent.UI_Elements
import DiplomaContent.Navigation
import DiplomaContent.Presenters
import DiplomaContent.Components

BasePage {
    id: myLibraryPage

    ReaderPage { id: readerPage; visible: false; allowLocalFile: true }

    NotificationToast {
        id: libToast
        anchors.top: parent.top; anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        z: 300
    }

    MyLibraryPresenter {
        id: presenter

        onBooksLoaded: {
            readingModel.clear()
            finishedModel.clear()
            for (var i = 0; i < presenter.readingBooks.length; i++)
                readingModel.append(presenter.readingBooks[i])
            for (var j = 0; j < presenter.finishedBooks.length; j++)
                finishedModel.append(presenter.finishedBooks[j])
        }
        onBookRemovedSuccess: {
            presenter.loadLibrary("")
        }
        onBookRemovedFailed: function(message) {
            libToast.show(message || "Не удалось удалить книгу.", "error")
        }
        onLoadFailed: function(message) {
            libToast.show(message || "Не удалось загрузить библиотеку. Проверьте подключение.", "error")
        }
        onLocalBookAdded: {
            presenter.loadLibrary("")
        }
    }

    PdfDocument {
        id: metaPdfDoc
        onStatusChanged: {
            if (metaPdfDoc.status === PdfDocument.Ready) {
                if (localMeta.titleField  && metaPdfDoc.title  !== "")  localMeta.titleField.text  = metaPdfDoc.title
                if (localMeta.authorField && metaPdfDoc.author !== "")  localMeta.authorField.text = metaPdfDoc.author
                if (localMeta.yearField) {
                    var d = metaPdfDoc.creationDate
                    if (d) {
                        var yr = new Date(d).getFullYear()
                        if (yr > 1000 && yr <= new Date().getFullYear())
                            localMeta.yearField.text = yr.toString()
                    }
                }
                if (localMeta.titleField && localMeta.titleField.text === "") {
                    var raw  = localMeta.filePath.replace(/\\/g, "/")
                    var fname = raw.split("/").pop()
                    var titleFromFile = fname.replace(/\.[^.]+$/, "")
                    if (titleFromFile !== "") localMeta.titleField.text = titleFromFile
                }
            }
            if (metaPdfDoc.status === PdfDocument.Ready || metaPdfDoc.status === PdfDocument.Error)
                localMetaPopup.visible = true
        }
    }

    FileDialog {
        id: localFileDialog
        title: "Выберите книгу (PDF или EPUB)"
        nameFilters: ["Книги (*.pdf *.epub)", "PDF (*.pdf)", "EPUB (*.epub)"]
        onAccepted: {
            localMeta.filePath = selectedFile.toString()
            _clearLocalMeta()
            var path = selectedFile.toString().toLowerCase()
            if (path.indexOf(".pdf") !== -1) {
                metaPdfDoc.source = ""
                metaPdfDoc.source = selectedFile
            } else {
                localMetaPopup.visible = true
            }
        }
    }

    Item {
        id: localMetaPopup
        visible: false
        anchors.fill: parent
        z: 200

        NumberAnimation { id: metaFadeAnim;  target: localMetaPopup; property: "opacity"; from: 0; to: 1;    duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { id: metaScaleAnim; target: metaCard;       property: "scale";   from: 0.90; to: 1; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.5 }

        onVisibleChanged: {
            if (visible) {
                metaFadeAnim.start()
                metaScaleAnim.start()
            }
        }

        Rectangle {
            anchors.fill: parent; color: "#000000"; opacity: 0.70
            MouseArea { anchors.fill: parent }
        }

        Rectangle {
            id: metaCard
            anchors.centerIn: parent
            width: 440; height: localMetaCol.implicitHeight + 52
            color: "#0D3030"; radius: 20; border.color: "#2E6054"; border.width: 2

            Column {
                id: localMetaCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 28
                width: parent.width - 48
                spacing: 14

                Text {
                    text: "Добавить локальную книгу"
                    font.family: "Montserrat"; font.pixelSize: 18; font.bold: true; color: "#DAF1DE"
                }
                Rectangle { width: parent.width; height: 1; color: "#235347" }

                Repeater {
                    model: [
                        { label: "Название *", id: "title",  hint: "Введите название"  },
                        { label: "Автор",      id: "author", hint: "Введите автора"    },
                        { label: "Жанр",       id: "genre",  hint: "Жанр (необяз.)"   },
                        { label: "Год",        id: "year",   hint: "Год издания"       }
                    ]
                    delegate: Column {
                        width: parent.width; spacing: 4
                        Text { text: modelData.label; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                        MainTextField {
                            objectName: "localMeta_" + modelData.id
                            width: parent.width; height: 40
                            hint: modelData.hint; hintTextSize: 12; mainTextSize: 13
                            Component.onCompleted: {
                                if      (modelData.id === "title")  localMeta.titleField  = this
                                else if (modelData.id === "author") localMeta.authorField = this
                                else if (modelData.id === "genre")  localMeta.genreField  = this
                                else if (modelData.id === "year")   localMeta.yearField   = this
                            }
                        }
                    }
                }

                Text {
                    id: localMetaError
                    visible: false; text: ""
                    color: "#F44336"; font.family: "Montserrat"; font.pixelSize: 12
                }

                Row {
                    width: parent.width; spacing: 12
                    MainButton {
                        width: (parent.width - 12) / 2; height: 42
                        buttonText: "Добавить"; buttonTextSize: 11
                        onClicked: {
                            if (!localMeta.titleField || localMeta.titleField.text.trim() === "") {
                                localMetaError.text = "Введите название книги"; localMetaError.visible = true; return
                            }
                            localMetaError.visible = false
                            presenter.addLocalBook({
                                title:  localMeta.titleField  ? localMeta.titleField.text.trim()  : "",
                                author: localMeta.authorField ? localMeta.authorField.text.trim() : "",
                                genre:  localMeta.genreField  ? localMeta.genreField.text.trim()  : "",
                                year:   localMeta.yearField   ? localMeta.yearField.text.trim()   : "0"
                            }, localMeta.filePath)
                            _clearLocalMeta()
                            localMetaPopup.visible = false
                        }
                    }
                    MainButton {
                        width: (parent.width - 12) / 2; height: 42
                        buttonText: "Отмена"; buttonTextSize: 11
                        onClicked: { _clearLocalMeta(); localMetaPopup.visible = false }
                    }
                }
                Item { width: 1; height: 4 }
            }
        }
    }

    QtObject {
        id: localMeta
        property string filePath: ""
        property var titleField:  null
        property var authorField: null
        property var genreField:  null
        property var yearField:   null
    }

    function _clearLocalMeta() {
        if (localMeta.titleField)  localMeta.titleField.text  = ""
        if (localMeta.authorField) localMeta.authorField.text = ""
        if (localMeta.genreField)  localMeta.genreField.text  = ""
        if (localMeta.yearField)   localMeta.yearField.text   = ""
        localMetaError.visible = false
    }

    ConfirmDialog {
        id: removeDialog
        title: "Удалить книгу?"
        message: "Книга будет удалена из вашей библиотеки.\nПрогресс чтения будет потерян."
        confirmText: "Удалить"
        confirmType: "danger"

        property string pendingBookId: ""

        onConfirmed: presenter.removeBook(pendingBookId)
    }

    Item {
        id: bookDetailPopup
        visible: false
        anchors.fill: parent
        z: 190

        property var book: null

        NumberAnimation { id: libFadeAnim;  target: bookDetailPopup; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { id: libScaleAnim; target: libPopupCard;    property: "scale";   from: 0.90; to: 1; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 0.6 }

        onVisibleChanged: {
            if (visible) { libFadeAnim.start(); libScaleAnim.start() }
        }

        Rectangle {
            anchors.fill: parent; color: "#000000"; opacity: 0.70
            MouseArea { anchors.fill: parent; onClicked: bookDetailPopup.visible = false }
        }

        Rectangle {
            id: libPopupCard
            anchors.centerIn: parent
            width: 520
            height: libDetailCol.implicitHeight + 52
            color: "#0B2B26"; radius: 20
            border.color: "#2E6054"; border.width: 2

            Column {
                id: libDetailCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 32
                width: parent.width - 56
                spacing: 16

                Row {
                    width: parent.width; spacing: 20

                    Rectangle {
                        width: 90; height: 120; radius: 10
                        color: "#163832"; border.color: "#235347"; border.width: 2
                        layer.enabled: true
                        clip: true

                        Image {
                            id: popupCoverImg
                            anchors.fill: parent
                            anchors.margins: 2
                            source: bookDetailPopup.book && bookDetailPopup.book.coverPath
                                    ? bookDetailPopup.book.coverPath : ""
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width:  86
                            sourceSize.height: 116
                            mipmap: true
                            asynchronous: true
                            cache: false
                            visible: source !== ""
                            property bool everLoaded: false
                            opacity: (status === Image.Ready || everLoaded) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                            onStatusChanged: if (status === Image.Ready) everLoaded = true
                            onSourceChanged: everLoaded = false
                        }

                        Column {
                            anchors.centerIn: parent; spacing: 6
                            visible: !popupCoverImg.source || popupCoverImg.status === Image.Error
                            Repeater {
                                model: 4
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 44 - index * 10; height: 4; radius: 2
                                    color: "#8EB69B"; opacity: 0.85 - index * 0.15
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width - 110; spacing: 8
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            width: parent.width
                            text: bookDetailPopup.book ? bookDetailPopup.book.title : ""
                            font.family: "Montserrat"; font.pixelSize: 18; font.bold: true
                            color: "#DAF1DE"; wrapMode: Text.WordWrap
                        }
                        Text {
                            width: parent.width
                            text: bookDetailPopup.book ? bookDetailPopup.book.author : ""
                            font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: "#235347" }

                Row {
                    spacing: 24
                    Repeater {
                        model: bookDetailPopup.book ? [
                            { label: "Жанр",     val: bookDetailPopup.book.genre || "—" },
                            { label: "Год",      val: bookDetailPopup.book.year ? bookDetailPopup.book.year.toString() : "—" },
                            { label: "Прогресс", val: bookDetailPopup.book.totalPages > 0
                                ? "стр. " + bookDetailPopup.book.lastPage + " / " + bookDetailPopup.book.totalPages
                                : (bookDetailPopup.book.readProgress || 0) + "%" }
                        ] : []
                        delegate: Column {
                            spacing: 4
                            Text { text: modelData.label; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                            Text { text: modelData.val;   font.family: "Montserrat"; font.pixelSize: 13; font.bold: true; color: "#DAF1DE" }
                        }
                    }
                }

                Row {
                    width: parent.width; spacing: 12

                    MainButton {
                        width: (parent.width - 12) / 2; height: 44
                        buttonText: "Читать"; buttonTextSize: 11
                        onClicked: {
                            var b = bookDetailPopup.book
                            readerPage.userBookId    = b.userBookId   || 0
                            readerPage.startPage     = b.lastPage    || 1
                            readerPage.bookTotalPages = b.totalPages  || 0
                            readerPage.bookTitle     = b.title
                            readerPage.bookAuthor    = b.author
                            if (b.isLocal && b.localPath) {
                                readerPage.localFilePath  = b.localPath
                                readerPage.allowLocalFile = true
                            } else {
                                readerPage.localFilePath  = ""
                                readerPage.allowLocalFile = false
                            }
                            readerPage.bookId = b.bookId
                            readerPage._loadCounter++
                            bookDetailPopup.visible = false
                            NavigationModule.push(readerPage)
                        }
                    }
                    MainButton {
                        width: (parent.width - 12) / 2; height: 44
                        buttonText: "Закрыть"; buttonTextSize: 11
                        onClicked: bookDetailPopup.visible = false
                    }
                }
                Item { width: 1; height: 4 }
            }
        }
    }

    Image {
        anchors.fill: parent
        source: backgroundImage
        fillMode: Image.PreserveAspectCrop
        mipmap: true; smooth: true
    }
    Rectangle { anchors.fill: parent; color: "#051F20"; opacity: 0.88 }

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80

        Rectangle { anchors.fill: parent; color: "#051F20"; opacity: 0.85 }

        HeadingText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 36
            text: "Моя библиотека"
            size: 32
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 36
            spacing: 12

            MainButton {
                width: 180; height: 44
                buttonText: "+ Загрузить локально"
                buttonTextSize: 10
                onClicked: localFileDialog.open()
            }
            MainButton {
                width: 120; height: 44
                buttonText: "← Назад"
                buttonTextSize: 11
                onClicked: NavigationModule.pop()
            }
        }
    }

    Item {
        id: tabBar
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 54

        property int currentTab: 0

        Rectangle { anchors.fill: parent; color: "#0B2B26" }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 36

            Repeater {
                model: ["Читаю (" + readingModel.count + ")", "Прочитано (" + finishedModel.count + ")"]

                delegate: Item {
                    width: 200; height: tabBar.height

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: "Montserrat"
                        font.pixelSize: 15
                        font.bold: tabBar.currentTab === index
                        color: tabBar.currentTab === index ? "#DAF1DE" : "#8EB69B"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Rectangle {
                        visible: tabBar.currentTab === index
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 120; height: 3
                        color: "#8EB69B"
                        radius: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tabBar.currentTab = index
                    }
                }
            }
        }
    }

    Item {
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24

        ScrollView {
            anchors.fill: parent
            visible: tabBar.currentTab === 0
            clip: true

            GridView {
                id: readingGrid
                width: parent.width
                cellWidth: 210; cellHeight: 320
                model: readingModel
                delegate: _bookDelegate

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "scale";  from: 0.85; to: 1; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 0.4 }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
                    NumberAnimation { property: "scale";  from: 1; to: 0.85; duration: 200 }
                }
            }
        }

        ScrollView {
            anchors.fill: parent
            visible: tabBar.currentTab === 1
            clip: true

            GridView {
                id: finishedGrid
                width: parent.width
                cellWidth: 210; cellHeight: 320
                model: finishedModel
                delegate: _bookDelegate

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "scale";  from: 0.85; to: 1; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 0.4 }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
                    NumberAnimation { property: "scale";  from: 1; to: 0.85; duration: 200 }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 16
            visible: !presenter.isLoading &&
                     ((tabBar.currentTab === 0 && readingModel.count === 0) ||
                      (tabBar.currentTab === 1 && finishedModel.count === 0))

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tabBar.currentTab === 0 ? "Вы пока не читаете ни одной книги" : "Вы ещё не закончили ни одной книги"
                font.family: "Montserrat"; font.pixelSize: 18
                color: "#8EB69B"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Откройте каталог и выберите книгу"
                font.family: "Montserrat"; font.pixelSize: 14
                color: "#8EB69B"; opacity: 0.7
            }
        }
    }

    Component {
        id: _bookDelegate

        Item {
            width: 210; height: 320

            BookCard {
                anchors.centerIn: parent
                width: 185; height: 296
                title:        model.title
                author:       model.author
                genre:        model.genre
                year:         model.year
                bookId:       model.bookId
                coverSource:  model.coverPath || ""
                readProgress: model.readProgress || 0

                onReadClicked: function(id) {
                    var prog = (model.isLocal && model.localPath)
                        ? presenter.getLocalProgress(model.localPath)
                        : { page: model.lastPage || 1, total: model.totalPages || 0 }
                    bookDetailPopup.book = {
                        bookId:      model.bookId,
                        userBookId:  model.userBookId || 0,
                        title:       model.title,
                        author:      model.author,
                        genre:       model.genre,
                        year:        model.year,
                        coverPath:   model.coverPath || "",
                        readProgress: prog.total > 0
                            ? Math.round(prog.page / prog.total * 100)
                            : (model.readProgress || 0),
                        lastPage:    prog.page  || 1,
                        totalPages:  prog.total || 0,
                        isLocal:     model.isLocal || false,
                        localPath:   model.localPath || ""
                    }
                    bookDetailPopup.visible = true
                }
            }

            Rectangle {
                visible: model.isLocal || false
                anchors.top: parent.top; anchors.topMargin: 6
                anchors.left: parent.left; anchors.leftMargin: 12
                width: 54; height: 18; radius: 9
                color: "#1a3a6a"
                border.color: "#4a7aff"; border.width: 1
                z: 10
                Text {
                    anchors.centerIn: parent
                    text: "локал."
                    font.family: "Montserrat"; font.pixelSize: 9; font.bold: true; color: "#aad4ff"
                }
            }

            Item {
                width: 28; height: 28
                anchors.top: parent.top; anchors.topMargin: 2
                anchors.right: parent.right; anchors.rightMargin: 10
                z: 10

                Rectangle {
                    anchors.fill: parent; radius: 8
                    color: delHover.containsMouse ? "#7a1a1a" : "#5c1010"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"; color: "#DAF1DE"; font.pixelSize: 12
                    }
                }

                MouseArea {
                    id: delHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        removeDialog.pendingBookId = model.bookId
                        removeDialog.show("Удалить книгу?",
                            "«" + model.title + "» будет удалена из вашей библиотеки")
                    }
                }
            }
        }
    }

    PageLoader {
        id: pageLoader
        loading: presenter.isLoading
        loadingText: "Загрузка библиотеки..."
    }

    ListModel { id: readingModel  }
    ListModel { id: finishedModel }

    Connections {
        target: readerPage
        function onVisibleChanged() {
            if (!readerPage.visible && readerPage.bookId !== "")
                _updateBookProgress(readerPage.bookId,
                                    readerPage.currentReadingPage,
                                    readerPage.totalReadingPages)
        }
    }

    function _updateBookProgress(bookId, page, total) {
        var sid = String(bookId)
        for (var i = 0; i < readingModel.count; i++) {
            if (String(readingModel.get(i).bookId) === sid) {
                var progress = (total > 0) ? Math.round(page / total * 100) : 0
                var update = { lastPage: page, readProgress: progress }
                if (total > 0) update.totalPages = total
                readingModel.set(i, update)
                return
            }
        }
    }

    function refresh() {
        presenter.loadLibrary("")
    }
}
