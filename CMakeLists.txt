cmake_minimum_required(VERSION 3.21)
project(Diploma VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.7 REQUIRED COMPONENTS
    Core Gui Quick Qml Sql Pdf Widgets Network WebEngineQuick)

qt_standard_project_setup(REQUIRES 6.7)

# ─── DiplomaDatabase — локальная SQLite БД ────────────────────────────────────
qt_add_library(DiplomaDatabase STATIC)

target_include_directories(DiplomaDatabase PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/DiplomaContent/Database
)

qt_add_qml_module(DiplomaDatabase
    URI "DiplomaContent.Database"
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/DiplomaContent/Database
    SOURCES
        DiplomaContent/Database/LocalBookDatabase.h
        DiplomaContent/Database/LocalBookDatabase.cpp
)

target_link_libraries(DiplomaDatabase PRIVATE
    Qt6::Qml
    Qt6::Sql
)

# ─── DiplomaNetwork — HTTP/GraphQL слой ──────────────────────────────────────
qt_add_library(DiplomaNetwork STATIC)

target_include_directories(DiplomaNetwork PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/DiplomaContent/Network
)

qt_add_qml_module(DiplomaNetwork
    URI "DiplomaContent.Network"
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/DiplomaContent/Network
    SOURCES
        DiplomaContent/Network/AppSettings.h
        DiplomaContent/Network/AppSettings.cpp
        DiplomaContent/Network/TokenManager.h
        DiplomaContent/Network/TokenManager.cpp
        DiplomaContent/Network/GraphQLClient.h
        DiplomaContent/Network/GraphQLClient.cpp
        DiplomaContent/Network/FileUploader.h
        DiplomaContent/Network/FileUploader.cpp
)

target_link_libraries(DiplomaNetwork PRIVATE
    Qt6::Qml
    Qt6::Network
    Qt6::Gui
)

# ─── Diploma — главный исполняемый файл ──────────────────────────────────────
qt_add_executable(Diploma WIN32
    main.cpp
)

qt_add_resources(Diploma "appresources"
    PREFIX "/"
    FILES
        DiplomaContent/images/QDUzAz9yOs.ico
)

target_include_directories(Diploma PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/DiplomaContent/Network
    ${CMAKE_CURRENT_SOURCE_DIR}/DiplomaContent/Database
)

get_target_property(_qmake_exe Qt6::qmake IMPORTED_LOCATION)
get_filename_component(_qt_bin "${_qmake_exe}" DIRECTORY)
get_filename_component(_qt_root "${_qt_bin}" DIRECTORY)

target_compile_definitions(Diploma PRIVATE
    DIPLOMA_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
    DIPLOMA_BUILD_DIR="${CMAKE_BINARY_DIR}"
    DIPLOMA_QT_QML_PATH="${_qt_root}/qml"
)

target_link_libraries(Diploma PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Pdf
    Qt6::Widgets
    Qt6::Network
    Qt6::WebEngineQuick
    DiplomaDatabase
    DiplomaDatabaseplugin
    DiplomaNetwork
    DiplomaNetworkplugin
)
