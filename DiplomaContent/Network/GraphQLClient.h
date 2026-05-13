// QML singleton that sends GraphQL requests over HTTP and emits signals for auth and network errors.
#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJSValue>
#include <QJsonArray>
#include <QtQml/qqml.h>

class QQmlEngine;
class QJSEngine;

class GraphQLClient : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT

public:
    explicit GraphQLClient(QObject *parent = nullptr);

    static GraphQLClient *create(QQmlEngine *engine, QJSEngine *scriptEngine);
    static GraphQLClient *instance();

    Q_INVOKABLE void execute(const QString &query,
                             const QVariantMap &variables,
                             const QJSValue &onSuccess,
                             const QJSValue &onError = QJSValue());

signals:
    void unauthorizedError();
    void networkError(const QString &message);
    void serverUnavailable();
    void serverRestored();

private:
    static bool isAuthNotAuthorized(const QJsonArray &errors);
    static bool isConnectionError(QNetworkReply::NetworkError err);

    void recordSuccess();
    void recordConnectionError();

    static GraphQLClient *s_instance;
    QNetworkAccessManager *m_nam;
    QJSEngine             *m_jsEngine;
    int                    m_consecutiveConnErrors    = 0;
    bool                   m_serverUnavailableEmitted = false;
};
