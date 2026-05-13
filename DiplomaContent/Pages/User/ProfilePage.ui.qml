// User profile page with view/edit mode, statistics display, and password change via SMS code.
import QtQuick
import QtQuick.Controls.Basic
import ".."
import DiplomaContent.Network
import DiplomaContent.UI_Elements
import DiplomaContent.Navigation
import DiplomaContent.Presenters
import DiplomaContent.Services

BasePage {
    id: profilePage

    property string userName: ""

    ProfilePresenter {
        id: presenter

        onProfileLoaded: {
            firstNameField.text  = presenter.firstName
            lastNameField.text   = presenter.lastName
            middleNameField.text = presenter.middleName
            emailDisplay.text    = presenter.email
            phoneField.text      = presenter.phone
            yearField.text       = presenter.yearOfBirth > 0 ? presenter.yearOfBirth.toString() : ""
        }
        onLoadFailed: function(message) {
            NotificationManager.error(message || "Не удалось загрузить профиль. Проверьте подключение.")
        }
        onProfileUpdated: {
            editMode = false
            NotificationManager.success("Профиль успешно обновлён")
        }
        onUpdateFailed: function(message) {
            NotificationManager.error(message)
        }
        onPasswordChanged: {
            passwordSection = false
            NotificationManager.success("Пароль успешно изменён")
        }
        onPasswordChangeFailed: function(message) {
            NotificationManager.error(message)
        }
        onSessionInvalid: NavigationModule.popToRoot()
    }

    property bool editMode:        false
    property bool passwordSection: false

    onPasswordSectionChanged: {
        if (!passwordSection) {
            newPassField.text     = ""
            confirmPassField.text = ""
            smsCodeField.text     = ""
            presenter.smsCodeSent = false
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
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 80

        Rectangle { anchors.fill: parent; color: "#051F20"; opacity: 0.85 }

        HeadingText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 36
            text: "Профиль"
            size: 32
        }

        MainButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 36
            width: 120; height: 44
            buttonText: "← Назад"
            buttonTextSize: 11
            onClicked: {
                profilePage.editMode        = false
                profilePage.passwordSection = false
                NavigationModule.pop()
            }
        }
    }

    ScrollView {
        anchors.top: header.bottom; anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right
        anchors.topMargin: 24
        clip: true

        Item {
            width: profilePage.width
            height: profileContent.implicitHeight + 60

            Column {
                id: profileContent
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(680, parent.width - 48)
                spacing: 24

                Row {
                    width: parent.width
                    spacing: 24

                    Rectangle {
                        width: 100; height: 100; radius: 50
                        color: "#163832"
                        border.color: "#235347"; border.width: 3

                        Text {
                            anchors.centerIn: parent
                            text: presenter.firstName.length > 0 ? presenter.firstName[0].toUpperCase() : "?"
                            font.family: "Montserrat"; font.pixelSize: 40; font.bold: true
                            color: "#DAF1DE"
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: presenter.firstName + " " + presenter.lastName
                            font.family: "Montserrat"; font.pixelSize: 24; font.bold: true
                            color: "#DAF1DE"
                        }

                        Text {
                            id: emailDisplay
                            text: presenter.email
                            font.family: "Montserrat"; font.pixelSize: 14
                            color: "#8EB69B"
                        }

                        Row {
                            spacing: 20

                            Row {
                                spacing: 8
                                Text { text: presenter.booksReading.toString(); font.family: "Montserrat"; font.pixelSize: 16; font.bold: true; color: "#DAF1DE" }
                                Text { text: "читаю"; font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Row {
                                spacing: 8
                                Text { text: presenter.booksRead.toString(); font.family: "Montserrat"; font.pixelSize: 16; font.bold: true; color: "#DAF1DE" }
                                Text { text: "прочитано"; font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: profileFormCol.implicitHeight + 32
                    color: "#163832"; radius: 16; border.color: "#235347"; border.width: 1

                    Column {
                        id: profileFormCol
                        anchors.fill: parent; anchors.margins: 20
                        spacing: 14

                        Item {
                            width: parent.width
                            height: 36

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                text: "Личные данные"
                                font.family: "Montserrat"; font.pixelSize: 16; font.bold: true; color: "#DAF1DE"
                            }

                            HeadingText {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                text: profilePage.editMode ? "Отмена" : "Редактировать"
                                size: 12
                                glowEnabled: true
                                onClicked: {
                                    if (profilePage.editMode) {
                                        presenter.loadProfile("")
                                    }
                                    profilePage.editMode = !profilePage.editMode
                                }
                            }
                        }

                        Row {
                            width: parent.width; spacing: 12

                            MainTextField {
                                id: firstNameField
                                width: (parent.width - 12) / 2; height: 50
                                hint: "Имя"; hintTextSize: 13; mainTextSize: 14
                                readOnly: !profilePage.editMode
                                opacity: profilePage.editMode ? 1 : 0.7
                                onTextEdited: {
                                    var f = text.replace(/[^A-Za-zА-ЯЁа-яё\-]/g, "")
                                    if (text !== f) { text = f; cursorPosition = f.length }
                                }
                            }
                            MainTextField {
                                id: lastNameField
                                width: (parent.width - 12) / 2; height: 50
                                hint: "Фамилия"; hintTextSize: 13; mainTextSize: 14
                                readOnly: !profilePage.editMode
                                opacity: profilePage.editMode ? 1 : 0.7
                                onTextEdited: {
                                    var f = text.replace(/[^A-Za-zА-ЯЁа-яё\-]/g, "")
                                    if (text !== f) { text = f; cursorPosition = f.length }
                                }
                            }
                        }

                        MainTextField {
                            id: middleNameField
                            width: parent.width; height: 50
                            hint: "Отчество"; hintTextSize: 13; mainTextSize: 14
                            readOnly: !profilePage.editMode
                            opacity: profilePage.editMode ? 1 : 0.7
                            onTextEdited: {
                                var f = text.replace(/[^A-Za-zА-ЯЁа-яё\-]/g, "")
                                if (text !== f) { text = f; cursorPosition = f.length }
                            }
                        }

                        Row {
                            width: parent.width; spacing: 12

                            MainTextField {
                                id: phoneField
                                width: (parent.width - 12) * 0.6; height: 50
                                hint: "+7 (___) ___-__-__"; hintTextSize: 13; mainTextSize: 14
                                maximumLength: 18
                                readOnly: !profilePage.editMode
                                opacity: profilePage.editMode ? 1 : 0.7
                                inputMethodHints: Qt.ImhDialableCharactersOnly

                                function formatPhone(digits) {
                                    if (digits.length === 0) return ""
                                    var r = "+" + digits.charAt(0)
                                    if (digits.length === 1) return r
                                    r += " (" + digits.substring(1, Math.min(4, digits.length))
                                    if (digits.length < 4) return r
                                    r += ")"
                                    if (digits.length === 4) return r
                                    r += " " + digits.substring(4, Math.min(7, digits.length))
                                    if (digits.length < 7) return r
                                    r += "-" + digits.substring(7, Math.min(9, digits.length))
                                    if (digits.length < 9) return r
                                    r += "-" + digits.substring(9, 11)
                                    return r
                                }

                                onTextEdited: {
                                    var raw = text
                                    if (raw.length > 0 && raw.charAt(0) !== '+' && /\d/.test(raw.charAt(0)))
                                        raw = "7" + raw
                                    var digits = raw.replace(/\D/g, "").substring(0, 11)
                                    if (digits.length === 0) { text = ""; return }
                                    var formatted = formatPhone(digits)
                                    if (text !== formatted) {
                                        text = formatted
                                        cursorPosition = formatted.length
                                    }
                                }
                            }
                            MainTextField {
                                id: yearField
                                width: (parent.width - 12) * 0.4; height: 50
                                hint: "Год рождения"; hintTextSize: 13; mainTextSize: 14
                                readOnly: !profilePage.editMode
                                opacity: profilePage.editMode ? 1 : 0.7
                                validator: IntValidator { bottom: 1900; top: 2010 }
                            }
                        }

                        MainButton {
                            width: parent.width; height: 52
                            buttonText: presenter.isLoading ? "Сохранение..." : "Сохранить изменения"
                            buttonTextSize: 12
                            visible: profilePage.editMode
                            enabled: !presenter.isLoading
                            onClicked: presenter.updateProfile(
                                firstNameField.text, lastNameField.text,
                                middleNameField.text, phoneField.text
                            )
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: passCol.implicitHeight + 32
                    color: "#163832"; radius: 16; border.color: "#235347"; border.width: 1

                    Column {
                        id: passCol
                        anchors.fill: parent; anchors.margins: 20
                        spacing: 14

                        Item {
                            width: parent.width; height: 36

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                text: "Смена пароля"
                                font.family: "Montserrat"; font.pixelSize: 16; font.bold: true; color: "#DAF1DE"
                            }

                            HeadingText {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                text: profilePage.passwordSection ? "Скрыть" : "Изменить"
                                size: 12; glowEnabled: true
                                onClicked: profilePage.passwordSection = !profilePage.passwordSection
                            }
                        }

                        Column {
                            id: passFormCol
                            width: parent.width
                            spacing: 14
                            visible: profilePage.passwordSection
                            opacity: profilePage.passwordSection ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                            MainTextField {
                                id: newPassField
                                width: parent.width; height: 50
                                hint: "Новый пароль"; hintTextSize: 13; mainTextSize: 14
                                echoMode: TextInput.Password
                            }
                            MainTextField {
                                id: confirmPassField
                                width: parent.width; height: 50
                                hint: "Повторите новый пароль"; hintTextSize: 13; mainTextSize: 14
                                echoMode: TextInput.Password
                            }

                            Column {
                                width: parent.width; spacing: 12
                                visible: presenter.smsCodeSent
                                opacity: presenter.smsCodeSent ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    width: parent.width; height: 44; radius: 12
                                    color: "#0D3030"; border.color: "#2E6054"; border.width: 1
                                    Row {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 10
                                        Text {
                                            text: "✓"
                                            font.pixelSize: 14; color: "#8EB69B"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "Код отправлен на " + presenter.email
                                            font.family: "Montserrat"; font.pixelSize: 13; color: "#8EB69B"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                MainTextField {
                                    id: smsCodeField
                                    width: parent.width; height: 50
                                    hint: "6-значный код из письма"; hintTextSize: 13; mainTextSize: 18
                                    validator: IntValidator { bottom: 0; top: 999999 }
                                    maximumLength: 6
                                }
                            }

                            Item {
                                width: parent.width; height: 52

                                MainButton {
                                    anchors.fill: parent
                                    visible: !presenter.smsCodeSent
                                    opacity: !presenter.smsCodeSent ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                    buttonText: presenter.isLoading ? "Отправка..." : "Получить код"
                                    buttonTextSize: 11
                                    enabled: !presenter.isLoading
                                    onClicked: presenter.sendSmsCode()
                                }

                                MainButton {
                                    anchors.fill: parent
                                    visible: presenter.smsCodeSent
                                    opacity: presenter.smsCodeSent ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                    buttonText: presenter.isLoading ? "Проверка..." : "Сменить пароль"
                                    buttonTextSize: 12
                                    enabled: !presenter.isLoading
                                    onClicked: presenter.changePassword(
                                        smsCodeField.text, newPassField.text, confirmPassField.text
                                    )
                                }
                            }
                        }
                    }
                }

                Item { width: 1; height: 24 }
            }
        }
    }

    function refresh() {
        firstNameField.text = presenter.firstName
        lastNameField.text  = presenter.lastName
        emailDisplay.text   = presenter.email
        presenter.loadProfile("")
    }

    Component.onCompleted: {
        if (!TokenManager.hasValidToken()) return
        firstNameField.text = presenter.firstName
        lastNameField.text  = presenter.lastName
        emailDisplay.text   = presenter.email
        presenter.loadProfile("")
    }
}
