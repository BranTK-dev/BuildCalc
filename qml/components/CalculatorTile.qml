import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root

    property string iconText: ""
    property string label: ""
    property color accentColor: "#2F7D46"
    property color tintColor: "#EEF5F0"
    property color surfaceColor: "#FFFFFF"
    property color textColor: "#17201A"
    property color lineColor: "#DCE4DE"

    signal picked()

    implicitHeight: 104
    padding: 14
    hoverEnabled: true

    background: Rectangle {
        radius: 8
        color: root.down ? Qt.darker(root.tintColor, 1.04) : root.surfaceColor
        border.color: root.hovered ? root.accentColor : root.lineColor
        border.width: 1
    }

    contentItem: RowLayout {
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 48
            height: 48
            radius: 8
            color: root.tintColor

            Label {
                anchors.centerIn: parent
                text: root.iconText
                color: root.accentColor
                font.pixelSize: root.iconText.length > 1 ? 17 : 22
                font.weight: Font.Bold
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.label
            color: root.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    onClicked: picked()
}
