// Implements FileUploader: uploads files via HTTP PUT to S3 and downloads remote files to disk.
#include "FileUploader.h"

#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QImageReader>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QSslError>
#include <QStandardPaths>
#include <QQmlEngine>
#include <QJSEngine>

FileUploader *FileUploader::s_instance = nullptr;

FileUploader::FileUploader(QObject *parent)
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

FileUploader *FileUploader::create(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    if (!s_instance)
        s_instance = new FileUploader(engine ? engine : scriptEngine);
    if (engine && !s_instance->m_jsEngine)
        s_instance->m_jsEngine = engine;
    if (engine)
        engine->setObjectOwnership(s_instance, QQmlEngine::CppOwnership);
    return s_instance;
}

FileUploader *FileUploader::instance()
{
    return s_instance;
}

qint64 FileUploader::fileSize(const QString &path)
{
    QFileInfo info(path);
    return info.exists() ? info.size() : -1;
}

QVariantMap FileUploader::imageSize(const QString &path)
{
    QVariantMap result;
    result["width"]  = 0;
    result["height"] = 0;

    QImageReader reader(path);
    const QSize sz = reader.size();
    if (sz.isValid()) {
        result["width"]  = sz.width();
        result["height"] = sz.height();
    }
    return result;
}

QString FileUploader::appCacheDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
}

void FileUploader::downloadFile(const QString &url, const QString &localPath,
                                 const QJSValue &onSuccess, const QJSValue &onError)
{
    _downloadImpl(url, localPath, QString{}, onSuccess, onError);
}

void FileUploader::downloadFileAuth(const QString &url, const QString &localPath,
                                     const QString &token,
                                     const QJSValue &onSuccess, const QJSValue &onError)
{
    _downloadImpl(url, localPath, token, onSuccess, onError);
}

void FileUploader::_downloadImpl(const QString &url, const QString &localPath,
                                  const QString &token,
                                  const QJSValue &onSuccess, const QJSValue &onError)
{
    QNetworkRequest request{QUrl(url)};
    request.setTransferTimeout(120000);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);

    if (!token.isEmpty())
        request.setRawHeader(QByteArrayLiteral("Authorization"),
                             QByteArrayLiteral("Bearer ") + token.toUtf8());

    QNetworkReply *reply = m_nam->get(request);
    QJSValue successCb = onSuccess;
    QJSValue errorCb   = onError;

    connect(reply, &QNetworkReply::finished, this, [=]() mutable {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            if (errorCb.isCallable())
                errorCb.call({reply->errorString()});
            return;
        }
        QFileInfo fi(localPath);
        QDir().mkpath(fi.absolutePath());
        QFile file(localPath);
        if (!file.open(QIODevice::WriteOnly)) {
            const QString msg = QStringLiteral("Не удалось записать: ") + localPath;
            if (errorCb.isCallable())
                errorCb.call({msg});
            return;
        }
        file.write(reply->readAll());
        file.close();
        if (successCb.isCallable())
            successCb.call({});
    });
}

void FileUploader::uploadFile(const QString &url,
                               const QString &localPath,
                               const QString &contentType,
                               const QJSValue &onProgress,
                               const QJSValue &onSuccess,
                               const QJSValue &onError)
{
    auto *file = new QFile(localPath, this);
    if (!file->open(QIODevice::ReadOnly)) {
        file->deleteLater();
        if (onError.isCallable()) {
            QJSValue cb = onError;
            cb.call({QStringLiteral("Не удалось открыть файл: ") + localPath});
        }
        return;
    }

    QNetworkRequest request{QUrl(url)};
    request.setHeader(QNetworkRequest::ContentTypeHeader, contentType.toUtf8());
    request.setHeader(QNetworkRequest::ContentLengthHeader, file->size());
    request.setTransferTimeout(300000);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply *reply = m_nam->put(request, file);
    file->setParent(reply);

    QJSValue progressCb = onProgress;
    QJSValue successCb  = onSuccess;
    QJSValue errorCb    = onError;
    QJSEngine *jsEng    = m_jsEngine;

    connect(reply, &QNetworkReply::uploadProgress,
            this, [progressCb, jsEng](qint64 sent, qint64 total) mutable {
        if (total > 0 && progressCb.isCallable())
            progressCb.call({static_cast<double>(sent) / static_cast<double>(total)});
    });

    connect(reply, &QNetworkReply::finished,
            this, [reply, successCb, errorCb]() mutable {
        reply->deleteLater();
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QByteArray body = reply->readAll();

        if (reply->error() != QNetworkReply::NoError) {
            const QString msg = QStringLiteral("Ошибка загрузки (HTTP %1): %2")
                                    .arg(status).arg(reply->errorString());
            if (errorCb.isCallable())
                errorCb.call({msg});
            return;
        }

        if (status < 200 || status >= 300) {
            if (errorCb.isCallable())
                errorCb.call({QStringLiteral("Неожиданный статус S3: HTTP %1").arg(status)});
            return;
        }

        if (successCb.isCallable())
            successCb.call({});
    });
}
