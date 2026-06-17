import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property var values: [1, 2, 3]
    property int currentValue: values[0]
    property color softSurfaceColor: "#F9FAF7"
    property color textColor: "#17201A"
    property color lineColor: "#D3DCD5"
    property color accentColor: "#2F7D46"

    spacing: 8

    Repeater {
        model: root.values

        Button {
            required property int modelData

            Layout.fillWidth: true
            implicitHeight: 46
            text: modelData
            checkable: true
            checked: root.currentValue === modelData

            background: Rectangle {
                radius: 8
                color: checked ? root.accentColor : root.softSurfaceColor
                border.color: checked ? root.accentColor : root.lineColor
            }

            contentItem: Label {
                text: parent.text
                color: parent.checked ? "#FFFFFF" : root.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            onClicked: root.currentValue = modelData
        }
    }
}
