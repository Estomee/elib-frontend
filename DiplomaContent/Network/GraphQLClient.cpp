// Implements GraphQLClient: posts GraphQL queries with auth headers and handles error classification.
#include "GraphQLClient.h"
#include "TokenManager.h"
#include "AppSettings.h"

#include <QNetworkRequest>
#include <QNetworkReply>
#include <QSslError>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QQmlEngine>
#include <QJSEngine>

GraphQLClient *GraphQLClient::s_instance = nullptr;

GraphQLClient::GraphQLClient(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_jsEngine(qobject_cast<QJSEngine*>(parent))
{
    if (!m_jsEngine && s_instance && s_instance->m_jsEngine)
        m_jsEngine = s_instance->m_jsEngine;

    s_instance = this;

#ifdef QT_DEBUG
    connect(m_nam, &QNetworkAccessManager::sslErrors,
            this, [](QNetworkReply *reply, const QList<QSslError> &) {
        reply->ignoreSslErrors();
    });
#endif
}

GraphQLClient *GraphQLClient::create(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    if (!s_instance)
        s_instance = new GraphQLClient(engine ? engine : scriptEngine);
    if (engine && !s_instance->m_jsEngine)
        s_instance->m_jsEngine = engine;
    if (engine)
        engine->setObjectOwnership(s_instance, QQmlEngine::CppOwnership);
    return s_instance;
}

GraphQLClient *GraphQLClient::instance()
{
    return s_instance;
}

bool GraphQLClient::isAuthNotAuthorized(const QJsonArray &errors)
{
    for (const QJsonValue &e : errors) {
        const QJsonObject ext = e.toObject()[QStringLiteral("extensions")].toObject();
        if (ext[QStringLiteral("code")].toString() == QStringLiteral("AUTH_NOT_AUTHORIZED"))
            return true;
    }
    return false;
}

bool GraphQLClient::isConnectionError(QNetworkReply::NetworkError err)
{
    return err == QNetworkReply::ConnectionRefusedError
        || err == QNetworkReply::HostNotFoundError
        || err == QNetworkReply::TimeoutError
        || err == QNetworkReply::OperationCanceledError
        || err == QNetworkReply::RemoteHostClosedError
        || err == QNetworkReply::NetworkSessionFailedError;
}

void GraphQLClient::recordSuccess()
{
    m_consecutiveConnErrors = 0;
    if (m_serverUnavailableEmitted) {
        m_serverUnavailableEmitted = false;
        emit serverRestored();
    }
}

void GraphQLClient::recordConnectionError()
{
    ++m_consecutiveConnErrors;
    if (m_consecutiveConnErrors >= 3 && !m_serverUnavailableEmitted) {
        m_serverUnavailableEmitted = true;
        emit serverUnavailable();
    }
}

static QString networkErrorToRussian(QNetworkReply::NetworkError err, const QString &)
{
    switch (err) {
    case QNetworkReply::ConnectionRefusedError:
        return QStringLiteral("Сервер недоступен. Проверьте подключение к интернету.");
    case QNetworkReply::RemoteHostClosedError:
        return QStringLiteral("Соединение с сервером прервано. Попробуйте позже.");
    case QNetworkReply::HostNotFoundError:
        return QStringLiteral("Сервер не найден. Проверьте адрес сервера и подключение к интернету.");
    case QNetworkReply::TimeoutError:
        return QStringLiteral("Сервер не отвечает. Попробуйте позже.");
    case QNetworkReply::SslHandshakeFailedError:
        return QStringLiteral("Ошибка защищённого соединения (SSL). Обратитесь в поддержку.");
    case QNetworkReply::AuthenticationRequiredError:
        return QStringLiteral("Требуется авторизация. Войдите в систему повторно.");
    case QNetworkReply::ContentAccessDenied:
        return QStringLiteral("Доступ запрещён. Недостаточно прав.");
    case QNetworkReply::ContentNotFoundError:
        return QStringLiteral("Запрошенный ресурс не найден на сервере.");
    case QNetworkReply::InternalServerError:
        return QStringLiteral("Внутренняя ошибка сервера. Попробуйте позже.");
    case QNetworkReply::ServiceUnavailableError:
        return QStringLiteral("Сервис временно недоступен. Попробуйте позже.");
    default:
        return QStringLiteral("Ошибка подключения к серверу. Попробуйте позже.");
    }
}

void GraphQLClient::execute(const QString &query,
                             const QVariantMap &variables,
                             const QJSValue &onSuccess,
                             const QJSValue &onError)
{
    auto *settings = AppSettings::instance();
    auto *tokens   = TokenManager::instance();

    const QString url = settings ? settings->serverUrl()
                                 : QStringLiteral("http://localhost:7054/graphql");

    QNetworkRequest request{QUrl(url)};
    request.setHeader(QNetworkRequest::ContentTypeHeader, QByteArrayLiteral("application/json"));
    request.setTransferTimeout(15000);

    const QString token = tokens ? tokens->accessToken() : QString{};
    if (!token.isEmpty())
        request.setRawHeader(QByteArrayLiteral("Authorization"),
                             QByteArrayLiteral("Bearer ") + token.toUtf8());

    QJsonObject body;
    body[QStringLiteral("query")] = query;
    if (!variables.isEmpty())
        body[QStringLiteral("variables")] = QJsonObject::fromVariantMap(variables);

    const QByteArray bodyBytes = QJsonDocument(body).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = m_nam->post(request, bodyBytes);

    QJSValue successCb = onSuccess;
    QJSValue errorCb   = onError;

    connect(reply, &QNetworkReply::finished, this, [this, reply, successCb, errorCb]() mutable {
        reply->deleteLater();
        QJSEngine *jsEng = m_jsEngine;

        if (reply->error() != QNetworkReply::NoError) {
            const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            const QByteArray errorBody = reply->readAll();

            if (isConnectionError(reply->error()))
                recordConnectionError();

            if (statusCode == 401) {
                recordSuccess();
                emit unauthorizedError();
                if (errorCb.isCallable())
                    errorCb.call({QStringLiteral("Сессия истекла. Войдите снова.")});
                return;
            }

            if (!errorBody.isEmpty()) {
                QJsonParseError pe;
                const QJsonDocument errDoc = QJsonDocument::fromJson(errorBody, &pe);
                if (pe.error == QJsonParseError::NoError && errDoc.object().contains(QStringLiteral("errors"))) {
                    const QJsonArray errors = errDoc.object()[QStringLiteral("errors")].toArray();

                    if (isAuthNotAuthorized(errors)) {
                        recordSuccess();
                        emit unauthorizedError();
                        if (errorCb.isCallable())
                            errorCb.call({QStringLiteral("Сессия истекла. Войдите снова.")});
                        return;
                    }

                    QString msg;
                    for (const QJsonValue &e : errors) {
                        const QString serverMsg = e.toObject()[QStringLiteral("message")].toString();
                        if (!msg.isEmpty()) msg += QStringLiteral("; ");
                        msg += serverMsg;
                    }
                    if (!msg.isEmpty()) {
                        recordSuccess();
                        if (errorCb.isCallable())
                            errorCb.call({msg});
                        return;
                    }
                }
            }

            const QString msg = networkErrorToRussian(reply->error(), reply->errorString());
            if (!m_serverUnavailableEmitted)
                emit networkError(msg);
            if (errorCb.isCallable())
                errorCb.call({msg});
            return;
        }

        const QByteArray raw = reply->readAll();
        QJsonParseError parseErr;
        const QJsonDocument doc = QJsonDocument::fromJson(raw, &parseErr);

        if (parseErr.error != QJsonParseError::NoError) {
            const QString msg = QStringLiteral("Получен некорректный ответ от сервера.");
            if (errorCb.isCallable())
                errorCb.call({msg});
            return;
        }

        const QJsonObject root = doc.object();

        if (root.contains(QStringLiteral("errors"))) {
            const QJsonArray errors = root[QStringLiteral("errors")].toArray();

            if (isAuthNotAuthorized(errors)) {
                recordSuccess();
                emit unauthorizedError();
                if (errorCb.isCallable())
                    errorCb.call({QStringLiteral("Сессия истекла. Войдите снова.")});
                return;
            }

            QString msg;
            for (const QJsonValue &e : errors) {
                const QString serverMsg = e.toObject()[QStringLiteral("message")].toString();
                if (!msg.isEmpty()) msg += QStringLiteral("; ");
                msg += serverMsg;
            }
            if (msg.isEmpty())
                msg = QStringLiteral("Произошла ошибка при выполнении операции.");
            recordSuccess();
            if (errorCb.isCallable())
                errorCb.call({msg});
            return;
        }

        recordSuccess();

        if (jsEng && successCb.isCallable()) {
            const QJsonObject data = root[QStringLiteral("data")].toObject();
            QJSValue jsData = jsEng->toScriptValue(data.toVariantMap());
            QJSValue result = successCb.call({jsData});
        }
    });
}
