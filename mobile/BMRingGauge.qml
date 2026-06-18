import QtQuick 2.15

Item {
    id: root

    property real value: 0
    property real maxValue: 60
    property string unit: "KM/H"
    property color accentColor: "#dfbd91"

    implicitWidth: 230
    implicitHeight: 230

    Item {
        width: parent.width
        height: Math.min(88, parent.height * 0.38)
        anchors.centerIn: parent

        Text {
            id: speedText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            text: root.value > 0 ? root.value.toFixed(1) : "--"
            color: "#f4f1ea"
            font.pixelSize: Math.max(42, root.width * 0.19)
            font.bold: true
            font.letterSpacing: 0
        }

        Text {
            id: unitText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: speedText.bottom
            anchors.topMargin: 4
            text: root.unit
            color: "#9aa3b2"
            font.pixelSize: 14
            font.letterSpacing: 2.4
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: unitText.bottom
            anchors.topMargin: 4
            text: qsTr("实时速度")
            color: "#9aa3b2"
            font.pixelSize: 12
        }
    }
}
