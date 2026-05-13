// Singleton service for admin-only GraphQL operations: system logs, log levels, employees, and positions.
pragma Singleton
import QtQuick
import DiplomaContent.Network

QtObject {
    id: root

    function loadSystemLogs(pagination, filter, onSuccess, onError) {
        const q = `
            query SystemLogs($pagination: PaginationInput!, $filter: LogFilter) {
                system_logs(pagination: $pagination, filter: $filter) {
                    nodes {
                        log_id
                        timestamp
                        action
                        ip_address
                        user_id
                        level { level_id level_name color }
                    }
                    total_count
                    page_info { has_next_page end_cursor }
                }
            }
        `
        GraphQLClient.execute(q, { pagination: pagination, filter: filter || {} },
            function(data) { if (onSuccess) onSuccess(data.system_logs) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadAdminStats(onSuccess, onError) {
        const q = `
            query AdminStats {
                admin_stats {
                    books_count
                    users_count
                    reading_now
                    uploaded_today
                }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.admin_stats) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadLogLevels(onSuccess, onError) {
        const q = `
            query LogLevels {
                log_levels { level_id level_name color }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.log_levels) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function createLogLevel(levelName, color, onSuccess, onError) {
        const q = `
            mutation CreateLogLevel($levelName: String!, $color: String!) {
                create_log_level(level_name: $levelName, color: $color) {
                    level_id level_name color
                }
            }
        `
        GraphQLClient.execute(q, { levelName: levelName, color: color },
            function(data) { if (onSuccess) onSuccess(data.create_log_level) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function updateLogLevel(levelId, levelName, color, onSuccess, onError) {
        const q = `
            mutation UpdateLogLevel($levelId: Int!, $levelName: String!, $color: String!) {
                update_log_level(level_id: $levelId, level_name: $levelName, color: $color) {
                    level_id level_name color
                }
            }
        `
        GraphQLClient.execute(q, { levelId: parseInt(levelId), levelName: levelName, color: color },
            function(data) { if (onSuccess) onSuccess(data.update_log_level) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function deleteLogLevel(levelId, onSuccess, onError) {
        const q = `
            mutation DeleteLogLevel($levelId: Int!) {
                delete_log_level(level_id: $levelId)
            }
        `
        GraphQLClient.execute(q, { levelId: parseInt(levelId) },
            function(data) { if (onSuccess) onSuccess() },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadEmployees(onSuccess, onError) {
        const q = `
            query Employees {
                employees {
                    employee_id
                    hire_date
                    termination_date
                    passport_series
                    passport_number
                    user { user_id first_name last_name middle_name email phone }
                    position { position_id title salary }
                }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.employees) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadMyRole(onSuccess, onError) {
        const q = `
            query MyRole {
                my_employee_role
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.my_employee_role || "") },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadPositions(onSuccess, onError) {
        const q = `
            query Positions {
                positions {
                    position_id title salary
                    permissions { to_read to_write to_delete to_update }
                }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.positions) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function createPosition(input, onSuccess, onError) {
        const q = `
            mutation CreatePosition($input: CreatePositionInput!) {
                create_position(input: $input) {
                    position_id title salary
                    permissions { to_read to_write to_delete to_update }
                }
            }
        `
        GraphQLClient.execute(q, { input: input },
            function(data) { if (onSuccess) onSuccess(data.create_position) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function updatePosition(input, onSuccess, onError) {
        const q = `
            mutation UpdatePosition($input: UpdatePositionInput!) {
                update_position(input: $input) {
                    position_id title salary
                    permissions { to_read to_write to_delete to_update }
                }
            }
        `
        GraphQLClient.execute(q, { input: input },
            function(data) { if (onSuccess) onSuccess(data.update_position) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function deletePosition(positionId, onSuccess, onError) {
        const q = `
            mutation DeletePosition($positionId: Int!) {
                delete_position(position_id: $positionId)
            }
        `
        GraphQLClient.execute(q, { positionId: parseInt(positionId) },
            function(data) { if (onSuccess) onSuccess() },
            function(msg)  { if (onError)   onError(msg) }
        )
    }
}
