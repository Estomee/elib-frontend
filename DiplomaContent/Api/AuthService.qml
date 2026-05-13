// Singleton service providing GraphQL mutations for authentication: login, register, token refresh, logout, and password reset.
pragma Singleton
import QtQuick
import DiplomaContent.Network

QtObject {
    id: root

    function login(email, password, remember, onSuccess, onError) {
        const q = `
            mutation Login($input: LoginInput!) {
                login(input: $input) {
                    access_token
                    refresh_token
                    user {
                        user_id
                        employee
                        first_name
                        last_name
                        email
                    }
                }
            }
        `
        GraphQLClient.execute(q, { input: { email: email, password: password, device_info: AppSettings.deviceInfo } },
            function(data) {
                const r = data.login
                TokenManager.saveTokens(
                    r.access_token,
                    r.refresh_token,
                    parseInt(r.user.user_id),
                    r.user.employee,
                    r.user.first_name,
                    r.user.last_name,
                    r.user.email
                )
                if (remember) {
                    TokenManager.setRememberMe(true)
                    TokenManager.setSavedEmail(email)
                } else {
                    TokenManager.setRememberMe(false)
                }
                if (onSuccess) onSuccess(r)
            },
            function(msg) { if (onError) onError(msg) }
        )
    }

    function register(input, onSuccess, onError) {
        const q = `
            mutation Register($input: RegisterInput!) {
                register(input: $input) {
                    access_token
                }
            }
        `
        const fullInput = Object.assign({}, input, { device_info: AppSettings.deviceInfo })
        GraphQLClient.execute(q, { input: fullInput },
            function(data) { if (onSuccess) onSuccess(data.register) },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function refreshToken(onSuccess, onError) {
        const q = `
            mutation RefreshToken($input: RefreshTokenInput!) {
                refresh_token(input: $input) {
                    access_token
                    refresh_token
                }
            }
        `
        GraphQLClient.execute(q, { input: { refresh_token: TokenManager.refreshToken } },
            function(data) {
                const r = data.refresh_token
                TokenManager.saveTokens(
                    r.access_token,
                    r.refresh_token,
                    TokenManager.userId,
                    TokenManager.isEmployee,
                    TokenManager.firstName,
                    TokenManager.lastName,
                    TokenManager.email
                )
                if (onSuccess) onSuccess(r)
            },
            function(msg) { if (onError) onError(msg) }
        )
    }

    function logout(onSuccess, onError) {
        const q = `
            mutation Logout($input: RefreshTokenInput!) {
                logout(input: $input)
            }
        `
        GraphQLClient.execute(q, { input: { refresh_token: TokenManager.refreshToken } },
            function(data) {
                TokenManager.clearTokens()
                if (onSuccess) onSuccess()
            },
            function(msg) {
                TokenManager.clearTokens()
                if (onError) onError(msg)
            }
        )
    }

    function requestPasswordReset(email, onSuccess, onError) {
        const q = `
            mutation RequestPasswordReset($input: RequestPasswordResetInput!) {
                request_password_reset(input: $input)
            }
        `
        GraphQLClient.execute(q, { input: { email: email } },
            function(data) { if (onSuccess) onSuccess() },
            function(msg)  { if (onError)   onError(msg) }
        )
    }

    function resetPassword(email, code, newPassword, onSuccess, onError) {
        const q = `
            mutation ResetPassword($input: ResetPasswordInput!) {
                reset_password(input: $input)
            }
        `
        GraphQLClient.execute(q, { input: { email: email, code: code, new_password: newPassword } },
            function(data) { if (onSuccess) onSuccess() },
            function(msg)  { if (onError)   onError(msg) }
        )
    }
}
