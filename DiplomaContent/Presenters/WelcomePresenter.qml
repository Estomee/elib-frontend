// Presenter for the welcome/registration screen: validates input and registers a new user via AuthService.
import QtQuick
import DiplomaContent.Api

QtObject {
    id: root

    signal registerSuccess()
    signal registerFailed(string message)

    property bool isLoading: false

    function register(firstName, lastName, middleName, email, phone, yearOfBirth, password) {
        var err = _validate(firstName, lastName, email, phone, yearOfBirth, password)
        if (err !== "") {
            registerFailed(err)
            return
        }

        isLoading = true

        AuthService.register(
            {
                first_name:   firstName,
                last_name:    lastName,
                middle_name:  middleName || null,
                email:        email,
                password:     password,
                username:     email,
                phone:        phone,
                year_of_birth: parseInt(yearOfBirth)
            },
            function(data) {
                isLoading = false
                registerSuccess()
            },
            function(msg) {
                isLoading = false
                registerFailed(_translateError(msg))
            }
        )
    }

    function _validate(firstName, lastName, email, phone, yearOfBirth, password) {
        if (firstName.trim() === "" || lastName.trim() === "")
            return "Введите имя и фамилию"
        var emailRe = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        if (!emailRe.test(email.trim()))
            return "Некорректный адрес электронной почты"
        var digits = phone.replace(/\D/g, "")
        if (digits.length !== 11)
            return "Введите корректный номер телефона (11 цифр)"
        var year = parseInt(yearOfBirth)
        if (isNaN(year) || year < 1900 || year > 2010)
            return "Введите корректный год рождения (1900–2010)"
        if (password.length < 6)
            return "Пароль должен содержать не менее 6 символов"
        return ""
    }

    function _translateError(msg) {
        if (!msg) return "Произошла ошибка. Попробуйте позже."
        if (msg.indexOf("уже") !== -1 || msg.indexOf("зарегистрирован") !== -1)
            return msg
        if (msg.indexOf("already") !== -1 || msg.indexOf("exist") !== -1)
            return "Пользователь с таким email уже зарегистрирован"
        if (msg.indexOf("required") !== -1 || msg.indexOf("missing") !== -1)
            return "Заполните все обязательные поля"
        if (msg.indexOf("invalid") !== -1)
            return "Некорректные данные"
        if (msg.indexOf("Internal") !== -1 || msg.indexOf("Error") !== -1)
            return "Произошла ошибка сервера. Попробуйте позже."
        return msg
    }
}
