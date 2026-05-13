// Implements LocalBookDatabase: manages an SQLite database for local book metadata and read progress.
#include "LocalBookDatabase.h"
#include <QCoreApplication>
#include <QDir>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDateTime>
#include <QUuid>
#include <cmath>

LocalBookDatabase::LocalBookDatabase(QObject *parent)
    : QObject(parent)
    , m_connectionName(QStringLiteral("elib_") +
                       QUuid::createUuid().toString(QUuid::WithoutBraces))
{
    const QString dir = QCoreApplication::applicationDirPath()
                        + QStringLiteral("/local");
    m_ready = initDb(dir);
    if (!m_ready)
        qWarning() << "LocalBookDatabase: не удалось инициализировать БД по пути" << dir;
}

LocalBookDatabase::~LocalBookDatabase()
{
    if (m_db.isOpen())
        m_db.close();
    QSqlDatabase::removeDatabase(m_connectionName);
}

bool LocalBookDatabase::initDb(const QString &dirPath)
{
    QDir dir;
    if (!dir.exists(dirPath) && !dir.mkpath(dirPath)) {
        qWarning() << "LocalBookDatabase: не удалось создать директорию" << dirPath;
        return false;
    }

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
    m_db.setDatabaseName(dirPath + QStringLiteral("/elib.db"));

    if (!m_db.open()) {
        qWarning() << "LocalBookDatabase: не удалось открыть БД:"
                   << m_db.lastError().text();
        return false;
    }

    return createTable();
}

bool LocalBookDatabase::createTable()
{
    QSqlQuery q(m_db);
    bool ok = q.exec(
        "CREATE TABLE IF NOT EXISTS local_books ("
        "bookId TEXT PRIMARY KEY, "
        "title TEXT, author TEXT, genre TEXT, year INTEGER, "
        "localPath TEXT UNIQUE, "
        "page INTEGER DEFAULT 1, total INTEGER DEFAULT 0)"
    );
    if (!ok)
        qWarning() << "LocalBookDatabase: ошибка создания таблицы:" << q.lastError().text();
    return ok;
}

bool LocalBookDatabase::addOrUpdateBook(const QString &bookId,
                                        const QString &title,
                                        const QString &author,
                                        const QString &genre,
                                        int year,
                                        const QString &localPath)
{
    if (!m_ready) return false;

    QSqlQuery chk(m_db);
    chk.prepare(QStringLiteral("SELECT bookId FROM local_books WHERE localPath = ?"));
    chk.addBindValue(localPath);
    if (!chk.exec()) return false;

    if (chk.next()) {
        QSqlQuery uq(m_db);
        uq.prepare(QStringLiteral(
            "UPDATE local_books SET title=?, author=?, genre=?, year=? WHERE localPath=?"));
        uq.addBindValue(title);
        uq.addBindValue(author);
        uq.addBindValue(genre);
        uq.addBindValue(year);
        uq.addBindValue(localPath);
        return uq.exec();
    } else {
        QSqlQuery iq(m_db);
        iq.prepare(QStringLiteral(
            "INSERT INTO local_books (bookId, title, author, genre, year, localPath)"
            " VALUES (?,?,?,?,?,?)"));
        iq.addBindValue(bookId);
        iq.addBindValue(title);
        iq.addBindValue(author);
        iq.addBindValue(genre);
        iq.addBindValue(year);
        iq.addBindValue(localPath);
        return iq.exec();
    }
}

QVariantList LocalBookDatabase::getAllBooks() const
{
    QVariantList result;
    if (!m_ready) return result;

    QSqlQuery q(m_db);
    if (!q.exec(QStringLiteral(
            "SELECT bookId, title, author, genre, year, localPath, page, total"
            " FROM local_books ORDER BY rowid DESC")))
        return result;

    while (q.next()) {
        const int page  = q.value(QStringLiteral("page")).toInt();
        const int total = q.value(QStringLiteral("total")).toInt();
        const int prog  = (total > 0)
                          ? static_cast<int>(std::round(page * 100.0 / total))
                          : 0;

        QVariantMap book;
        book[QStringLiteral("bookId")]       = q.value(QStringLiteral("bookId"));
        book[QStringLiteral("title")]        = q.value(QStringLiteral("title"));
        book[QStringLiteral("author")]       = q.value(QStringLiteral("author"));
        book[QStringLiteral("genre")]        = q.value(QStringLiteral("genre"));
        book[QStringLiteral("year")]         = q.value(QStringLiteral("year"));
        book[QStringLiteral("localPath")]    = q.value(QStringLiteral("localPath"));
        book[QStringLiteral("lastPage")]     = page;
        book[QStringLiteral("totalPages")]   = total;
        book[QStringLiteral("readProgress")] = prog;
        book[QStringLiteral("isLocal")]      = true;
        result.append(book);
    }
    return result;
}

bool LocalBookDatabase::updateProgress(const QString &localPath, int page, int total)
{
    if (!m_ready) return false;

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "UPDATE local_books SET page=?, total=? WHERE localPath=?"));
    q.addBindValue(page);
    q.addBindValue(total);
    q.addBindValue(localPath);
    if (!q.exec()) return false;

    if (q.numRowsAffected() == 0) {
        QSqlQuery iq(m_db);
        iq.prepare(QStringLiteral(
            "INSERT INTO local_books (bookId, localPath, page, total) VALUES (?,?,?,?)"));
        iq.addBindValue(QStringLiteral("reader_") +
                        QString::number(QDateTime::currentMSecsSinceEpoch()));
        iq.addBindValue(localPath);
        iq.addBindValue(page);
        iq.addBindValue(total);
        return iq.exec();
    }
    return true;
}

QVariantMap LocalBookDatabase::getProgress(const QString &localPath) const
{
    QVariantMap result;
    result[QStringLiteral("page")]  = 1;
    result[QStringLiteral("total")] = 0;

    if (!m_ready) return result;

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "SELECT page, total FROM local_books WHERE localPath = ?"));
    q.addBindValue(localPath);

    if (q.exec() && q.next()) {
        const int p = q.value(QStringLiteral("page")).toInt();
        result[QStringLiteral("page")]  = (p > 0) ? p : 1;
        result[QStringLiteral("total")] = q.value(QStringLiteral("total")).toInt();
    }
    return result;
}

bool LocalBookDatabase::removeBook(const QString &bookId)
{
    if (!m_ready) return false;

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM local_books WHERE bookId = ?"));
    q.addBindValue(bookId);
    return q.exec();
}
