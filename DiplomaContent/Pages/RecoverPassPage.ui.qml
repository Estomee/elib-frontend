// Three-step password recovery page: request code, verify and reset, success confirmation.
import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements
import DiplomaContent.Navigation
import DiplomaContent.Presenters
import DiplomaContent.Services

BasePage {
    id: forgotPassPage

    RecoverPassPresenter {
        id: presenter

        onCodeRequested: {
            pageState = "step2"
            NotificationManager.success("Код отправлен на " + emailStep1.text)
        }
        onCodeSendFailed: function(message) {
            NotificationManager.error(message)
        }
        onPasswordResetSuccess: {
            pageState = "step3"
        }
        onPasswordResetFailed: function(message) {
            NotificationManager.error(message)
        }
    }

    property string pageState: "step1"

    StackView.onActivated: {
        pageState = "step1"
        presenter._pendingEmail = ""
        emailStep1.text        = ""
        codeField.text         = ""
        newPasswordField.text  = ""
        confirmPasswordField.text = ""
    }

    Image {
        anchors.fill: parent
        mipmap: true; smooth: true
        source: backgroundImage
        fillMode: Image.PreserveAspectCrop
    }

    Item {
        anchors.centerIn: parent
        width: 500
        height: formColumn.implicitHeight

        Column {
            id: formColumn
            width: parent.width
            spacing: 24

            HeadingText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Восстановление пароля"
                size: 38
            }

            Column {
                width: parent.width
                spacing: 18
                visible: forgotPassPage.pageState === "step1"

                Text {
                    width: parent.width
                    text: "Введите email, привязанный к аккаунту.\nМы отправим код восстановления."
                    font.family: "Montserrat"
                    font.pixelSize: 14
                    color: "#8EB69B"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                MainTextField {
                    id: emailStep1
                    width: parent.width
                    height: 55
                    hint: "Электронная почта"
                    hintTextSize: 15; mainTextSize: 15
                    maximumLength: 50
                    validator: RegularExpressionValidator {
                        regularExpression: /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
                    }
                    Keys.onReturnPressed: _sendCode()
                }

                MainButton {
                    width: parent.width; height: 58
                    buttonText: presenter.isLoading ? "Отправка..." : "Отправить код"
                    buttonTextSize: 12
                    enabled: !presenter.isLoading
                    onClicked: _sendCode()
                }
            }

            Column {
                width: parent.width
                spacing: 18
                visible: forgotPassPage.pageState === "step2"

                Text {
                    width: parent.width
                    text: "Введите 6-значный код из письма\nи установите новый пароль"
                    font.family: "Montserrat"
                    font.pixelSize: 14
                    color: "#8EB69B"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                MainTextField {
                    id: codeField
                    width: parent.width; height: 55
                    hint: "Код из письма (6 символов)"
                    hintTextSize: 15; mainTextSize: 15
                    maximumLength: 6
                    validator: RegularExpressionValidator {
                        regularExpression: /^[A-Za-z0-9]{0,6}$/
                    }
                }

                MainTextField {
                    id: newPasswordField
                    width: parent.width; height: 55
                    hint: "Новый пароль"
                    hintTextSize: 15; mainTextSize: 15
                    maximumLength: 40
                    echoMode: showPasswordSwitch2.checked ? TextInput.Normal : TextInput.Password
                    validator: RegularExpressionValidator {
                        regularExpression: /^[A-Za-zА-Яа-яЁё0-9!@#$%^&*().]{1,40}$/
                    }
                }

                MainTextField {
                    id: confirmPasswordField
                    width: parent.width; height: 55
                    hint: "Повторите пароль"
                    hintTextSize: 15; mainTextSize: 15
                    maximumLength: 40
                    echoMode: showPasswordSwitch2.checked ? TextInput.Normal : TextInput.Password
                    Keys.onReturnPressed: _resetPassword()
                }

                Row {
                    width: parent.width
                    Item { width: parent.width - showPasswordSwitch2.width; height: 1 }
                    MainSwitch {
                        id: showPasswordSwitch2
                        textSize: 12; text: "Показать пароль"
                    }
                }

                MainButton {
                    width: parent.width; height: 58
                    buttonText: presenter.isLoading ? "Сохранение..." : "Сохранить пароль"
                    buttonTextSize: 12
                    enabled: !presenter.isLoading
                    onClicked: _resetPassword()
                }

                HeadingText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Отправить код повторно"
                    size: 12
                    glowEnabled: true
                    onClicked: {
                        forgotPassPage.pageState = "step1"
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 24
                visible: forgotPassPage.pageState === "step3"

                Text {
                    width: parent.width
                    text: "✓"
                    font.pixelSize: 64
                    color: "#4CAF50"
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: "Пароль успешно изменён!\nМожете войти в систему."
                    font.family: "Montserrat"
                    font.pixelSize: 16
                    color: "#8EB69B"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                MainButton {
                    width: parent.width; height: 58
                    buttonText: "Войти"
                    buttonTextSize: 12
                    onClicked: NavigationModule.pop()
                }
            }
        }
    }

    MainButton {
        anchors.left: parent.left; anchors.leftMargin: 52
        anchors.bottom: parent.bottom; anchors.bottomMargin: 52
        buttonTextSize: 12; buttonText: "Назад"
        visible: forgotPassPage.pageState !== "step3"
        onClicked: {
            if (forgotPassPage.pageState === "step2") {
                forgotPassPage.pageState = "step1"
            } else {
                NavigationModule.pop()
            }
        }
    }

    function _sendCode() {
        presenter.requestCode(emailStep1.text)
    }

    function _resetPassword() {
        presenter.verifyAndReset(codeField.text, newPasswordField.text, confirmPasswordField.text)
    }
}
