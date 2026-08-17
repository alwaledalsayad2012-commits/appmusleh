cmake_minimum_required(VERSION 3.16)

project(appmusleh VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql)

qt_standard_project_setup()

qt_add_executable(appmusleh MANUAL_FINALIZATION
    main.cpp
    databasemanager.h
    databasemanager.cpp
)

set_target_properties(appmusleh PROPERTIES
   QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")

qt_add_qml_module(appmusleh
    URI appmusleh
    VERSION 1.0
    QML_FILES
        Main.qml
)

target_link_libraries(appmusleh
    PRIVATE
    Qt6::Quick
    Qt6::Sql
)

qt_finalize_executable(appmusleh)

include(GNUInstallDirs)
install(TARGETS appmusleh
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)