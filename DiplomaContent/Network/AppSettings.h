// QML singleton that exposes server URL, storage URL, health endpoint, and device info to the app.
#pragma once
#include <QObject>
#include <QString>
#include <QtQml/qqml.h>

class QQmlEngine;
class QJSEngine;

class AppSettings : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT

    Q_PROPERTY(QString serverUrl      READ serverUrl      CONSTANT)
    Q_PROPERTY(QString healthUrl      READ healthUrl      CONSTANT)
    Q_PROPERTY(QString deviceInfo     READ deviceInfo     CONSTANT)
    Q_PROPERTY(QString storageBaseUrl READ storageBaseUrl CONSTANT)

public:
    explicit AppSettings(QObject *parent = nullptr);

    static AppSettings *create(QQmlEngine *engine, QJSEngine *scriptEngine);
    static AppSettings *instance();

    QString serverUrl()      const;
    QString healthUrl()      const;
    QString deviceInfo()     const;
    QString storageBaseUrl() const;

private:
    static AppSettings *s_instance;
    QString m_serverUrl;
    QString m_storageBaseUrl;
};
