// QML singleton for uploading files to S3 presigned URLs and downloading remote files to disk.
#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QJSValue>
#include <QVariantMap>
#include <QtQml/qqml.h>

class QQmlEngine;
class QJSEngine;

class FileUploader : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT

public:
    explicit FileUploader(QObject *parent = nullptr);

    static FileUploader *create(QQmlEngine *engine, QJSEngine *scriptEngine);
    static FileUploader *instance();

    Q_INVOKABLE void uploadFile(const QString &url,
                                const QString &localPath,
                                const QString &contentType,
                                const QJSValue &onProgress,
                                const QJSValue &onSuccess,
                                const QJSValue &onError);

    Q_INVOKABLE qint64 fileSize(const QString &path);

    Q_INVOKABLE QVariantMap imageSize(const QString &path);

    Q_INVOKABLE void downloadFile(const QString &url,
                                  const QString &localPath,
                                  const QJSValue &onSuccess,
                                  const QJSValue &onError);

    Q_INVOKABLE QString appCacheDir();

private:
    static FileUploader *s_instance;
    QNetworkAccessManager *m_nam;
    QJSEngine             *m_jsEngine;
};
