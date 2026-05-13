// Presenter for user management: loads, filters, and updates user accounts via UserService.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal usersLoaded()
    signal userUpdated()
    signal operationFailed(string message)

    property bool isLoading: false
    property bool excludeEmployees: false

    property var users: []

    function _formatMoscow(iso) {
        if (!iso) return "—"
        var d = new Date(iso)
        if (isNaN(d.getTime())) return iso
        var m = new Date(d.getTime() + 3 * 60 * 60 * 1000)
        var pad = function(n) { return n < 10 ? "0" + n : String(n) }
        return pad(m.getUTCDate()) + "." + pad(m.getUTCMonth() + 1) + "." + m.getUTCFullYear()
            + " " + pad(m.getUTCHours()) + ":" + pad(m.getUTCMinutes())
    }

    function loadUsers(searchText) {
        if (!TokenManager.hasValidToken()) return
        isLoading = true

        UserService.loadUsers(
            { first: 50, after: "" },
            searchText || null,
            function(data) {
                var result = []
                for (var i = 0; i < data.nodes.length; i++) {
                    var u = data.nodes[i]
                    if (root.excludeEmployees && u.employee === true) continue
                    result.push({
                        userId:    String(u.user_id),
                        username:  u.username   || "",
                        email:     u.email      || "",
                        firstName: u.first_name || "",
                        lastName:  u.last_name  || "",
                        phone:     u.phone      || "",
                        regDate:   _formatMoscow(u.registration_date),
                        role:      u.employee   ? "admin" : "reader",
                        userType:  u.employee   ? "Сотрудник" : "Пользователь",
                        booksCount: 0
                    })
                }
                users     = result
                isLoading = false
                usersLoaded()
            },
            function(msg) {
                isLoading = false
                operationFailed(msg)
            }
        )
    }

    function updateUser(userId, firstName, lastName, email, phone, role, newPassword) {
        isLoading = true

        UserService.updateUser(parseInt(userId),
            { first_name: firstName, last_name: lastName, email: email, phone: phone },
            function(data) {
                for (var i = 0; i < users.length; i++) {
                    if (users[i].userId === userId) {
                        users[i].firstName = firstName
                        users[i].lastName  = lastName
                        users[i].email     = email
                        users[i].phone     = phone
                        if (role && role !== "") users[i].role = role
                        break
                    }
                }
                if (newPassword && newPassword !== "") {
                    UserService.resetUserPassword(parseInt(userId), newPassword, null, null)
                }
                isLoading = false
                userUpdated()
            },
            function(msg) {
                isLoading = false
                operationFailed(msg)
            }
        )
    }

    function getUserDetails(userId) {
        for (var i = 0; i < users.length; i++) {
            if (users[i].userId === userId) return users[i]
        }
        return null
    }
}
