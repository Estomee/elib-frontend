// Presenter for the system logs screen: loads and filters paginated log entries via AdminService.
import QtQuick
import DiplomaContent.Api
import DiplomaContent.Network

QtObject {
    id: root

    signal logsLoaded()
    signal loadFailed(string message)

    property bool isLoading: false
    property int  totalLogs: 0

    property var logs: []

    property string _endCursor: ""
    property bool   _hasMore:   false

    function _formatMoscow(iso) {
        if (!iso) return "—"
        var d = new Date(iso)
        if (isNaN(d.getTime())) return iso
        var m = new Date(d.getTime() + 3 * 60 * 60 * 1000)
        var pad = function(n) { return n < 10 ? "0" + n : String(n) }
        return pad(m.getUTCDate()) + "." + pad(m.getUTCMonth() + 1) + "." + m.getUTCFullYear()
            + " " + pad(m.getUTCHours()) + ":" + pad(m.getUTCMinutes()) + ":" + pad(m.getUTCSeconds())
    }

    function loadLogs(levelFilter, dateFrom, dateTo) {
        if (!TokenManager.hasValidToken()) return
        isLoading = true

        var filter = {}
        if (levelFilter && levelFilter !== "all") filter.level_name = levelFilter
        if (dateFrom) filter.date_from = dateFrom
        if (dateTo)   filter.date_to   = dateTo

        AdminService.loadSystemLogs(
            { first: 100, after: "" },
            filter,
            function(data) {
                var result = []
                for (var i = 0; i < data.nodes.length; i++) {
                    var entry = data.nodes[i]
                    result.push({
                        logId:     String(entry.log_id),
                        timestamp: _formatMoscow(entry.timestamp),
                        level:     entry.level ? entry.level.level_name : "info",
                        userId:    entry.user_id != null ? String(entry.user_id) : "—",
                        action:    entry.action,
                        ip:        entry.ip_address || "—"
                    })
                }
                logs      = result
                totalLogs = data.total_count
                _hasMore   = data.page_info ? data.page_info.has_next_page : false
                _endCursor = data.page_info ? (data.page_info.end_cursor || "") : ""
                isLoading  = false
                logsLoaded()
            },
            function(msg) {
                isLoading = false
                loadFailed(msg)
            }
        )
    }

    function filterByLevel(level) {
        if (level === "all") return logs
        return logs.filter(function(l) { return l.level === level })
    }
}
