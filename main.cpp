#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "databasemanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    DatabaseManager dbManager;
    if (!dbManager.initDatabase()) {
        qWarning() << "Failed to initialize database!";
    }

    QQmlApplicationEngine engine;

    // ربط محرك قاعدة البيانات مع QML باسم dbManager
    engine.rootContext()->setContextProperty("dbManager", &dbManager);

    const QUrl url(QStringLiteral("qrc:/appmusleh/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}