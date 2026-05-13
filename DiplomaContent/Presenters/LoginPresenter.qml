// Presenter for the login screen: validates credentials and triggers authentication via AuthService.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal loginSuccess(string role)
    signal loginFailed(string message)

    property bool   isLoading:  false
    property bool   rememberMe: false

    readonly property string savedEmail: TokenManager.savedEmail

    function login(email, password, remember) {
        if (email.trim() === "" || password.trim() === "") {
            loginFailed("Введите email и пароль")
            return
        }

        rememberMe = remember
        isLoading  = true

        AuthService.login(email, password, remember,
            function(data) {
                isLoading = false
                var role = data.user.employee ? "admin" : "reader"
                HealthService.check()
                loginSuccess(role)
            },
            function(msg) {
                isLoading = false
                loginFailed(msg)
            }
        )
    }
}
