// Presenter for reference data management: handles log levels and employee positions CRUD via AdminService.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal logLevelsLoaded()
    signal logLevelAdded()
    signal logLevelUpdated()
    signal logLevelDeleted()

    signal positionsLoaded()
    signal positionAdded()
    signal positionUpdated()
    signal positionDeleted()

    signal operationFailed(string message)

    property bool isLoading: false
    property var  logLevels: []
    property var  positions: []

    function loadLogLevels() {
        if (!TokenManager.hasValidToken()) return
        isLoading = true
        AdminService.loadLogLevels(
            function(data) {
                logLevels = data.map(function(l) {
                    return { levelId: String(l.level_id), levelName: l.level_name, color: l.color || "#8EB69B" }
                })
                isLoading = false
                logLevelsLoaded()
            },
            function(msg) { isLoading = false; operationFailed(msg) }
        )
    }

    function addLogLevel(levelName, color) {
        AdminService.createLogLevel(levelName, color,
            function(data) {
                var arr = logLevels.slice()
                arr.push({ levelId: String(data.level_id), levelName: data.level_name, color: data.color })
                logLevels = arr
                logLevelAdded()
            },
            function(msg) { operationFailed(msg) }
        )
    }

    function updateLogLevel(levelId, levelName, color) {
        AdminService.updateLogLevel(levelId, levelName, color,
            function(data) {
                var arr = logLevels.slice()
                for (var i = 0; i < arr.length; i++) {
                    if (arr[i].levelId === String(levelId)) {
                        arr[i] = { levelId: String(data.level_id), levelName: data.level_name, color: data.color }
                        break
                    }
                }
                logLevels = arr
                logLevelUpdated()
            },
            function(msg) { operationFailed(msg) }
        )
    }

    function deleteLogLevel(levelId) {
        AdminService.deleteLogLevel(levelId,
            function() {
                logLevels = logLevels.filter(function(l) { return l.levelId !== String(levelId) })
                logLevelDeleted()
            },
            function(msg) { operationFailed(msg) }
        )
    }

    function loadPositions() {
        if (!TokenManager.hasValidToken()) return
        AdminService.loadPositions(
            function(data) {
                positions = data.map(function(p) {
                    return {
                        positionId:  String(p.position_id),
                        title:       p.title,
                        salary:      p.salary || 0,
                        permissions: {
                            toRead:   p.permissions ? p.permissions.to_read   : false,
                            toWrite:  p.permissions ? p.permissions.to_write  : false,
                            toDelete: p.permissions ? p.permissions.to_delete : false,
                            toUpdate: p.permissions ? p.permissions.to_update : false
                        }
                    }
                })
                positionsLoaded()
            },
            function(msg) { operationFailed(msg) }
        )
    }

    function addPosition(input) {
        var apiInput = {
            title:  input.title || "",
            salary: parseFloat(input.salary) || 0,
            permissions: {
                to_read:   input.permissions ? input.permissions.toRead   : false,
                to_write:  input.permissions ? input.permissions.toWrite  : false,
                to_delete: input.permissions ? input.permissions.toDelete : false,
                to_update: input.permissions ? input.permissions.toUpdate : false
            }
        }
        AdminService.createPosition(apiInput,
            function(data) {
                var arr = positions.slice()
                arr.push(_mapPosition(data))
                positions = arr
                positionAdded()
            },
            function(msg) { operationFailed(msg) }
        )
    }

    function updatePosition(positionId, input) {
        var apiInput = {
            position_id: parseInt(positionId),
            title:       input.title || null,
            salary:      parseFloat(input.salary) || null,
            permissions: {
                to_read:   input.permissions ? input.permissions.toRead   : false,
                to_write:  input.permissions ? input.permissions.toWrite  : false,
                to_delete: input.permissions ? input.permissions.toDelete : false,
                to_update: input.permissions ? input.permissions.toUpdate : false
            }
        }
        AdminService.updatePosition(apiInput,
            function(data) {
                var arr = positions.slice()
                for (var i = 0; i < arr.length; i++) {
                    if (arr[i].positionId === String(positionId)) {
                        arr[i] = _mapPosition(data)
                        break
                    }
                }
                positions = arr
                positionUpdated()
            },
            function(msg) { operationFailed(msg) }
        )
    }

    function deletePosition(positionId) {
        AdminService.deletePosition(positionId,
            function() {
                positions = positions.filter(function(p) { return p.positionId !== String(positionId) })
                positionDeleted()
            },
            function(msg) { operationFailed(msg) }
        )
    }

    function _mapPosition(p) {
        return {
            positionId:  String(p.position_id),
            title:       p.title,
            salary:      p.salary || 0,
            permissions: {
                toRead:   p.permissions ? p.permissions.to_read   : false,
                toWrite:  p.permissions ? p.permissions.to_write  : false,
                toDelete: p.permissions ? p.permissions.to_delete : false,
                toUpdate: p.permissions ? p.permissions.to_update : false
            }
        }
    }
}
