cmake_minimum_required(VERSION 3.16)

project(appmusleh VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql)

qt_standard_project_setup()

qt_add_executable(appmusleh
    main.cpp
    databasemanager.cpp
    databasemanager.h
)

qt_add_qml_module(appmusleh
    URI appmusleh
    VERSION 1.0
    QML_FILES Main.qml
)

target_link_libraries(appmusleh PRIVATE Qt6::Quick Qt6::Sql)
