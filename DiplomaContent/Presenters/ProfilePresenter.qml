// Presenter for the user profile screen: loads and updates profile data, manages email-based password change.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal profileLoaded()
    signal profileUpdated()
    signal updateFailed(string message)
    signal loadFailed(string message)
    signal passwordChanged()
    signal passwordChangeFailed(string message)
    signal codeSent()
    signal sessionInvalid()

    property bool   isLoading:    false
    property bool   smsCodeSent:  false
    property string firstName:    TokenManager.firstName
    property string lastName:     TokenManager.lastName
    property string middleName:   ""
    property string email:        TokenManager.email
    property string phone:        ""
    property int    yearOfBirth:  0
    property int    booksRead:    0
    property int    booksReading: 0

    function loadProfile(userId) {
        if (!TokenManager.hasValidToken()) return
        isLoading = true

        UserService.getMe(
            function(me) {
                if (!me) {
                    isLoading = false
                    loadFailed("Не удалось загрузить данные профиля")
                    return
                }
                firstName   = me.first_name    || TokenManager.firstName
                lastName    = me.last_name     || TokenManager.lastName
                middleName  = me.middle_name   || ""
                email       = me.email         || TokenManager.email
                phone       = me.phone         || ""
                yearOfBirth = me.year_of_birth || 0
                isLoading   = false
                profileLoaded()
                _loadBookCounts()
            },
            function(msg) {
                isLoading = false
                loadFailed(msg)
            }
        )
    }

    function _loadBookCounts() {
        LibraryService.loadUserBooks(TokenManager.userId, { first: 500, after: "" },
            function(data) {
                var reading = 0, finished = 0
                for (var i = 0; i < data.nodes.length; i++) {
                    if (data.nodes[i].status === "finished") finished++
                    else reading++
                }
                booksReading = reading
                booksRead    = finished
            },
            null
        )
    }

    function updateProfile(fName, lName, mName, ph) {
        if (fName.trim() === "" || lName.trim() === "") {
            updateFailed("Имя и фамилия обязательны")
            return
        }
        isLoading = true

        UserService.updateUser(TokenManager.userId,
            { first_name: fName, last_name: lName, middle_name: mName, phone: ph },
            function(data) {
                firstName  = data.first_name  || fName
                lastName   = data.last_name   || lName
                middleName = data.middle_name || mName
                phone      = data.phone       || ph
                isLoading  = false
                TokenManager.updateLocalUserInfo(firstName, lastName, "")
                profileUpdated()
            },
            function(msg) {
                isLoading = false
                updateFailed(msg)
            }
        )
    }

    function sendSmsCode() {
        if (email === "") {
            passwordChangeFailed("Email не привязан к аккаунту")
            return
        }
        isLoading = true

        AuthService.requestPasswordReset(email,
            function() {
                smsCodeSent = true
                isLoading   = false
                codeSent()
            },
            function(msg) {
                isLoading = false
                passwordChangeFailed(msg)
            }
        )
    }

    function changePassword(smsCode, newPass, confirmPass) {
        if (smsCode.trim() === "" || smsCode.length < 6) {
            passwordChangeFailed("Введите 6-значный код из письма")
            return
        }
        if (newPass !== confirmPass) {
            passwordChangeFailed("Пароли не совпадают")
            return
        }
        if (newPass.length < 6) {
            passwordChangeFailed("Пароль не менее 6 символов")
            return
        }
        isLoading = true

        UserService.changePasswordByEmailCode(smsCode, newPass,
            function() {
                smsCodeSent = false
                isLoading   = false
                passwordChanged()
            },
            function(msg) {
                isLoading = false
                passwordChangeFailed(msg)
            }
        )
    }
}
