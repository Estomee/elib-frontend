// Main user dashboard with side navigation, recent books section, and catalog shortcut.
import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements
import DiplomaContent.Navigation
import DiplomaContent.Presenters
import DiplomaContent.Components
import DiplomaContent.Network

BasePage {
    id: mainPage

    property string userName: (TokenManager.firstName + " " + TokenManager.lastName).trim() || "Пользователь"

    CatalogPage    { id: catalogPage    }
    MyLibraryPage  { id: myLibraryPage  }
    ProfilePage    { id: profilePage    }

    ConfirmDialog {
        id: logoutDialog
        confirmText: "Выйти"
        confirmType: "danger"
        onConfirmed: presenter.logout()
    }

    MainPresenter {
        id: presenter
        userName: mainPage.userName

        onLogoutRequested: {
            NavigationModule.pop()
        }
        onRecentBooksLoaded: {
            recentModel.clear()
            for (var i = 0; i < presenter.recentBooks.length; i++) {
                recentModel.append(presenter.recentBooks[i])
            }
        }
    }

    Image {
        anchors.fill: parent
        source: backgroundImage
        fillMode: Image.PreserveAspectCrop
        mipmap: true; smooth: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#051F20"
        opacity: 0.65
    }

    Rectangle {
        id: navPanel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 280
        color: "#0B2B26"
        border.color: "#051F20"
        border.width: 1

        Column {
            id: navTopSection
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            Item {
                width: parent.width; height: 100
                Rectangle { anchors.fill: parent; color: "#051F20" }
                Column {
                    anchors.centerIn: parent; spacing: 6
                    HeadingText { anchors.horizontalCenter: parent.horizontalCenter; text: "Elib"; size: 32 }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Электронная библиотека"
                        font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B"
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#163832" }
            Item { width: 1; height: 20 }

            Item {
                width: parent.width; height: 60
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    Text { text: "Добро пожаловать,"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    Text {
                        text: mainPage.userName
                        font.family: "Montserrat"; font.pixelSize: 16; font.bold: true; color: "#DAF1DE"
                        elide: Text.ElideRight; width: navPanel.width - 40
                    }
                }
            }

            Item { width: 1; height: 16 }
            Rectangle { width: parent.width - 28; height: 1; color: "#163832"; anchors.horizontalCenter: parent.horizontalCenter }
            Item { width: 1; height: 16 }

            Repeater {
                model: [
                    { label: "Каталог книг",   icon: "☰", page: "catalog"  },
                    { label: "Моя библиотека", icon: "♦", page: "library" },
                    { label: "Профиль",        icon: "◉", page: "profile"  }
                ]
                delegate: Item {
                    width: navPanel.width; height: 52
                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                        radius: 12
                        color: navBtn.containsMouse ? "#163832" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 16; spacing: 14
                            Text { text: modelData.icon; font.pixelSize: 20; color: "#8EB69B"; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData.label; font.family: "Montserrat"; font.pixelSize: 15; color: "#DAF1DE"; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: navBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.page === "catalog")      { catalogPage.userName = mainPage.userName; catalogPage.refresh(); NavigationModule.push(catalogPage) }
                                else if (modelData.page === "library") { myLibraryPage.refresh(); NavigationModule.push(myLibraryPage) }
                                else if (modelData.page === "profile") { profilePage.userName = mainPage.userName; profilePage.refresh(); NavigationModule.push(profilePage) }
                            }
                        }
                    }
                }
            }
        }

        Column {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            Rectangle { width: parent.width - 28; height: 1; color: "#163832"; anchors.horizontalCenter: parent.horizontalCenter }
            Item { width: 1; height: 10 }

            Item {
                width: navPanel.width; height: 48
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                    radius: 12
                    color: logoutBtn.containsMouse ? "#2a1010" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 16; spacing: 14
                        Text { text: "⏻"; font.pixelSize: 20; color: "#8B2020"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Выйти"; font.family: "Montserrat"; font.pixelSize: 15; color: "#8B2020"; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        id: logoutBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: logoutDialog.show("Выйти из системы?", "Вы действительно хотите выйти?")
                    }
                }
            }

            Item { width: 1; height: 16 }
        }
    }

    Item {
        id: contentArea
        anchors.left: navPanel.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 0

        Column {
            anchors.fill: parent
            anchors.margins: 36
            spacing: 32

            Column {
                width: parent.width
                spacing: 8

                HeadingText {
                    text: "Главная"
                    size: 40
                }

                Text {
                    text: "Продолжите читать или откройте что-то новое"
                    font.family: "Montserrat"; font.pixelSize: 16
                    color: "#8EB69B"
                }
            }

            Column {
                width: parent.width
                spacing: 16
                visible: recentModel.count > 0

                Text {
                    text: "Недавние книги"
                    font.family: "Montserrat"; font.pixelSize: 22; font.bold: true
                    color: "#DAF1DE"
                }

                ListView {
                    id: recentListView
                    width: parent.width
                    height: 310
                    orientation: ListView.Horizontal
                    spacing: 20
                    model: recentModel
                    clip: true

                    delegate: BookCard {
                        width: 172; height: 262
                        title:        model.title
                        author:       model.author
                        genre:        model.genre || ""
                        year:         model.year  || 0
                        bookId:       model.bookId
                        coverSource:  (model.coverPath && model.coverPath !== "") ? model.coverPath : ""
                        readProgress: model.readProgress || 0

                        onReadClicked: function(id) {
                            myLibraryPage.refresh()
                            NavigationModule.push(myLibraryPage)
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 120

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: "#163832"
                    border.color: "#235347"
                    border.width: 2

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 28
                        spacing: 6

                        Text {
                            text: "Каталог книг"
                            font.family: "Montserrat"; font.pixelSize: 22; font.bold: true
                            color: "#DAF1DE"
                        }
                        Text {
                            text: "Тысячи книг в вашем распоряжении"
                            font.family: "Montserrat"; font.pixelSize: 14
                            color: "#8EB69B"
                        }
                    }

                    MainButton {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right; anchors.rightMargin: 28
                        width: 180; height: 52
                        buttonText: "Открыть каталог"
                        buttonTextSize: 11
                        onClicked: {
                            catalogPage.userName = mainPage.userName
                            catalogPage.refresh()
                            NavigationModule.push(catalogPage)
                        }
                    }
                }
            }
        }
    }

    ListModel { id: recentModel }

    function refresh() {
        recentModel.clear()
        presenter.loadMainData("")
    }

    Component.onCompleted: { if (TokenManager.hasValidToken()) presenter.loadMainData("") }
}
