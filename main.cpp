#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QUrl>
#include <QDir>
#include <QLibraryInfo>
#include <QDebug>
#include <QIcon>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

#include <QtQml/qqmlextensionplugin.h>
Q_IMPORT_QML_PLUGIN(DiplomaContent_DatabasePlugin)
Q_IMPORT_QML_PLUGIN(DiplomaContent_NetworkPlugin)

// Явно инициализируем C++ синглтоны до загрузки QML, чтобы они были
// доступны из GraphQLClient::execute() в момент первого запроса.
#include "AppSettings.h"
#include "TokenManager.h"
#include "GraphQLClient.h"

int main(int argc, char *argv[])
{
    QtWebEngineQuick::initialize();
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Elib"));
    app.setApplicationDisplayName(QStringLiteral("Elib"));
    app.setOrganizationName(QStringLiteral("ELib"));
    app.setWindowIcon(QIcon(QStringLiteral(":/DiplomaContent/images/QDUzAz9yOs.ico")));

    QQmlApplicationEngine engine;

    // Создаём синглтоны с parent = &engine (освобождаются вместе с движком).
    // create()-фабрики QML_SINGLETON вернут эти же объекты при первом
    // обращении из QML.
    new AppSettings(&engine);
    new TokenManager(&engine);
    new GraphQLClient(&engine);  // инициализирует m_jsEngine из parent до загрузки QML

    // Бинарная директория содержит сгенерированные qmldir для C++ модулей
    engine.addImportPath(QStringLiteral(DIPLOMA_BUILD_DIR));

    // Qt QML-плагины (в т.ч. QtWebEngineQuick).
    // Qt 6 CMake встраивает qt.conf в ресурс exe и перенаправляет QmlImportsPath
    // на папку сборки — системные модули туда не копируются.
    // Добавляем реальный путь Qt из compile-definition, вычисленного CMake.
    engine.addImportPath(QLibraryInfo::path(QLibraryInfo::QmlImportsPath));
    engine.addImportPath(QStringLiteral(DIPLOMA_QT_QML_PATH));

    const QString src = QStringLiteral(DIPLOMA_SOURCE_DIR);
    for (const QString &path : {
             src,
             src + QStringLiteral("/DiplomaContent/UI_Elements"),
             src + QStringLiteral("/DiplomaContent/UI_Effects"),
             src + QStringLiteral("/DiplomaContent/Pages"),
             src + QStringLiteral("/DiplomaContent/Navigation"),
             src + QStringLiteral("/DiplomaContent/Presenters"),
             src + QStringLiteral("/DiplomaContent/Models"),
             src + QStringLiteral("/DiplomaContent/Components"),
             src + QStringLiteral("/DiplomaContent/Services"),
             src + QStringLiteral("/DiplomaContent/Api")
         }) {
        engine.addImportPath(path);
    }

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(QUrl::fromLocalFile(
        src + QStringLiteral("/DiplomaContent/App.qml")));

    return app.exec();
}
