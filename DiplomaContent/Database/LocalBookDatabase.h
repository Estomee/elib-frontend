// QML singleton providing a SQLite-backed store for locally downloaded books and reading progress.
#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QSqlDatabase>
#include <QtQml/qqml.h>

class LocalBookDatabase : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit LocalBookDatabase(QObject *parent = nullptr);
    ~LocalBookDatabase() override;

    Q_INVOKABLE bool addOrUpdateBook(const QString &bookId,
                                     const QString &title,
                                     const QString &author,
                                     const QString &genre,
                                     int year,
                                     const QString &localPath);

    Q_INVOKABLE QVariantList getAllBooks() const;

    Q_INVOKABLE bool updateProgress(const QString &localPath, int page, int total);

    Q_INVOKABLE QVariantMap getProgress(const QString &localPath) const;

    Q_INVOKABLE bool removeBook(const QString &bookId);

    Q_INVOKABLE bool isReady() const { return m_ready; }

private:
    bool initDb(const QString &dirPath);
    bool createTable();

    QSqlDatabase m_db;
    QString      m_connectionName;
    bool         m_ready = false;
};
