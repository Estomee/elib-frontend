// Welcome page with registration form, auto-login on startup, and offline banner.
import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements
import DiplomaContent.Navigation
import DiplomaContent.Presenters
import DiplomaContent.Services
import DiplomaContent.Network
import DiplomaContent.Api

BasePage {
    id: welcomePage

    LoginPage { id: loginPage }

    property bool _pendingAutoLogin: false

    onVisibleChanged: {
        if (visible) _pendingAutoLogin = false
    }

    Component.onCompleted: {
        if (TokenManager.hasValidToken() && TokenManager.rememberMe) {
            _pendingAutoLogin = true
            loginPage.autoLogin(function(isNetworkErr) {
                welcomePage._pendingAutoLogin = false
                if (isNetworkErr)
                    offlineBanner.show("Сервер недоступен. Войдите повторно, когда соединение восстановится.")
            })
        }
    }

    WelcomePresenter {
        id: presenter

        onRegisterSuccess: {
            NotificationManager.success("Аккаунт создан! Войдите в систему.")
            NavigationModule.push(loginPage)
        }
        onRegisterFailed: function(message) {
            errorText.text = message
            errorText.opacity = 1
            shakeAnim.start()
        }
    }

    Image {
        id: backGround
        anchors.fill: parent
        mipmap: true; smooth: true
        source: backgroundImage
        fillMode: Image.PreserveAspectCrop
    }

    Column {
        anchors.centerIn: parent
        spacing: 18
        visible: welcomePage._pendingAutoLogin

        HeadingText { anchors.horizontalCenter: parent.horizontalCenter; text: "Elib"; size: 48 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Выполняется вход..."
            font.family: "Montserrat"; font.pixelSize: 16; color: "#8EB69B"
        }
    }

    Item {
        id: registrationFormContainer
        visible: !welcomePage._pendingAutoLogin
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.top: parent.top
        anchors.topMargin: 200
        width: Math.min(540, parent.width * 0.44)
        height: childrenRect.height

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: registrationFormContainer; property: "x"; to: anchors.leftMargin + 10; duration: 60 }
            NumberAnimation { target: registrationFormContainer; property: "x"; to: anchors.leftMargin - 10; duration: 60 }
            NumberAnimation { target: registrationFormContainer; property: "x"; to: anchors.leftMargin + 6;  duration: 50 }
            NumberAnimation { target: registrationFormContainer; property: "x"; to: anchors.leftMargin;       duration: 50 }
        }

        Column {
            id: registrationColumn
            width: parent.width
            spacing: 18

            HeadingText {
                id: createNewAccLabel
                height: 80
                text: "Создайте новый аккаунт"
                size: 44
            }

            Row {
                spacing: 6
                HeadingText {
                    text: "Уже зарегистрированы? "
                    size: 22
                    height: 50
                }
                HeadingText {
                    text: "Войти"
                    size: 22
                    height: 50
                    glowEnabled: true
                    onClicked: NavigationModule.push(loginPage)
                }
            }

            Item { width: 1; height: 6 }

            Row {
                width: parent.width
                spacing: 10
                MainTextField {
                    id: firstNameField
                    width: (parent.width - 10) / 2
                    hint: "Имя"
                    hintTextSize: 14; mainTextSize: 14
                    maximumLength: 30
                    onTextEdited: {
                        var f = text.replace(/[^A-Za-zА-ЯЁа-яё\-]/g, "")
                        if (text !== f) { text = f; cursorPosition = f.length }
                    }
                }
                MainTextField {
                    id: lastNameField
                    width: (parent.width - 10) / 2
                    hint: "Фамилия"
                    hintTextSize: 14; mainTextSize: 14
                    maximumLength: 30
                    onTextEdited: {
                        var f = text.replace(/[^A-Za-zА-ЯЁа-яё\-]/g, "")
                        if (text !== f) { text = f; cursorPosition = f.length }
                    }
                }
            }

            MainTextField {
                id: middleNameField
                width: parent.width
                hint: "Отчество (необязательно)"
                hintTextSize: 14; mainTextSize: 14
                maximumLength: 30
                onTextEdited: {
                    var f = text.replace(/[^A-Za-zА-ЯЁа-яё\-]/g, "")
                    if (text !== f) { text = f; cursorPosition = f.length }
                }
            }

            MainTextField {
                id: emailField
                width: parent.width
                hint: "Электронная почта"
                hintTextSize: 14; mainTextSize: 14
                maximumLength: 50
                validator: RegularExpressionValidator {
                    regularExpression: /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
                }
            }

            Row {
                width: parent.width
                spacing: 10
                MainTextField {
                    id: phoneField
                    width: (parent.width - 10) * 0.58
                    hint: "+7 (___) ___-__-__"
                    hintTextSize: 13; mainTextSize: 14
                    maximumLength: 18
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
                    width: (parent.width - 10) * 0.42
                    hint: "Год рождения"
                    hintTextSize: 13; mainTextSize: 14
                    maximumLength: 4
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 1900; top: 2010 }
                }
            }

            MainTextField {
                id: passwordField
                width: parent.width
                hint: "Пароль (не менее 6 символов)"
                hintTextSize: 14; mainTextSize: 14
                maximumLength: 40
                echoMode: showPasswordSwitch.checked ? TextInput.Normal : TextInput.Password
                validator: RegularExpressionValidator {
                    regularExpression: /^[A-Za-zА-Яа-яЁё0-9!@#$%^&*().]{1,40}$/
                }
            }

            MainSwitch {
                id: showPasswordSwitch
                textSize: 12
                text: "Показать пароль"
            }

            Text {
                id: errorText
                width: parent.width
                text: ""
                color: "#F44336"
                font.family: "Montserrat"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                opacity: 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }

            MainButton {
                id: createAccountButton
                width: parent.width
                height: 58
                buttonTextSize: 12
                buttonText: presenter.isLoading ? "Создание аккаунта..." : "Создать аккаунт"
                enabled: !presenter.isLoading
                onClicked: {
                    errorText.opacity = 0
                    presenter.register(
                        firstNameField.text.trim(),
                        lastNameField.text.trim(),
                        middleNameField.text.trim(),
                        emailField.text.trim(),
                        phoneField.text,
                        yearField.text,
                        passwordField.text
                    )
                }
            }
        }
    }

    Rectangle {
        id: offlineBanner
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: visible ? _bannerCol.implicitHeight + 24 : 0
        visible: false
        color: "#1a0000"
        z: 100

        property string _message: ""

        function show(msg) {
            _message = msg
            visible = true
        }

        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Column {
            id: _bannerCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 20
            spacing: 8

            Text {
                width: parent.width
                text: offlineBanner._message
                font.family: "Montserrat"; font.pixelSize: 13; color: "#FF7070"
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: 12
                MainButton {
                    width: 140; height: 36; buttonTextSize: 10; buttonText: "Повторить"
                    onClicked: {
                        offlineBanner.visible = false
                        welcomePage._pendingAutoLogin = true
                        loginPage.autoLogin(function(isNetworkErr) {
                            welcomePage._pendingAutoLogin = false
                            if (isNetworkErr)
                                offlineBanner.show("Сервер недоступен. Попробуйте позже.")
                        })
                    }
                }
                MainButton {
                    width: 100; height: 36; buttonTextSize: 10; buttonText: "Войти"
                    onClicked: {
                        offlineBanner.visible = false
                        NavigationModule.push(loginPage)
                    }
                }
            }
        }
    }
}
