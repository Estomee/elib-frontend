// Presenter for password recovery: requests an email code and verifies it to reset the password.
import QtQuick
import DiplomaContent.Api

QtObject {
    id: root

    signal codeRequested()
    signal codeSendFailed(string message)
    signal passwordResetSuccess()
    signal passwordResetFailed(string message)

    property bool   isLoading:     false
    property string _pendingEmail: ""

    function requestCode(email) {
        var emailRe = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        if (!emailRe.test(email)) {
            codeSendFailed("Некорректный адрес электронной почты")
            return
        }
        _pendingEmail = email
        isLoading = true

        AuthService.requestPasswordReset(email,
            function() {
                isLoading = false
                codeRequested()
            },
            function(msg) {
                isLoading = false
                codeSendFailed(msg)
            }
        )
    }

    function verifyAndReset(code, newPassword, confirmPassword) {
        if (newPassword !== confirmPassword) {
            passwordResetFailed("Пароли не совпадают")
            return
        }
        if (newPassword.length < 6) {
            passwordResetFailed("Пароль должен содержать не менее 6 символов")
            return
        }
        if (code.trim().length !== 6) {
            passwordResetFailed("Код должен содержать 6 символов")
            return
        }

        isLoading = true

        AuthService.resetPassword(_pendingEmail, code, newPassword,
            function() {
                isLoading = false
                passwordResetSuccess()
            },
            function(msg) {
                isLoading = false
                passwordResetFailed(msg)
            }
        )
    }
}
