// Implements TokenManager: persists and retrieves auth tokens and user preferences using QSettings.
#include "TokenManager.h"
#include <QQmlEngine>

TokenManager *TokenManager::s_instance = nullptr;

TokenManager::TokenManager(QObject *parent)
    : QObject(parent)
    , m_settings(QStringLiteral("ELib"), QStringLiteral("Diploma"))
{
    s_instance = this;

    // On fresh install the MSI writes a unique ProductCode to HKLM\Software\ELib\InstallId.
    // Compare it against the last seen value in HKCU to detect a new installation and clear
    // stale auth tokens so the user is not greeted with a spurious "session expired" error.
    QSettings hklm(QStringLiteral("HKEY_LOCAL_MACHINE\\Software\\ELib"),
                   QSettings::NativeFormat);
    const QString installId = hklm.value(QStringLiteral("InstallId")).toString();
    const QString seenId    = m_settings.value(QStringLiteral("meta/install_id")).toString();

    if (!installId.isEmpty() && installId != seenId) {
        m_settings.remove(QStringLiteral("auth/access_token"));
        m_settings.remove(QStringLiteral("auth/refresh_token"));
        m_settings.remove(QStringLiteral("auth/user_id"));
        m_settings.remove(QStringLiteral("auth/is_employee"));
        m_settings.remove(QStringLiteral("auth/first_name"));
        m_settings.remove(QStringLiteral("auth/last_name"));
        m_settings.remove(QStringLiteral("auth/email"));
        m_settings.setValue(QStringLiteral("meta/install_id"), installId);
    }
}

TokenManager *TokenManager::create(QQmlEngine *engine, QJSEngine *)
{
    if (!s_instance)
        s_instance = new TokenManager(engine);
    engine->setObjectOwnership(s_instance, QQmlEngine::CppOwnership);
    return s_instance;
}

TokenManager *TokenManager::instance()
{
    return s_instance;
}

QString TokenManager::accessToken() const
{
    return m_settings.value(QStringLiteral("auth/access_token")).toString();
}

QString TokenManager::refreshToken() const
{
    return m_settings.value(QStringLiteral("auth/refresh_token")).toString();
}

int TokenManager::userId() const
{
    return m_settings.value(QStringLiteral("auth/user_id"), 0).toInt();
}

bool TokenManager::isEmployee() const
{
    return m_settings.value(QStringLiteral("auth/is_employee"), false).toBool();
}

QString TokenManager::firstName() const
{
    return m_settings.value(QStringLiteral("auth/first_name")).toString();
}

QString TokenManager::lastName() const
{
    return m_settings.value(QStringLiteral("auth/last_name")).toString();
}

QString TokenManager::email() const
{
    return m_settings.value(QStringLiteral("auth/email")).toString();
}

bool TokenManager::rememberMe() const
{
    return m_settings.value(QStringLiteral("prefs/remember_me"), false).toBool();
}

QString TokenManager::savedEmail() const
{
    return m_settings.value(QStringLiteral("prefs/saved_email")).toString();
}

bool TokenManager::hasValidToken() const
{
    return !accessToken().isEmpty();
}

void TokenManager::saveTokens(const QString &access,
                               const QString &refresh,
                               int uid,
                               bool employee,
                               const QString &fname,
                               const QString &lname,
                               const QString &mail)
{
    m_settings.setValue(QStringLiteral("auth/access_token"),  access);
    m_settings.setValue(QStringLiteral("auth/refresh_token"), refresh);
    m_settings.setValue(QStringLiteral("auth/user_id"),       uid);
    m_settings.setValue(QStringLiteral("auth/is_employee"),   employee);
    m_settings.setValue(QStringLiteral("auth/first_name"),    fname);
    m_settings.setValue(QStringLiteral("auth/last_name"),     lname);
    m_settings.setValue(QStringLiteral("auth/email"),         mail);
    emit tokensChanged();
}

void TokenManager::updateLocalUserInfo(const QString &fname,
                                        const QString &lname,
                                        const QString &mail)
{
    m_settings.setValue(QStringLiteral("auth/first_name"), fname);
    m_settings.setValue(QStringLiteral("auth/last_name"),  lname);
    if (!mail.isEmpty())
        m_settings.setValue(QStringLiteral("auth/email"), mail);
    emit tokensChanged();
}

void TokenManager::clearTokens()
{
    m_settings.remove(QStringLiteral("auth/access_token"));
    m_settings.remove(QStringLiteral("auth/refresh_token"));
    m_settings.remove(QStringLiteral("auth/user_id"));
    m_settings.remove(QStringLiteral("auth/is_employee"));
    m_settings.remove(QStringLiteral("auth/first_name"));
    m_settings.remove(QStringLiteral("auth/last_name"));
    m_settings.remove(QStringLiteral("auth/email"));
    emit tokensChanged();
}

void TokenManager::setRememberMe(bool value)
{
    m_settings.setValue(QStringLiteral("prefs/remember_me"), value);
    emit prefsChanged();
}

void TokenManager::setSavedEmail(const QString &mail)
{
    m_settings.setValue(QStringLiteral("prefs/saved_email"), mail);
    emit prefsChanged();
}
