// Singleton service that checks backend health endpoint and exposes database, storage, and email availability flags.
pragma Singleton
import QtQuick
import DiplomaContent.Network

QtObject {
    id: root

    signal checkCompleted()
    signal checkFailed(string message)

    property bool   isChecking:  false
    property bool   isChecked:   false

    property bool   isDatabaseReady: false
    property bool   isStorageReady:  false
    property bool   isEmailReady:    false
    property string storageBaseUrl:  ""

    readonly property string storageUnavailableMessage:
        "Файловое хранилище временно недоступно. Чтение и загрузка книг недоступны."
    readonly property string emailUnavailableMessage:
        "Сервис отправки писем недоступен. Смена пароля через email невозможна."
    readonly property string databaseUnavailableMessage:
        "База данных недоступна. Повторите попытку позже."

    function check() {
        if (isChecking) return
        isChecking = true

        var xhr = Qt.createQmlObject("import QtQuick; QtObject {}", root)
        var req = new XMLHttpRequest()

        req.open("GET", AppSettings.healthUrl, true)
        req.timeout = 10000

        req.onreadystatechange = function() {
            if (req.readyState !== XMLHttpRequest.DONE) return

            isChecking = false
            isChecked  = true

            if (req.status === 200) {
                try {
                    var data = JSON.parse(req.responseText)
                    isDatabaseReady = data.database === true
                    isStorageReady  = data.storage  === true
                    isEmailReady    = data.email     === true
                    storageBaseUrl  = data.storage_base_url || ""
                    checkCompleted()
                } catch (e) {
                    isDatabaseReady = true
                    isStorageReady  = true
                    isEmailReady    = true
                    checkCompleted()
                }
            } else if (req.status === 0) {
                isDatabaseReady = false
                isStorageReady  = false
                isEmailReady    = false
                checkFailed("Сервер недоступен. Проверьте подключение к интернету.")
            } else {
                isDatabaseReady = true
                isStorageReady  = true
                isEmailReady    = true
                checkCompleted()
            }
        }

        req.ontimeout = function() {
            isChecking      = false
            isChecked       = true
            isDatabaseReady = false
            isStorageReady  = false
            isEmailReady    = false
            checkFailed("Сервер не отвечает. Попробуйте позже.")
        }

        req.send()
    }

    function requireDatabase(onOk, notificationManager) {
        if (!isDatabaseReady) {
            if (notificationManager)
                notificationManager.showError(databaseUnavailableMessage)
            return
        }
        if (onOk) onOk()
    }

    function requireStorage(onOk, notificationManager) {
        if (!isStorageReady) {
            if (notificationManager)
                notificationManager.showError(storageUnavailableMessage)
            return
        }
        if (onOk) onOk()
    }

    function requireEmail(onOk, notificationManager) {
        if (!isEmailReady) {
            if (notificationManager)
                notificationManager.showError(emailUnavailableMessage)
            return
        }
        if (onOk) onOk()
    }
}
