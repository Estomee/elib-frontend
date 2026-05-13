// Singleton notification manager that emits a signal consumed by App.qml to display toast messages.
pragma Singleton
import QtQuick

QtObject {
    id: root

    signal notificationReady(string message, string type)

    function show(message, type) {
        notificationReady(message, type || "info")
    }

    function success(message) { notificationReady(message, "success") }
    function error(message)   { notificationReady(message, "error")   }
    function warning(message) { notificationReady(message, "warning") }
    function info(message)    { notificationReady(message, "info")    }
}
