// Implements AppSettings: resolves server and storage URLs from environment variables or QSettings.
#include "AppSettings.h"
#include <QQmlEngine>
#include <QSettings>
#include <QProcessEnvironment>
#include <QSysInfo>
#include <QJsonObject>
#include <QJsonDocument>

AppSettings *AppSettings::s_instance = nullptr;

AppSettings::AppSettings(QObject *parent)
    : QObject(parent)
{
    s_instance = this;

    const QString envUrl = QProcessEnvironment::systemEnvironment()
                               .value(QStringLiteral("ELIB_SERVER_URL"));
    if (!envUrl.isEmpty()) {
        m_serverUrl = envUrl;
    } else {
        QSettings settings(QStringLiteral("ELib"), QStringLiteral("Diploma"));
        const QString saved = settings.value(QStringLiteral("settings/server_url")).toString();
        if (!saved.isEmpty()) {
            m_serverUrl = saved;
        } else {
#ifdef QT_DEBUG
            m_serverUrl = QStringLiteral("http://localhost:5099/graphql");
#else
            m_serverUrl = QStringLiteral("https://elib-server.onrender.com/graphql");
#endif
        }
    }

    const QString envStorage = QProcessEnvironment::systemEnvironment()
                                   .value(QStringLiteral("ELIB_STORAGE_URL"));
    if (!envStorage.isEmpty()) {
        m_storageBaseUrl = envStorage;
    } else {
        QSettings settings(QStringLiteral("ELib"), QStringLiteral("Diploma"));
        m_storageBaseUrl = settings.value(QStringLiteral("settings/storage_url")).toString();
    }
}

AppSettings *AppSettings::create(QQmlEngine *engine, QJSEngine *)
{
    if (!s_instance)
        s_instance = new AppSettings(engine);
    engine->setObjectOwnership(s_instance, QQmlEngine::CppOwnership);
    return s_instance;
}

AppSettings *AppSettings::instance()
{
    return s_instance;
}

QString AppSettings::serverUrl() const
{
    return m_serverUrl;
}

QString AppSettings::deviceInfo() const
{
    QJsonObject obj;
    obj[QStringLiteral("device_id")]   = QString::fromLatin1(QSysInfo::machineUniqueId().toHex());
    obj[QStringLiteral("device_type")] = QStringLiteral("desktop");
    obj[QStringLiteral("os")]          = QSysInfo::prettyProductName();
    obj[QStringLiteral("arch")]        = QSysInfo::currentCpuArchitecture();
    obj[QStringLiteral("hostname")]    = QSysInfo::machineHostName();
    return QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact));
}

QString AppSettings::storageBaseUrl() const
{
    return m_storageBaseUrl;
}

QString AppSettings::healthUrl() const
{
    QString base = m_serverUrl;
    if (base.endsWith(QStringLiteral("/graphql")))
        base.chop(8);
    return base + QStringLiteral("/health");
}
