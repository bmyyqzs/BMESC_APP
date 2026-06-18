import QtQuick 2.15

Item {
    id: root

    property real percent: 0
    property bool valid: false
    property color fillColor: clampedPercent < 20 ? "#ff5c6f" : "#dfbd91"
    property color emptyColor: "#11161c"
    property color borderColor: Qt.rgba(255, 255, 255, 0.28)
    property color textColor: "#f4f1ea"

    readonly property real safePercent: isFinite(percent) ? percent : 0
    readonly property real clampedPercent: Math.max(0, Math.min(100, safePercent))
    readonly property real terminalWidth: Math.max(2, height * 0.12)
    readonly property real bodyPadding: height < 22 ? 2 : 3

    implicitWidth: 92
    implicitHeight: 32

    Rectangle {
        id: batteryBody
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - root.terminalWidth - 3
        height: parent.height
        radius: Math.max(3, height * 0.22)
        color: root.emptyColor
        border.width: 1
        border.color: root.valid ? root.borderColor : Qt.rgba(255, 255, 255, 0.14)
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: root.bodyPadding
            width: root.valid
                   ? Math.max(0, (parent.width - (root.bodyPadding * 2)) * root.clampedPercent / 100)
                   : 0
            radius: Math.max(2, height * 0.24)
            color: root.fillColor
            opacity: root.valid ? 1.0 : 0.0

            Behavior on width {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.06)
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - 4
            text: root.valid ? Math.round(root.clampedPercent) + "%" : "--"
            color: root.textColor
            font.pixelSize: Math.min(14, Math.max(6, parent.height * 0.46))
            font.bold: true
            fontSizeMode: Text.Fit
            minimumPixelSize: 5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    Rectangle {
        anchors.left: batteryBody.right
        anchors.leftMargin: 3
        anchors.verticalCenter: batteryBody.verticalCenter
        width: root.terminalWidth
        height: Math.max(6, batteryBody.height * 0.42)
        radius: Math.max(1, width * 0.4)
        color: root.valid ? root.borderColor : Qt.rgba(255, 255, 255, 0.14)
    }
}
