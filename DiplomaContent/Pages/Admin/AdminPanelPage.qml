// Admin panel page with sidebar navigation, dashboard stats tiles, and section routing.
import QtQuick
import QtQuick.Controls.Basic
import ".."
import DiplomaContent.UI_Elements
import DiplomaContent.Navigation
import DiplomaContent.Components
import DiplomaContent.Network
import DiplomaContent.Api

BasePage {
    id: adminPanelPage

    property string adminName:  TokenManager.firstName + " " + TokenManager.lastName
    property string adminEmail: TokenManager.email
    property string _adminRole: ""

    property int _statBooks:   0
    property int _statUsers:   0
    property int _statReading: 0
    property int _statToday:   0

    function refresh() {
        _loadStats()
        switch (contentStack.currentSection) {
            case "books":     manageBooksView.reload();    break
            case "users":     manageUsersView.reload();    break
            case "employees": manageEmployeesView.reload(); break
            case "logs":      systemLogsView.reload();     break
            case "reference": manageReferenceView.reload(); break
        }
    }

    function _loadRole() {
        if (!TokenManager.hasValidToken()) return
        AdminService.loadMyRole(
            function(role) { adminPanelPage._adminRole = role || "" },
            function(msg)  { }
        )
    }

    function _loadStats() {
        if (!TokenManager.hasValidToken()) return
        AdminService.loadAdminStats(
            function(s) {
                _statBooks   = s.books_count    || 0
                _statUsers   = s.users_count    || 0
                _statReading = s.reading_now    || 0
                _statToday   = s.uploaded_today || 0
            },
            function(msg) { }
        )
    }

    Timer {
        id: statsRetryTimer
        interval: 800
        repeat: true
        property int _attempts: 0
        onTriggered: {
            if (_statBooks > 0 || _attempts >= 8) {
                repeat = false
                _attempts = 0
                return
            }
            _attempts++
            if (TokenManager.hasValidToken())
                adminPanelPage._loadStats()
        }
    }

    Component.onCompleted: { _loadStats(); _loadRole(); statsRetryTimer.start() }

    onVisibleChanged: {
        if (visible && TokenManager.hasValidToken()) {
            _loadStats()
            _loadRole()
            statsRetryTimer.start()
        }
    }

    Rectangle { anchors.fill: parent; color: "#051F20" }

    ConfirmDialog {
        id: adminLogoutDialog
        confirmText: "Выйти"
        confirmType: "danger"
        onConfirmed: NavigationModule.pop()
    }

    AdminSideBar {
        id: sidebar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        currentSection: contentStack.currentSection
        adminName: adminPanelPage.adminName
        adminEmail: adminPanelPage.adminEmail

        onSectionRequested: function(section) {
            contentStack.currentSection = section
        }
        onLogoutRequested: {
            adminLogoutDialog.show("Выйти из системы?", "Вы действительно хотите выйти из панели управления?")
        }
    }

    Item {
        id: contentArea
        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Item {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 58
            z: 10

            Rectangle {
                anchors.fill: parent; color: "#0B2B26"
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#163832" }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: 28
                text: {
                    switch(contentStack.currentSection) {
                        case "dashboard":  return "Панель управления"
                        case "books":      return "Управление книгами"
                        case "users":      return "Пользователи"
                        case "upload":     return "Загрузка книг"
                        case "logs":       return "Системные логи"
                        case "employees":  return "Сотрудники"
                        case "reference":  return "Справочники"
                        default:           return "Elib Admin"
                    }
                }
                font.family: "Montserrat"; font.pixelSize: 18; font.bold: true; color: "#DAF1DE"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right; anchors.rightMargin: 28
                text: adminPanelPage.adminName + (adminPanelPage._adminRole ? " · " + adminPanelPage._adminRole : "")
                font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"
            }
        }

        Item {
            id: contentStack
            anchors.top: topBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            property string currentSection: "dashboard"

            Item {
                anchors.fill: parent
                visible: contentStack.currentSection === "dashboard"
                onVisibleChanged: if (visible) adminPanelPage._loadStats()

                Column {
                    anchors.fill: parent; anchors.margins: 32; spacing: 28

                    HeadingText { text: "Добро пожаловать в панель управления"; size: 28 }

                    Row {
                        width: parent.width; spacing: 20

                        Repeater {
                            model: [
                                { label: "Книг в каталоге",  icon: "📚", idx: 0 },
                                { label: "Пользователей",     icon: "👥", idx: 1 },
                                { label: "Читают сейчас",     icon: "📖", idx: 2 },
                                { label: "Загружено сегодня", icon: "↑",  idx: 3 }
                            ]

                            delegate: Rectangle {
                                width: (parent.width - 60) / 4
                                height: 130
                                color: "#163832"; radius: 18
                                border.color: "#235347"; border.width: 2

                                Rectangle {
                                    anchors.fill: parent; anchors.topMargin: 6
                                    color: "#051F20"; radius: parent.radius; z: -1
                                }

                                Column {
                                    anchors.centerIn: parent; spacing: 10

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.icon; font.pixelSize: 32
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: {
                                            switch (modelData.idx) {
                                                case 0: return adminPanelPage._statBooks.toString()
                                                case 1: return adminPanelPage._statUsers.toString()
                                                case 2: return adminPanelPage._statReading.toString()
                                                case 3: return adminPanelPage._statToday.toString()
                                                default: return "0"
                                            }
                                        }
                                        font.family: "Montserrat"; font.pixelSize: 28; font.bold: true; color: "#DAF1DE"
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.label
                                        font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B"
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Быстрые действия"
                        font.family: "Montserrat"; font.pixelSize: 20; font.bold: true; color: "#DAF1DE"
                    }

                    Flow {
                        width: parent.width
                        spacing: 16

                        Repeater {
                            model: [
                                { label: "Загрузить книгу",  section: "upload"     },
                                { label: "Список книг",       section: "books"      },
                                { label: "Пользователи",      section: "users"      },
                                { label: "Сотрудники",        section: "employees"  },
                                { label: "Системные логи",    section: "logs"       },
                                { label: "Справочники",       section: "reference"  }
                            ]
                            delegate: MainButton {
                                width: 200; height: 52
                                buttonText: modelData.label; buttonTextSize: 11
                                onClicked: contentStack.currentSection = modelData.section
                            }
                        }
                    }
                }
            }

            Item {
                id: booksSection
                anchors.fill: parent
                visible: contentStack.currentSection === "books"
                opacity: 0
                onVisibleChanged: {
                    if (visible) {
                        booksSection.opacity = 0
                        sectionFadeBooks.restart()
                        manageBooksView.reload()
                    }
                }
                NumberAnimation { id: sectionFadeBooks; target: booksSection; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                ManageBooksView {
                    id: manageBooksView
                    anchors.fill: parent
                    onUploadRequested: contentStack.currentSection = "upload"
                }
            }

            Item {
                id: usersSection
                anchors.fill: parent
                visible: contentStack.currentSection === "users"
                opacity: 0
                onVisibleChanged: {
                    if (visible) { usersSection.opacity = 0; sectionFadeUsers.restart(); manageUsersView.reload() }
                }
                NumberAnimation { id: sectionFadeUsers; target: usersSection; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                ManageUsersView { id: manageUsersView; anchors.fill: parent }
            }

            Item {
                id: uploadSection
                anchors.fill: parent
                visible: contentStack.currentSection === "upload"
                opacity: 0
                onVisibleChanged: {
                    if (visible) {
                        uploadSection.opacity = 0
                        sectionFadeUpload.restart()
                        uploadBooksView.reload()
                    }
                }
                NumberAnimation { id: sectionFadeUpload; target: uploadSection; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                UploadBooksView {
                    id: uploadBooksView
                    anchors.fill: parent
                    onUploadSuccess: manageBooksView.reload()
                }
            }

            Item {
                id: logsSection
                anchors.fill: parent
                visible: contentStack.currentSection === "logs"
                opacity: 0
                onVisibleChanged: {
                    if (visible) { logsSection.opacity = 0; sectionFadeLogs.restart(); systemLogsView.reload() }
                }
                NumberAnimation { id: sectionFadeLogs; target: logsSection; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                SystemLogsView { id: systemLogsView; anchors.fill: parent }
            }

            Item {
                id: employeesSection
                anchors.fill: parent
                visible: contentStack.currentSection === "employees"
                opacity: 0
                onVisibleChanged: {
                    if (visible) { employeesSection.opacity = 0; sectionFadeEmployees.restart(); manageEmployeesView.reload() }
                }
                NumberAnimation { id: sectionFadeEmployees; target: employeesSection; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                ManageEmployeesView { id: manageEmployeesView; anchors.fill: parent }
            }

            Item {
                id: referenceSection
                anchors.fill: parent
                visible: contentStack.currentSection === "reference"
                opacity: 0
                onVisibleChanged: {
                    if (visible) { referenceSection.opacity = 0; sectionFadeReference.restart(); manageReferenceView.reload() }
                }
                NumberAnimation { id: sectionFadeReference; target: referenceSection; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                ManageReferenceView { id: manageReferenceView; anchors.fill: parent }
            }
        }
    }
}
