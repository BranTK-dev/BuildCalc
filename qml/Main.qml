pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BuildCalc
import "components"

ApplicationWindow {
    id: window

    width: 390
    height: 844
    visible: true
    title: "BuildCalc"
    color: pageColor

    onClosing: function(close) {
        if (stack.depth > 1) {
            close.accepted = false
            window.navigateBack()
        }
    }

    CalculatorEngine {
        id: engine
    }

    property string currentCalculator: "paint"
    property var currentResult: ({})
    property string errorMessage: ""
    property string toastMessage: ""
    property string greetingText: greeting()
    readonly property bool systemDarkTheme: Application.styleHints.colorScheme === Qt.ColorScheme.Dark
    readonly property color pageColor: engine.darkTheme ? "#121713" : "#F4F1EA"
    readonly property color surfaceColor: engine.darkTheme ? "#1B231E" : "#FFFFFF"
    readonly property color softSurfaceColor: engine.darkTheme ? "#202B24" : "#F9FAF7"
    readonly property color panelColor: engine.darkTheme ? "#17201A" : "#FFFFFF"
    readonly property color inkColor: engine.darkTheme ? "#F3F6F1" : "#17201A"
    readonly property color mutedColor: engine.darkTheme ? "#B3BEB5" : "#647168"
    readonly property color lineColor: engine.darkTheme ? "#344037" : "#DCE4DE"
    readonly property color brandColor: "#2F7D46"

    readonly property var calculators: [
        { key: "paint", label: "Paint", icon: "P", accent: "#2F7D46", tint: "#E6F2E7" },
        { key: "tiling", label: "Tiling", icon: "T", accent: "#446F8A", tint: "#E5EFF5" },
        { key: "concrete", label: "Concrete", icon: "C", accent: "#6E6A5E", tint: "#EFEEE8" },
        { key: "bricks", label: "Bricks", icon: "B", accent: "#B85E3D", tint: "#F7E7DE" },
        { key: "flooring", label: "Flooring", icon: "F", accent: "#9A6A36", tint: "#F4EBD8" },
        { key: "roofing", label: "Roofing", icon: "R", accent: "#5D7F96", tint: "#E5EEF2" },
        { key: "plastering", label: "Plaster", icon: "PL", accent: "#7C735E", tint: "#F1EEE4" }
    ]

    readonly property var calculatorTitles: ({
        paint: "Paint calculator",
        tiling: "Tiling calculator",
        concrete: "Concrete calculator",
        bricks: "Brick calculator",
        flooring: "Flooring calculator",
        roofing: "Roofing sheets",
        plastering: "Plastering"
    })

    function greeting() {
        var hour = new Date().getHours()
        if (hour < 12)
            return "Good morning"
        if (hour < 17)
            return "Good afternoon"
        return "Good evening"
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: window.greetingText = window.greeting()
    }

    Component.onCompleted: engine.setDarkTheme(window.systemDarkTheme)

    Connections {
        target: Application.styleHints
        function onColorSchemeChanged() {
            engine.setDarkTheme(window.systemDarkTheme)
        }
    }

    function openCalculator(key) {
        currentCalculator = key
        errorMessage = ""
        stack.push(inputPage)
    }

    function calculatorMeta(key) {
        for (var i = 0; i < calculators.length; ++i) {
            if (calculators[i].key === key)
                return calculators[i]
        }
        return calculators[0]
    }

    function countryIndex(country) {
        var list = engine.countries()
        for (var i = 0; i < list.length; ++i) {
            if (list[i].country === country)
                return i
        }
        return 0
    }

    function countryMeta(country) {
        var list = engine.countries()
        return list[Math.max(0, countryIndex(country))]
    }

    function openHistoryItem(item) {
        currentResult = item
        toastMessage = ""
        stack.push(resultPage)
    }

    function navigateBack() {
        toastMessage = ""
        errorMessage = ""
        if (stack.depth > 1) {
            stack.pop()
            return true
        }
        return false
    }

    function recentTitle() {
        if (!engine.recent || !engine.recent.title || !engine.recent.headline)
            return ""
        if (engine.recent.title === "undefined" || engine.recent.headline === "undefined")
            return ""
        return engine.recent.title + ", " + engine.recent.headline
    }

    function priceLabel(calculator) {
        var code = engine.currencyCode
        if (calculator === "paint")
            return "Optional price per 5L can (" + code + ")"
        if (calculator === "tiling")
            return "Optional price per tile (" + code + ")"
        if (calculator === "flooring")
            return "Optional price per pack (" + code + ")"
        if (calculator === "concrete")
            return "Optional price per 50kg cement bag (" + code + ")"
        if (calculator === "bricks")
            return "Optional price per brick (" + code + ")"
        if (calculator === "plastering")
            return "Optional price per 50kg cement bag (" + code + ")"
        if (calculator === "roofing")
            return "Optional price per sheet (" + code + ")"
        return "Optional unit price (" + code + ")"
    }

    function extraPriceLabel(calculator) {
        var code = engine.currencyCode
        if (calculator === "concrete")
            return "Optional sand price per m³ (" + code + ")"
        if (calculator === "plastering")
            return "Optional plaster sand price per m³ (" + code + ")"
        return ""
    }

    function thirdPriceLabel(calculator) {
        var code = engine.currencyCode
        if (calculator === "concrete")
            return "Optional stone price per m³ (" + code + ")"
        return ""
    }

    function instructions(calculator) {
        if (calculator === "paint")
            return "Measure the wall width and height, choose the number of coats, then add the price for one 5L paint can if you want a cost estimate."
        if (calculator === "tiling")
            return "Measure the surface, enter tile size in millimetres, and add the price for one tile. The result includes a 10% spare allowance."
        if (calculator === "flooring")
            return "Measure the room, enter how many square metres one flooring pack covers, and add the price for one pack."
        if (calculator === "concrete")
            return "Measure slab length, width, and depth. Add cement bag, sand, and stone prices separately for a fuller material estimate."
        if (calculator === "bricks")
            return "Measure wall length and height, then add the price for one brick. The estimate uses a single-skin wall with 5% extra."
        if (calculator === "plastering")
            return "Measure wall width and height, confirm plaster thickness, then add cement bag and plaster sand prices if needed."
        if (calculator === "roofing")
            return "Enter roof width, sheet length, and effective cover width. Add the price for one roof sheet for the cost."
        return "Enter the site measurements and optional prices to calculate the buying quantity."
    }

    function unitScale(unit) {
        if (unit === "cm")
            return 0.01
        if (unit === "mm")
            return 0.001
        return 1
    }

    function coverWidthPlaceholder(unit) {
        if (unit === "cm")
            return "76.2"
        if (unit === "mm")
            return "762"
        return "0.762"
    }

    Shortcut {
        sequences: [StandardKey.Back]
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!window.navigateBack())
                Qt.quit()
        }
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: homePage
    }

    Component {
        id: homePage

        Page {
            background: Rectangle { color: window.pageColor }

            ScrollView {
                id: homeScroll
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                anchors.topMargin: 18
                anchors.bottomMargin: 16
                clip: true
                contentWidth: availableWidth
                contentHeight: homeColumn.implicitHeight
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    id: homeColumn
                    width: homeScroll.availableWidth
                    spacing: 14

                    ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: window.greetingText
                                color: window.mutedColor
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Label {
                                Layout.fillWidth: true
                                text: "BuildCalc"
                                color: window.inkColor
                                font.pixelSize: 30
                                font.weight: Font.Bold
                            }
                        }

                        RowLayout {
                            spacing: 8

                            ThemeToggle {}

                            Rectangle {
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 42
                                radius: 8
                                color: engine.darkTheme ? window.surfaceColor : "#203326"
                                border.color: engine.darkTheme ? window.lineColor : "transparent"

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    source: "qrc:/qt/qml/BuildCalc/assets/app-icon.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 168
                        radius: 8
                        clip: true
                        color: "#E7EFE7"

                        Image {
                            anchors.fill: parent
                            source: "qrc:/qt/qml/BuildCalc/assets/buildcalc-header.png"
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 56
                            color: engine.darkTheme ? "#17201A" : "#DDEBE0"
                            opacity: engine.darkTheme ? 0.88 : 0.94
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 14
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Label {
                                    text: "Material estimates"
                                    color: engine.darkTheme ? "#F3F6F1" : "#203326"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                }

                                Label {
                                    text: "Fast quantities for site and store runs"
                                    color: engine.darkTheme ? "#B3BEB5" : "#526058"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }

                            Label {
                                text: "7 tools"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                padding: 8
                                background: Rectangle {
                                    radius: 8
                                    color: window.brandColor
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        Layout.fillWidth: true
                        text: "Calculators"
                        color: window.inkColor
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }

                    Label {
                        text: "Metric"
                        color: window.mutedColor
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: window.calculators

                        CalculatorTile {
                            required property var modelData
                            Layout.fillWidth: true
                            label: modelData.label
                            iconText: modelData.icon
                            accentColor: modelData.accent
                            tintColor: engine.darkTheme ? window.softSurfaceColor : modelData.tint
                            surfaceColor: window.surfaceColor
                            textColor: window.inkColor
                            lineColor: window.lineColor
                            onPicked: window.openCalculator(modelData.key)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    radius: 8
                    color: window.surfaceColor
                    border.color: window.lineColor
                    visible: window.recentTitle().length > 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "Recent"
                                color: window.mutedColor
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Label {
                                Layout.fillWidth: true
                                text: window.recentTitle()
                                color: window.inkColor
                                elide: Text.ElideRight
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: window.openCalculator(engine.recent.calculator)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    radius: 8
                    color: window.surfaceColor
                    border.color: window.lineColor
                    visible: engine.history.length > 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "History"
                                color: window.mutedColor
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Label {
                                Layout.fillWidth: true
                                text: engine.history.length + " saved estimate" + (engine.history.length === 1 ? "" : "s")
                                color: window.inkColor
                                elide: Text.ElideRight
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }
                        }

                        Label {
                            text: "View"
                            color: window.brandColor
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: stack.push(historyPage)
                    }
                }

                AdBanner {}
                }
            }
        }
    }

    Component {
        id: historyPage

        Page {
            background: Rectangle { color: window.pageColor }

            header: ToolBar {
                background: Rectangle { color: window.pageColor }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 16

                    ToolButton {
                        text: "<"
                        font.pixelSize: 20
                        onClicked: stack.pop()
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "History"
                        color: window.inkColor
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }

                    Button {
                        id: clearHistoryButton
                        visible: engine.history.length > 0
                        text: "Clear"
                        background: Rectangle {
                            radius: 8
                            color: clearHistoryButton.down ? window.softSurfaceColor : window.surfaceColor
                            border.color: window.lineColor
                        }
                        contentItem: Label {
                            text: clearHistoryButton.text
                            color: window.mutedColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        onClicked: engine.clearHistory()
                    }
                }
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10
                clip: true
                model: engine.history

                delegate: Rectangle {
                    id: historyCard
                    required property var modelData

                    width: ListView.view.width
                    height: 132
                    radius: 8
                    color: window.surfaceColor
                    border.color: window.lineColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: historyCard.modelData.title
                                color: window.inkColor
                                elide: Text.ElideRight
                                font.pixelSize: 15
                                font.weight: Font.Bold
                            }

                            Label {
                                text: historyCard.modelData.timestamp
                                color: window.mutedColor
                                font.pixelSize: 11
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: historyCard.modelData.headline
                            color: window.brandColor
                            elide: Text.ElideRight
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }

                        Label {
                            Layout.fillWidth: true
                            text: historyCard.modelData.purchase + (historyCard.modelData.cost ? " · " + historyCard.modelData.cost : "")
                            color: window.mutedColor
                            elide: Text.ElideRight
                            font.pixelSize: 13
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                id: openHistoryButton
                                Layout.fillWidth: true
                                text: "Open"
                                background: Rectangle {
                                    radius: 8
                                    color: openHistoryButton.down ? window.softSurfaceColor : window.surfaceColor
                                    border.color: window.brandColor
                                }
                                contentItem: Label {
                                    text: openHistoryButton.text
                                    color: window.brandColor
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                onClicked: window.openHistoryItem(historyCard.modelData)
                            }

                            Button {
                                id: copyHistoryButton
                                Layout.fillWidth: true
                                text: "Copy"
                                background: Rectangle {
                                    radius: 8
                                    color: copyHistoryButton.down ? window.softSurfaceColor : window.surfaceColor
                                    border.color: window.lineColor
                                }
                                contentItem: Label {
                                    text: copyHistoryButton.text
                                    color: window.inkColor
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                onClicked: {
                                    engine.copyText(engine.shareText(historyCard.modelData))
                                    window.toastMessage = "Estimate copied"
                                }
                            }

                            Button {
                                id: whatsappHistoryButton
                                Layout.fillWidth: true
                                text: "WhatsApp"
                                background: Rectangle {
                                    radius: 8
                                    color: whatsappHistoryButton.down ? window.softSurfaceColor : window.surfaceColor
                                    border.color: window.lineColor
                                }
                                contentItem: Label {
                                    text: whatsappHistoryButton.text
                                    color: window.inkColor
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                onClicked: Qt.openUrlExternally("https://wa.me/?text=" + encodeURIComponent(engine.shareText(historyCard.modelData)))
                            }
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: engine.history.length === 0
                    text: "No saved estimates yet"
                    color: window.mutedColor
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Component {
        id: inputPage

        Page {
            id: inputView

            readonly property var meta: window.calculatorMeta(window.currentCalculator)
            property string measurementUnit: "m"

            function runCalculation() {
                var scale = window.unitScale(measurementUnit)
                var payload = ({
                    width: Number(widthField.text) * scale,
                    height: Number(heightField.text) * scale,
                    length: Number(lengthField.text) * scale,
                    depth: Number(depthField.text) * scale,
                    coats: coatsControl.currentValue,
                    tileWidth: Number(tileWidthField.text || 300) / 1000,
                    tileHeight: Number(tileHeightField.text || 300) / 1000,
                    packCoverage: Number(packField.text || 2.2),
                    thickness: Number(thicknessField.text || 12),
                    coverWidth: coverWidthField.text.length > 0 ? Number(coverWidthField.text) * scale : 0.762,
                    price: Number(priceField.text),
                    price2: Number(priceTwoField.text),
                    price3: Number(priceThreeField.text),
                    currencyCode: engine.currencyCode,
                    currencySymbol: engine.currencySymbol
                })
                var result = engine.calculate(window.currentCalculator, payload)
                if (!result.ok) {
                    window.errorMessage = result.error
                    return
                }
                window.currentResult = result
                stack.push(resultPage)
            }

            background: Rectangle { color: window.pageColor }

            header: ToolBar {
                background: Rectangle { color: window.pageColor }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 16

                    ToolButton {
                        text: "<"
                        Layout.preferredWidth: 42
                        icon.width: 20
                        font.pixelSize: 20
                        onClicked: stack.pop()
                    }

                    Label {
                        Layout.fillWidth: true
                        text: window.calculatorTitles[window.currentCalculator]
                        color: window.inkColor
                        elide: Text.ElideRight
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }

                    CountryChip {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 38
                        compact: true
                    }

                    ThemeToggle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 38
                    }
                }
            }

            ScrollView {
                id: inputScroll
                anchors.fill: parent
                anchors.margins: 20
                anchors.bottomMargin: 92
                clip: true
                contentWidth: availableWidth
                contentHeight: inputColumn.implicitHeight
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    id: inputColumn
                    width: inputScroll.availableWidth
                    spacing: 16

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 8
                        color: engine.darkTheme ? window.surfaceColor : inputView.meta.tint
                        border.color: engine.darkTheme ? window.lineColor : "transparent"
                        implicitHeight: Math.max(92, introColumn.implicitHeight + 28)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 52
                                Layout.preferredHeight: 52
                                radius: 8
                                color: inputView.meta.accent

                                Label {
                                    anchors.centerIn: parent
                                    text: inputView.meta.icon
                                    color: "#FFFFFF"
                                    font.pixelSize: inputView.meta.icon.length > 1 ? 17 : 24
                                    font.weight: Font.Bold
                                }
                            }

                            ColumnLayout {
                                id: introColumn
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: inputView.meta.label
                                    color: window.inkColor
                                    font.pixelSize: 19
                                    font.weight: Font.Bold
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: window.instructions(window.currentCalculator)
                                    color: window.mutedColor
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: 13
                                    lineHeight: 1.05
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 8
                        color: window.surfaceColor
                        border.color: window.lineColor
                        implicitHeight: formColumn.implicitHeight + 32

                        ColumnLayout {
                            id: formColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 7

                                Label {
                                    Layout.fillWidth: true
                                    text: "Measurement unit"
                                    color: window.mutedColor
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                UnitSelector {
                                    Layout.fillWidth: true
                                    currentUnit: inputView.measurementUnit
                                    accentColor: inputView.meta.accent
                                    softSurfaceColor: window.softSurfaceColor
                                    textColor: window.inkColor
                                    lineColor: window.lineColor
                                    onPicked: function(unit) { inputView.measurementUnit = unit }
                                }
                            }

                            FieldGroup {
                                id: widthField
                                label: "Width"
                                suffix: inputView.measurementUnit
                                visible: window.currentCalculator !== "bricks"
                            }

                            FieldGroup {
                                id: heightField
                                label: window.currentCalculator === "bricks" ? "Wall height" : "Height"
                                suffix: inputView.measurementUnit
                                visible: window.currentCalculator === "paint" || window.currentCalculator === "tiling" || window.currentCalculator === "plastering" || window.currentCalculator === "bricks"
                            }

                            FieldGroup {
                                id: lengthField
                                label: window.currentCalculator === "roofing" ? "Sheet length" : window.currentCalculator === "bricks" ? "Wall length" : "Length"
                                suffix: inputView.measurementUnit
                                visible: window.currentCalculator === "flooring" || window.currentCalculator === "concrete" || window.currentCalculator === "roofing" || window.currentCalculator === "bricks"
                            }

                            FieldGroup {
                                id: depthField
                                label: "Depth"
                                suffix: inputView.measurementUnit
                                visible: window.currentCalculator === "concrete"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 7
                                visible: window.currentCalculator === "paint"

                                Label { text: "Coats"; color: window.mutedColor; font.pixelSize: 14; font.weight: Font.DemiBold }
                                SegmentedControl {
                                    id: coatsControl
                                    Layout.fillWidth: true
                                    currentValue: 2
                                    accentColor: inputView.meta.accent
                                    softSurfaceColor: window.softSurfaceColor
                                    textColor: window.inkColor
                                    lineColor: window.lineColor
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                visible: window.currentCalculator === "tiling"

                                FieldGroup { id: tileWidthField; Layout.fillWidth: true; label: "Tile width"; suffix: "mm"; placeholderText: "300" }
                                FieldGroup { id: tileHeightField; Layout.fillWidth: true; label: "Tile height"; suffix: "mm"; placeholderText: "300" }
                            }

                            FieldGroup {
                                id: packField
                                label: "Pack coverage"
                                suffix: "m²"
                                placeholderText: "2.2"
                                visible: window.currentCalculator === "flooring"
                            }

                            FieldGroup {
                                id: thicknessField
                                label: "Thickness"
                                suffix: "mm"
                                placeholderText: "12"
                                visible: window.currentCalculator === "plastering"
                            }

                            FieldGroup {
                                id: coverWidthField
                                label: "Cover width"
                                suffix: inputView.measurementUnit
                                placeholderText: window.coverWidthPlaceholder(inputView.measurementUnit)
                                visible: window.currentCalculator === "roofing"
                            }

                            FieldGroup {
                                id: priceField
                                label: window.priceLabel(window.currentCalculator)
                            }

                            FieldGroup {
                                id: priceTwoField
                                label: window.extraPriceLabel(window.currentCalculator)
                                visible: label.length > 0
                            }

                            FieldGroup {
                                id: priceThreeField
                                label: window.thirdPriceLabel(window.currentCalculator)
                                visible: label.length > 0
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: window.errorMessage
                        visible: window.errorMessage.length > 0
                        color: "#A33C2F"
                        wrapMode: Text.WordWrap
                        font.pixelSize: 14
                    }

                    Button {
                        id: calculateButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        text: "Calculate"
                        font.pixelSize: 17
                        font.weight: Font.Bold
                        background: Rectangle {
                            radius: 8
                            color: calculateButton.down ? Qt.darker(inputView.meta.accent, 1.12) : inputView.meta.accent
                        }
                        contentItem: Label {
                            text: calculateButton.text
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font: calculateButton.font
                        }
                        onClicked: inputView.runCalculation()
                    }
                }
            }

            AdBanner {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 20
            }
        }
    }

    Component {
        id: resultPage

        Page {
            id: resultView

            readonly property var meta: window.calculatorMeta(window.currentResult.calculator || window.currentCalculator)

            background: Rectangle { color: window.pageColor }

            header: ToolBar {
                background: Rectangle { color: window.pageColor }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 16

                    ToolButton {
                        text: "<"
                        font.pixelSize: 20
                        onClicked: stack.pop()
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Result"
                        color: window.inkColor
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }
                }
            }

            ScrollView {
                id: resultScroll
                anchors.fill: parent
                anchors.margins: 20
                clip: true
                contentWidth: availableWidth
                contentHeight: resultColumn.implicitHeight
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                id: resultColumn
                width: resultScroll.availableWidth
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    radius: 8
                    color: resultView.meta.accent
                    implicitHeight: 202

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            Rectangle {
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 42
                                radius: 8
                                color: "#FFFFFF"
                                opacity: 0.95

                                Label {
                                    anchors.centerIn: parent
                                    text: resultView.meta.icon
                                    color: resultView.meta.accent
                                    font.pixelSize: resultView.meta.icon.length > 1 ? 15 : 20
                                    font.weight: Font.Bold
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: resultView.meta.label
                                color: "#FFFFFF"
                                horizontalAlignment: Text.AlignRight
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: window.currentResult.headline || ""
                            color: "#FFFFFF"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 34
                            font.weight: Font.Bold
                        }

                        Label {
                            Layout.fillWidth: true
                            text: window.currentResult.context || ""
                            color: "#EAF4ED"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 15
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 8
                    color: window.surfaceColor
                    border.color: window.lineColor
                    implicitHeight: breakdownColumn.implicitHeight + 32

                    ColumnLayout {
                        id: breakdownColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 12

                        Label {
                            Layout.fillWidth: true
                            text: "Buying breakdown"
                            color: window.inkColor
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        ResultRow {
                            label: "Purchase unit"
                            value: window.currentResult.purchase || ""
                            accentColor: resultView.meta.accent
                        }

                        ResultRow {
                            label: "Allowance"
                            value: window.currentResult.secondary || ""
                            accentColor: resultView.meta.accent
                        }

                        ResultRow {
                            label: "Cost"
                            value: window.currentResult.cost || "Not entered"
                            accentColor: resultView.meta.accent
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: window.lineColor
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Formula estimates are a planning guide. Confirm final quantities with supplier specs before buying."
                            color: window.mutedColor
                            wrapMode: Text.WordWrap
                            font.pixelSize: 14
                        }
                    }
                }

                Button {
                    id: shareButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    text: "Share email"
                    background: Rectangle {
                        radius: 8
                        color: shareButton.down ? Qt.darker(resultView.meta.accent, 1.12) : resultView.meta.accent
                    }
                    contentItem: Label {
                        text: shareButton.text
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    onClicked: Qt.openUrlExternally("mailto:?subject=BuildCalc Material Estimate&body=" + encodeURIComponent(engine.shareText(window.currentResult)))
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        id: copyButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        text: "Copy"
                        background: Rectangle {
                            radius: 8
                            color: copyButton.down ? Qt.darker(resultView.meta.accent, 1.2) : resultView.meta.accent
                            border.color: resultView.meta.accent
                        }
                        contentItem: Label {
                            text: copyButton.text
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        onClicked: {
                            engine.copyText(engine.shareText(window.currentResult))
                            window.toastMessage = "Estimate copied"
                        }
                    }

                    Button {
                        id: whatsappButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        text: "WhatsApp"
                        background: Rectangle {
                            radius: 8
                            color: whatsappButton.down ? Qt.darker(resultView.meta.accent, 1.2) : resultView.meta.accent
                            border.color: resultView.meta.accent
                        }
                        contentItem: Label {
                            text: whatsappButton.text
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        onClicked: Qt.openUrlExternally("https://wa.me/?text=" + encodeURIComponent(engine.shareText(window.currentResult)))
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: window.toastMessage
                    visible: window.toastMessage.length > 0
                    color: resultView.meta.accent
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Button {
                    id: newCalculationButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    text: "New calculation"
                    background: Rectangle {
                        radius: 8
                        color: newCalculationButton.down ? window.softSurfaceColor : (engine.darkTheme ? "#213528" : window.surfaceColor)
                        border.color: resultView.meta.accent
                        border.width: 2
                    }
                    contentItem: Label {
                        text: newCalculationButton.text
                        color: engine.darkTheme ? "#F3F6F1" : resultView.meta.accent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    onClicked: {
                        stack.pop(stack.get(0))
                    }
                }

                AdBanner {}
                }
            }
        }
    }

    component FieldGroup: ColumnLayout {
        id: fieldGroup

        property alias label: fieldLabel.text
        property alias text: input.text
        property alias placeholderText: input.placeholderText
        property alias suffix: input.suffix
        property color accentColor: window.brandColor

        spacing: 7

        Label {
            id: fieldLabel
            Layout.fillWidth: true
            color: window.mutedColor
            wrapMode: Text.WordWrap
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        MetricField {
            id: input
            Layout.fillWidth: true
            implicitHeight: 48
            surfaceColor: window.surfaceColor
            softSurfaceColor: window.softSurfaceColor
            textColor: window.inkColor
            mutedColor: window.mutedColor
            lineColor: window.lineColor
            accentColor: fieldGroup.accentColor
        }
    }

    component ResultRow: RowLayout {
        id: resultRow

        property string label: ""
        property string value: ""
        property color accentColor: window.brandColor

        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 38
            radius: 4
            color: resultRow.accentColor
            opacity: 0.85
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                Layout.fillWidth: true
                text: resultRow.label
                color: window.mutedColor
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                text: resultRow.value
                color: window.inkColor
                wrapMode: Text.WordWrap
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }
    }

    component UnitSelector: RowLayout {
        id: unitSelector

        property string currentUnit: "m"
        property color softSurfaceColor: "#F9FAF7"
        property color textColor: "#17201A"
        property color lineColor: "#D3DCD5"
        property color accentColor: "#2F7D46"

        signal picked(string unit)

        spacing: 8

        Repeater {
            model: ["m", "cm", "mm"]

            Button {
                id: unitButton
                required property string modelData

                Layout.fillWidth: true
                implicitHeight: 44
                text: modelData
                checkable: true
                checked: unitSelector.currentUnit === modelData

                background: Rectangle {
                    radius: 8
                    color: unitButton.checked ? unitSelector.accentColor : unitSelector.softSurfaceColor
                    border.color: unitButton.checked ? unitSelector.accentColor : unitSelector.lineColor
                }

                contentItem: Label {
                    text: unitButton.text
                    color: unitButton.checked ? "#FFFFFF" : unitSelector.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                onClicked: {
                    unitSelector.currentUnit = modelData
                    unitSelector.picked(modelData)
                }
            }
        }
    }

    component AdBanner: Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 0
        visible: false
    }

    component ThemeToggle: Button {
        id: themeButton

        implicitHeight: 38
        implicitWidth: 64
        padding: 0

        background: Rectangle {
            radius: 19
            color: engine.darkTheme ? "#263128" : "#FFFFFF"
            border.color: window.lineColor

            Rectangle {
                width: 30
                height: 30
                radius: 15
                anchors.verticalCenter: parent.verticalCenter
                x: engine.darkTheme ? parent.width - width - 4 : 4
                color: window.brandColor
            }
        }

        contentItem: Item {}

        onClicked: engine.setDarkTheme(!engine.darkTheme)
    }

    component CountryChip: Button {
        id: countryChip

        property bool compact: false
        readonly property var meta: window.countryMeta(engine.country)

        implicitHeight: 38
        implicitWidth: compact ? 64 : 96
        padding: 0

        background: Rectangle {
            radius: 8
            color: window.surfaceColor
            border.color: countryChip.down ? window.brandColor : window.lineColor
        }

        contentItem: Item {
            anchors.fill: parent

            Rectangle {
                id: countryBadge
                width: countryChip.compact ? 44 : 34
                height: 26
                radius: 6
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: countryChip.compact ? undefined : parent.left
                anchors.leftMargin: countryChip.compact ? 0 : 8
                anchors.horizontalCenter: countryChip.compact ? parent.horizontalCenter : undefined
                color: window.brandColor

                Label {
                    anchors.centerIn: parent
                    text: countryChip.meta.initials
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }

            Label {
                anchors.left: countryBadge.right
                anchors.leftMargin: 6
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: !countryChip.compact
                text: countryChip.meta.currencyCode
                color: window.inkColor
                elide: Text.ElideRight
                font.pixelSize: 12
                font.weight: Font.Bold
            }
        }

        onClicked: countryPopup.open()

        Popup {
            id: countryPopup
            parent: Overlay.overlay
            x: Math.max(12, Math.min(window.width - width - 12, countryChip.mapToItem(parent, 0, 0).x + countryChip.width - width))
            y: Math.min(window.height - height - 12, countryChip.mapToItem(parent, 0, 0).y + countryChip.height + 8)
            width: Math.min(320, window.width - 24)
            height: Math.min(420, window.height - y - 12, countryList.contentHeight + 18)
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: Rectangle {
                radius: 8
                color: window.surfaceColor
                border.color: window.lineColor
            }

            ListView {
                id: countryList
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                model: engine.countries()

                delegate: ItemDelegate {
                    id: countryDelegate
                    required property var modelData

                    width: countryList.width
                    height: 52
                    onClicked: {
                        engine.setCountry(modelData.country)
                        countryPopup.close()
                    }

                    background: Rectangle {
                        radius: 8
                        color: countryDelegate.hovered || countryDelegate.modelData.country === engine.country ? window.softSurfaceColor : "transparent"
                    }

                    contentItem: RowLayout {
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 30
                            radius: 7
                            color: countryDelegate.modelData.country === engine.country ? window.brandColor : window.softSurfaceColor
                            border.color: window.lineColor

                            Label {
                                anchors.centerIn: parent
                                text: countryDelegate.modelData.initials
                                color: countryDelegate.modelData.country === engine.country ? "#FFFFFF" : window.inkColor
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                text: countryDelegate.modelData.country
                                color: window.inkColor
                                elide: Text.ElideRight
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Label {
                                Layout.fillWidth: true
                                text: countryDelegate.modelData.currencyCode + " · " + countryDelegate.modelData.currencySymbol
                                color: window.mutedColor
                                elide: Text.ElideRight
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }

}
