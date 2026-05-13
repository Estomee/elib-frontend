// Presenter for employee management: loads employee list with positions and provides local CRUD operations.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal employeesLoaded()
    signal employeeAdded()
    signal employeeUpdated()
    signal employeeDeleted()
    signal operationFailed(string message)

    property bool isLoading: false

    property var employees:          []
    property var availablePositions: []

    function loadEmployees(searchText) {
        if (!TokenManager.hasValidToken()) return
        isLoading = true

        AdminService.loadPositions(
            function(posData) {
                availablePositions = posData.map(function(p) {
                    return { positionId: String(p.position_id), title: p.title }
                })
            },
            function() {}
        )

        AdminService.loadEmployees(
            function(data) {
                var result = []
                for (var i = 0; i < data.length; i++) {
                    var e = data[i]
                    var u = e.user  || {}
                    var p = e.position || {}
                    if (searchText) {
                        var t    = searchText.toLowerCase()
                        var full = ((u.last_name || "") + " " + (u.first_name || "") + " " + (u.middle_name || "")).toLowerCase()
                        if (!full.includes(t) && !(u.email || "").toLowerCase().includes(t)) continue
                    }
                    result.push({
                        employeeId:      String(e.employee_id),
                        userId:          String(u.user_id || ""),
                        firstName:       u.first_name  || "",
                        lastName:        u.last_name   || "",
                        middleName:      u.middle_name || "",
                        email:           u.email       || "",
                        phone:           u.phone       || "",
                        positionId:      String(p.position_id || ""),
                        positionTitle:   p.title        || "",
                        hireDate:        e.hire_date    || "",
                        terminationDate: e.termination_date || "",
                        passportNumber:  e.passport_number  || "",
                        passportSeries:  e.passport_series  || ""
                    })
                }
                employees = result
                isLoading = false
                employeesLoaded()
            },
            function(msg) {
                isLoading = false
                operationFailed(msg)
            }
        )
    }

    function addEmployee(input) {
        var arr = employees.slice()
        arr.push(Object.assign({ employeeId: String(Date.now()) }, input))
        employees = arr
        employeeAdded()
    }

    function updateEmployee(employeeId, input) {
        var arr = employees.slice()
        for (var i = 0; i < arr.length; i++) {
            if (arr[i].employeeId === employeeId) {
                arr[i] = Object.assign({}, arr[i], input)
                break
            }
        }
        employees = arr
        employeeUpdated()
    }

    function deleteEmployee(employeeId) {
        employees = employees.filter(function(e) { return e.employeeId !== employeeId })
        employeeDeleted()
    }
}
