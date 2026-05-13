// Singleton service for user account operations: profile queries, user updates, password changes, and admin user listing.
pragma Singleton
import QtQuick
import DiplomaContent.Network

QtObject {
    id: root

    function getMe(onSuccess, onError) {
        const q = `
            query Me {
                me {
                    user_id
                    username
                    email
                    first_name
                    last_name
                    middle_name
                    phone
                    year_of_birth
                    employee
                    registration_date
                    last_login
                }
            }
        `
        GraphQLClient.execute(q, {},
            function(data) { if (onSuccess) onSuccess(data.me) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function updateUser(userId, input, onSuccess, onError) {
        const q = `
            mutation UpdateUser($input: UpdateUserInput!) {
                update_user(input: $input) {
                    user_id
                    first_name
                    last_name
                    middle_name
                    phone
                }
            }
        `
        GraphQLClient.execute(q, { input: input },
            function(data) { if (onSuccess) onSuccess(data.update_user) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function changePasswordByEmailCode(code, newPassword, onSuccess, onError) {
        const q = `
            mutation ChangePasswordByEmailCode($input: ChangePasswordByEmailCodeInput!) {
                change_password_by_email_code(input: $input)
            }
        `
        GraphQLClient.execute(q, { input: { code: code, new_password: newPassword } },
            function(data) { if (onSuccess) onSuccess() },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function loadUsers(pagination, search, onSuccess, onError) {
        const q = `
            query Users($pagination: PaginationInput!, $filter: UserFilter) {
                users(pagination: $pagination, filter: $filter) {
                    nodes {
                        user_id
                        username
                        email
                        first_name
                        last_name
                        phone
                        employee
                        registration_date
                        last_login
                    }
                    total_count
                    page_info { has_next_page end_cursor }
                }
            }
        `
        const filter = search ? { search: search } : null
        GraphQLClient.execute(q, { pagination: pagination, filter: filter },
            function(data) { if (onSuccess) onSuccess(data.users) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function resetUserPassword(userId, newPassword, onSuccess, onError) {
        const q = `
            mutation ResetUserPassword($input: AdminResetPasswordInput!) {
                reset_user_password(input: $input)
            }
        `
        GraphQLClient.execute(q, { input: { user_id: userId, new_password: newPassword } },
            function(data) { if (onSuccess) onSuccess() },
            function(msg)  { if (onError)   onError(msg) }
        )
    }
}
