// QML singleton that stores and exposes JWT tokens and user identity via QSettings.
#pragma once
#include <QObject>
#include <QSettings>
#include <QtQml/qqml.h>

class QQmlEngine;
class QJSEngine;

class TokenManager : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT

    Q_PROPERTY(QString accessToken  READ accessToken  NOTIFY tokensChanged)
    Q_PROPERTY(QString refreshToken READ refreshToken NOTIFY tokensChanged)
    Q_PROPERTY(int     userId       READ userId       NOTIFY tokensChanged)
    Q_PROPERTY(bool    isEmployee   READ isEmployee   NOTIFY tokensChanged)
    Q_PROPERTY(QString firstName    READ firstName    NOTIFY tokensChanged)
    Q_PROPERTY(QString lastName     READ lastName     NOTIFY tokensChanged)
    Q_PROPERTY(QString email        READ email        NOTIFY tokensChanged)
    Q_PROPERTY(bool    rememberMe   READ rememberMe   NOTIFY prefsChanged)
    Q_PROPERTY(QString savedEmail   READ savedEmail   NOTIFY prefsChanged)

public:
    explicit TokenManager(QObject *parent = nullptr);

    static TokenManager *create(QQmlEngine *engine, QJSEngine *scriptEngine);
    static TokenManager *instance();

    QString accessToken()  const;
    QString refreshToken() const;
    int     userId()       const;
    bool    isEmployee()   const;
    QString firstName()    const;
    QString lastName()     const;
    QString email()        const;
    bool    rememberMe()   const;
    QString savedEmail()   const;

    Q_INVOKABLE bool    hasValidToken() const;
    Q_INVOKABLE void    saveTokens(const QString &access,
                                   const QString &refresh,
                                   int userId,
                                   bool isEmployee,
                                   const QString &firstName,
                                   const QString &lastName,
                                   const QString &email);
    Q_INVOKABLE void    updateLocalUserInfo(const QString &firstName,
                                            const QString &lastName,
                                            const QString &email);
    Q_INVOKABLE void    clearTokens();
    Q_INVOKABLE void    setRememberMe(bool value);
    Q_INVOKABLE void    setSavedEmail(const QString &email);

signals:
    void tokensChanged();
    void prefsChanged();

private:
    static TokenManager *s_instance;
    QSettings m_settings;
};
