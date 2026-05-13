// Book catalog page with grid view, infinite scroll, detail popup, and filter panel.
import QtQuick
import QtQuick.Controls.Basic
import ".."
import DiplomaContent.Api
import DiplomaContent.Network
import DiplomaContent.UI_Elements
import DiplomaContent.Navigation
import DiplomaContent.Presenters
import DiplomaContent.Components

BasePage {
    id: catalogPage

    property string userName: ""

    property bool _appendMode: false

    function _loadNextPage() {
        if (presenter.isLoading || !presenter.hasNextPage) return
        _appendMode = true
        presenter.nextPage()
    }

    ReaderPage { id: readerPage; visible: false; allowLocalFile: false }

    Item {
        id: bookDetailPopup
        visible: false
        anchors.fill: parent
        z: 200

        property var book: null

        NumberAnimation { id: popupFadeAnim;  target: bookDetailPopup; property: "opacity"; from: 0; to: 1;    duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { id: popupScaleAnim; target: popupCard;       property: "scale";   from: 0.90; to: 1; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 0.6 }

        onVisibleChanged: {
            if (visible) {
                popupFadeAnim.start()
                popupScaleAnim.start()
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"; opacity: 0.70
            MouseArea { anchors.fill: parent; onClicked: bookDetailPopup.visible = false }
        }

        Rectangle {
            id: popupCard
            anchors.centerIn: parent
            width: 560
            height: detailCol.implicitHeight + 52
            color: "#0B2B26"; radius: 20
            border.color: "#2E6054"; border.width: 2

            Column {
                id: detailCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 32
                width: parent.width - 56
                spacing: 16

                Row {
                    width: parent.width
                    spacing: 20

                    Rectangle {
                        width: 100; height: 140; radius: 10
                        color: "#163832"
                        border.color: "#235347"; border.width: 2
                        layer.enabled: true
                        clip: true

                        Image {
                            id: catalogPopupCoverImg
                            anchors.fill: parent
                            anchors.margins: 2
                            source: bookDetailPopup.book && bookDetailPopup.book.coverPath
                                    ? bookDetailPopup.book.coverPath : ""
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 96; sourceSize.height: 136
                            mipmap: true; asynchronous: true; cache: false
                            visible: source !== ""
                            property bool everLoaded: false
                            opacity: (status === Image.Ready || everLoaded) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                            onStatusChanged: if (status === Image.Ready) everLoaded = true
                            onSourceChanged: everLoaded = false
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            visible: !catalogPopupCoverImg.source || catalogPopupCoverImg.status === Image.Error
                            Repeater {
                                model: 4
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 52 - index * 12; height: 4; radius: 2
                                    color: "#8EB69B"
                                    opacity: 0.85 - index * 0.15
                                }
                            }
                        }

                        Text {
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: !catalogPopupCoverImg.source || catalogPopupCoverImg.status === Image.Error
                            text: {
                                if (!bookDetailPopup.book || !bookDetailPopup.book.author) return ""
                                var parts = bookDetailPopup.book.author.split(" ")
                                return parts.map(function(p) { return p.charAt(0) }).join("").substring(0, 2).toUpperCase()
                            }
                            font.family: "Montserrat"; font.pixelSize: 18; font.bold: true
                            color: "#DAF1DE"; opacity: 0.5
                        }
                    }

                    Column {
                        width: parent.width - 120
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            width: parent.width
                            text: bookDetailPopup.book ? bookDetailPopup.book.title : ""
                            font.family: "Montserrat"; font.pixelSize: 20; font.bold: true
                            color: "#DAF1DE"; wrapMode: Text.WordWrap
                        }
                        Text {
                            width: parent.width
                            text: bookDetailPopup.book ? bookDetailPopup.book.author : ""
                            font.family: "Montserrat"; font.pixelSize: 14; color: "#8EB69B"
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: "#235347" }

                Row {
                    spacing: 24
                    Repeater {
                        model: bookDetailPopup.book ? [
                            { label: "Жанр", val: bookDetailPopup.book.genre },
                            { label: "Год",  val: bookDetailPopup.book.year.toString() }
                        ] : []
                        delegate: Column {
                            spacing: 4
                            Text { text: modelData.label; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                            Text { text: modelData.val;   font.family: "Montserrat"; font.pixelSize: 13; font.bold: true; color: "#DAF1DE" }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: bookDetailPopup.book ? (bookDetailPopup.book.description || "Описание отсутствует.") : ""
                    font.family: "Montserrat"; font.pixelSize: 13; color: "#DAF1DE"
                    wrapMode: Text.WordWrap; lineHeight: 1.5
                }

                Row {
                    width: parent.width; spacing: 8
                    MainButton {
                        width: (parent.width - 16) / 3; height: 44
                        buttonText: "+ В библиотеку"; buttonTextSize: 10
                        onClicked: {
                            presenter.addToLibrary(bookDetailPopup.book.bookId)
                            bookDetailPopup.visible = false
                        }
                    }
                    MainButton {
                        width: (parent.width - 16) / 3; height: 44
                        buttonText: "Читать"; buttonTextSize: 11
                        onClicked: {
                            var b = bookDetailPopup.book
                            bookDetailPopup.visible = false
                            pageLoader.loading = true

                            LibraryService.addBookToLibrary(b.bookId,
                                function(data) {
                                    pageLoader.loading = false
                                    var ubId = (data && data.id) ? parseInt(data.id) : 0
                                    readerPage.userBookId     = ubId
                                    readerPage.startPage      = 1
                                    readerPage.bookTitle      = b.title
                                    readerPage.bookAuthor     = b.author
                                    readerPage.localFilePath  = ""
                                    readerPage.allowLocalFile = false
                                    readerPage.bookId         = b.bookId
                                    readerPage._loadCounter++
                                    NavigationModule.push(readerPage)
                                },
                                function(msg) {
                                    pageLoader.loading = false
                                    readerPage.userBookId     = 0
                                    readerPage.startPage      = 1
                                    readerPage.bookTitle      = b.title
                                    readerPage.bookAuthor     = b.author
                                    readerPage.localFilePath  = ""
                                    readerPage.allowLocalFile = false
                                    readerPage.bookId         = b.bookId
                                    readerPage._loadCounter++
                                    NavigationModule.push(readerPage)
                                }
                            )
                        }
                    }
                    MainButton {
                        width: (parent.width - 16) / 3; height: 44
                        buttonText: "Закрыть"; buttonTextSize: 11
                        onClicked: bookDetailPopup.visible = false
                    }
                }
                Item { width: 1; height: 4 }
            }
        }
    }

    CatalogPresenter {
        id: presenter

        onBooksLoaded: {
            if (!catalogPage._appendMode)
                booksModel.clear()
            for (var i = 0; i < presenter.books.length; i++) {
                booksModel.append(presenter.books[i])
            }
            catalogPage._appendMode = false
            pageLoader.loading = false
        }
        onLoadFailed: function(message) {
            catalogPage._appendMode = false
            pageLoader.loading = false
            catalogToast.show(message || "Не удалось загрузить каталог. Проверьте подключение.", "error")
        }
        onBookAddedToLibrary: function(isNew) {
            if (isNew)
                catalogToast.show("Книга добавлена в библиотеку", "success")
            else
                catalogToast.show("Книга уже есть в вашей библиотеке", "info")
        }
        onAddToLibraryFailed: function(message) {
            catalogToast.show(message, "error")
        }
    }

    NotificationToast {
        id: catalogToast
        anchors.top: parent.top; anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        z: 300
    }

    Image {
        anchors.fill: parent
        source: backgroundImage
        fillMode: Image.PreserveAspectCrop
        mipmap: true; smooth: true
    }
    Rectangle { anchors.fill: parent; color: "#051F20"; opacity: 0.70 }

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80

        Rectangle { anchors.fill: parent; color: "#051F20"; opacity: 0.85 }

        HeadingText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 36
            text: "Каталог книг"
            size: 32
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: backBtn.left
            anchors.rightMargin: 24
            text: presenter.totalCount > 0
                  ? "Загружено: " + booksModel.count + " из " + presenter.totalCount
                  : ""
            font.family: "Montserrat"; font.pixelSize: 14
            color: "#8EB69B"
        }

        MainButton {
            id: backBtn
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 36
            width: 120; height: 44
            buttonText: "← Назад"
            buttonTextSize: 11
            onClicked: NavigationModule.pop()
        }
    }

    FilterPanel {
        id: filterPanel
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        height: 70

        onSearchRequested: function(filters) {
            catalogPage._appendMode = false
            pageLoader.loading = true
            booksModel.clear()
            presenter.loadBooks(filters, "")
        }
        onResetRequested: {
            catalogPage._appendMode = false
            pageLoader.loading = true
            booksModel.clear()
            presenter.loadBooks({}, "")
        }
    }

    ScrollView {
        id: scrollView
        anchors.top: filterPanel.bottom
        anchors.topMargin: 20
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        clip: true

        GridView {
            id: booksGrid
            width: scrollView.width
            cellWidth: 190
            cellHeight: 280
            model: booksModel

            onAtYEndChanged: {
                if (atYEnd && !presenter.isLoading && presenter.hasNextPage)
                    catalogPage._loadNextPage()
            }

            footer: Item {
                width: booksGrid.width
                height: (presenter.isLoading && booksModel.count > 0) ? 56 : 0

                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: presenter.isLoading && booksModel.count > 0

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: "#8EB69B"
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 400 }
                            NumberAnimation { to: 1.0; duration: 400 }
                        }
                    }
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: "#8EB69B"
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 400 }
                            NumberAnimation { to: 1.0; duration: 400 }
                        }
                        OpacityAnimator on opacity { from: 1; to: 1; duration: 200 }
                    }
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: "#8EB69B"
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.0; duration: 400 }
                            NumberAnimation { to: 0.2; duration: 400 }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Загрузка..."
                        font.family: "Montserrat"; font.pixelSize: 13
                        color: "#8EB69B"
                    }
                }
            }

            delegate: Item {
                id: cardDelegate
                width: 190; height: 280

                opacity: 0
                Component.onCompleted: appearAnim.start()

                NumberAnimation {
                    id: appearAnim
                    target: cardDelegate
                    property: "opacity"
                    from: 0; to: 1
                    duration: 200 + (index % 20) * 20
                    easing.type: Easing.OutCubic
                }

                BookCard {
                    anchors.centerIn: parent
                    width: 172; height: 262
                    title:       model.title
                    author:      model.author
                    genre:       model.genre
                    year:        model.year
                    bookId:      model.bookId
                    coverSource: model.coverPath || ""

                    onReadClicked: function(id) {
                        bookDetailPopup.book = {
                            bookId:      model.bookId,
                            title:       model.title,
                            author:      model.author,
                            genre:       model.genre,
                            year:        model.year,
                            description: model.description || "",
                            coverPath:   model.coverPath   || ""
                        }
                        bookDetailPopup.visible = true
                    }
                    onAddToLibraryClicked: function(id) {
                        presenter.addToLibrary(id)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: booksModel.count === 0 && !pageLoader.loading
                text: "Книги не найдены.\nПопробуйте изменить фильтры."
                font.family: "Montserrat"; font.pixelSize: 16
                color: "#8EB69B"; horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    PageLoader {
        id: pageLoader
        loadingText: "Загрузка каталога..."
    }

    ListModel { id: booksModel }

    function refresh() {
        _appendMode = false
        booksModel.clear()
        pageLoader.loading = true
        presenter.loadBooks({}, "")
    }

    Component.onCompleted: {
        if (!TokenManager.hasValidToken()) return
        pageLoader.loading = true
        presenter.loadBooks({}, "")
    }
}
