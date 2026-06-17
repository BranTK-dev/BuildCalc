import QtQuick
import QtQuick.Controls

TextField {
    id: root

    property string suffix: ""
    property color surfaceColor: "#FFFFFF"
    property color softSurfaceColor: "#F9FAF7"
    property color textColor: "#17201A"
    property color mutedColor: "#66736A"
    property color lineColor: "#D3DCD5"
    property color accentColor: "#2F7D46"

    inputMethodHints: Qt.ImhFormattedNumbersOnly
    font.pixelSize: 17
    color: root.textColor
    placeholderTextColor: root.mutedColor
    selectByMouse: true

    rightPadding: suffixLabel.visible ? suffixLabel.width + 20 : 12

    background: Rectangle {
        radius: 8
        color: root.activeFocus ? root.surfaceColor : root.softSurfaceColor
        border.color: root.activeFocus ? root.accentColor : root.lineColor
        border.width: root.activeFocus ? 2 : 1
    }

    Label {
        id: suffixLabel
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.suffix
        visible: text.length > 0
        color: root.mutedColor
        font.pixelSize: 14
    }
}
