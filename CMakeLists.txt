cmake_minimum_required(VERSION 3.21)

project(BuildCalc VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Quick QuickControls2)
include(GNUInstallDirs)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appBuildCalc
    src/main.cpp
    src/calculatorengine.cpp
    src/calculatorengine.h
)

qt_add_qml_module(appBuildCalc
    URI BuildCalc
    VERSION 1.0
    NO_CACHEGEN
    QML_FILES
        qml/Main.qml
        qml/components/CalculatorTile.qml
        qml/components/MetricField.qml
        qml/components/SegmentedControl.qml
    RESOURCES
        assets/app-cover.png
        assets/app-icon.png
        assets/buildcalc-header.png
)

set_target_properties(appBuildCalc PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appBuildCalc
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
)

install(TARGETS appBuildCalc
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
