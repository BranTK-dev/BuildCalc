#include <QCoreApplication>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#include "calculatorengine.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName("BuildCalc");
    QGuiApplication::setOrganizationName("BuildCalc");
    QGuiApplication::setWindowIcon(QIcon(":/qt/qml/BuildCalc/assets/app-icon.png"));
    QQuickStyle::setStyle("Material");

    qmlRegisterType<CalculatorEngine>("BuildCalc", 1, 0, "CalculatorEngine");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("BuildCalc", "Main");

    return app.exec();
}
