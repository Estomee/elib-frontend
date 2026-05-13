// Login page with email/password form, auto-login support, and role-based navigation.
import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements
import DiplomaContent.Navigation
import DiplomaContent.Network
import DiplomaContent.Presenters
import DiplomaContent.Api

BasePage {
    id: loginPage

    RecoverPassPage   { id: recoverPassPage  }
    MainPage          { id: mainPage         }
    AdminPanelPage    { id: adminPanelPage   }

    LoginPresenter {
        id: presenter

        onLoginSuccess: function(role) {
            if (role === "admin") {
                NavigationModule.push(adminPanelPage)
            } else {
                mainPage.refresh()
                NavigationModule.push(mainPage)
            }
        }

        onLoginFailed: function(message) {
            errorText.text    = message
            errorText.visible = true
            shakeAnim.start()
        }
    }

    Image {
        anchors.fill: parent
        mipmap: true; smooth: true
        source: backgroundImage
        fillMode: Image.PreserveAspectCrop
    }

    Item {
        id: loginFormContainer
        anchors.centerIn: parent
        width: 500
        height: childrenRect.height

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: loginFormContainer; property: "x"; to: parent.width / 2 - 250 + 14; duration: 60 }
            NumberAnimation { target: loginFormContainer; property: "x"; to: parent.width / 2 - 250 - 14; duration: 60 }
            NumberAnimation { target: loginFormContainer; property: "x"; to: parent.width / 2 - 250 + 8;  duration: 50 }
            NumberAnimation { target: loginFormContainer; property: "x"; to: parent.width / 2 - 250;       duration: 50 }
        }

        Column {
            id: loginColumn
            width: parent.width
            spacing: 22

            HeadingText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Вход"
                size: 64
            }

            Item { width: 1; height: 8 }

            MainTextField {
                id: emailTextField
                width: parent.width
                height: 55
                hint: "Электронная почта"
                maximumLength: 50
                hintTextSize: 15; mainTextSize: 15
                validator: RegularExpressionValidator {
                    regularExpression: /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
                }
                Keys.onReturnPressed: passwordTextField.forceActiveFocus()
            }

            MainTextField {
                id: passwordTextField
                width: parent.width
                height: 55
                maximumLength: 40
                hint: "Пароль"
                hintTextSize: 15; mainTextSize: 15
                echoMode: showPasswordSwitch.checked ? TextInput.Normal : TextInput.Password
                validator: RegularExpressionValidator {
                    regularExpression: /^[A-Za-zА-Яа-яЁё0-9!@#$%^&*().]{1,40}$/
                }
                Keys.onReturnPressed: _doLogin()
            }

            Text {
                id: errorText
                width: parent.width
                visible: false
                text: ""
                color: "#F44336"
                font.family: "Montserrat"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width

                MainCheckbox {
                    id: rememberMeCheckbox
                    text: "Запомнить меня"
                    height: 34
                }

                Item { width: parent.width - rememberMeCheckbox.width - forgotPasswordLabel.width; height: 1 }

                HeadingText {
                    id: forgotPasswordLabel
                    height: 34
                    text: "Забыли пароль?"
                    size: 12
                    glowEnabled: true
                    onClicked: NavigationModule.push(recoverPassPage)
                }
            }

            Row {
                width: parent.width

                Item { width: parent.width - showPasswordSwitch.width; height: 1 }

                MainSwitch {
                    id: showPasswordSwitch
                    textSize: 12
                    text: "Показать пароль"
                }
            }

            Item { width: 1; height: 8 }

            MainButton {
                id: signInButton
                width: parent.width
                height: 60
                buttonTextSize: 12
                buttonText: presenter.isLoading ? "Вход..." : "Войти"
                enabled: !presenter.isLoading
                onClicked: _doLogin()
            }
        }
    }

    MainButton {
        id: backButton
        anchors.left: parent.left
        anchors.leftMargin: 52
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 52
        buttonTextSize: 12
        buttonText: "Назад"
        onClicked: NavigationModule.pop()
    }

    Component.onCompleted: {
        if (TokenManager.rememberMe && TokenManager.savedEmail !== "")
            emailTextField.text = TokenManager.savedEmail
    }

    function autoLogin(onFail, _retried) {
        UserService.getMe(
            function(me) {
                if (!me) { TokenManager.clearTokens(); if (onFail) onFail(false); return }
                if (TokenManager.isEmployee) {
                    NavigationModule.push(adminPanelPage)
                } else {
                    mainPage.refresh()
                    NavigationModule.push(mainPage)
                }
            },
            function(msg) {
                var isNetworkError = msg.indexOf("Сервер недоступен") !== -1
                    || msg.indexOf("не отвечает") !== -1
                    || msg.indexOf("подключения к серверу") !== -1
                    || msg.indexOf("Соединение") !== -1
                var isAuthError = msg.indexOf("Сессия") !== -1
                    || msg.indexOf("Войдите снова") !== -1
                    || msg.indexOf("UNAUTHORIZED") !== -1
                if (isNetworkError) {
                    if (onFail) onFail(true)
                    return
                }
                if (isAuthError && !_retried) {
                    AuthService.refreshToken(
                        function() { loginPage.autoLogin(onFail, true) },
                        function()  { TokenManager.clearTokens(); if (onFail) onFail(false) }
                    )
                    return
                }
                TokenManager.clearTokens()
                if (onFail) onFail(false)
            }
        )
    }

    function _doLogin() {
        errorText.visible = false
        presenter.login(emailTextField.text, passwordTextField.text, rememberMeCheckbox.checked)
    }
}
