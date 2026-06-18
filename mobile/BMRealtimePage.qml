import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Item {
    id: root

    property var deviceModel

    readonly property color pageColor: "#090b0d"
    readonly property color surfaceColor: "#13171a"
    readonly property color goldColor: "#d6ad68"
    readonly property color textColor: "#f4f0e8"
    readonly property color secondaryTextColor: "#92999d"
    readonly property color successColor: "#64d6b0"
    readonly property bool imperial: deviceModel ? deviceModel.useImperialUnits : false
    readonly property double speedKph: deviceModel ? deviceModel.speedMetersPerSecond * 3.6 : 0
    readonly property double displaySpeed: imperial ? speedKph * 0.621371192 : speedKph
    readonly property double displayTrip: deviceModel
                                                ? (imperial ? deviceModel.tripKm * 0.621371192
                                                            : deviceModel.tripKm)
                                                : 0
    readonly property double displayOdometer: deviceModel
                                                    ? (imperial ? deviceModel.odometerKm * 0.621371192
                                                                : deviceModel.odometerKm)
                                                    : 0

    Rectangle {
        anchors.fill: parent
        color: root.pageColor
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: root.width
            spacing: 12

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 20
                text: qsTr("Live ride")
                color: root.textColor
                font.pixelSize: 28
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                text: !root.deviceModel || !root.deviceModel.connected
                      ? qsTr("Connect your BM device to view live data")
                      : (!root.deviceModel.telemetryValid
                         ? qsTr("Waiting for device data")
                         : root.deviceModel.faultText)
                color: root.deviceModel && root.deviceModel.hasFault
                       ? "#ff9f73" : root.secondaryTextColor
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 8
                Layout.preferredHeight: 210
                radius: 8
                color: root.surfaceColor
                border.width: 1
                border.color: root.deviceModel && root.deviceModel.telemetryValid
                              ? "#3f705f" : "#2a3034"

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.deviceModel && root.deviceModel.telemetryValid
                              ? root.displaySpeed.toFixed(0) : "--"
                        color: root.textColor
                        font.pixelSize: 72
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.imperial ? qsTr("mph") : qsTr("km/h")
                        color: root.goldColor
                        font.pixelSize: 15
                        font.bold: true
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                MetricCard {
                    title: qsTr("Battery")
                    batteryMode: true
                    batteryValid: root.deviceModel && root.deviceModel.telemetryValid
                    batteryPercent: root.deviceModel && root.deviceModel.telemetryValid
                                    ? root.deviceModel.batteryPercent : 0
                }
                MetricCard {
                    title: qsTr("Power")
                    value: root.deviceModel && root.deviceModel.telemetryValid
                           ? root.deviceModel.powerWatts.toFixed(0) + " W" : "--"
                }
                MetricCard {
                    title: qsTr("This ride")
                    value: root.deviceModel && root.deviceModel.telemetryValid
                           ? root.displayTrip.toFixed(1) + (root.imperial ? " mi" : " km") : "--"
                }
                MetricCard {
                    title: qsTr("Odometer")
                    value: root.deviceModel && root.deviceModel.telemetryValid
                           ? root.displayOdometer.toFixed(1) + (root.imperial ? " mi" : " km") : "--"
                }
                MetricCard {
                    title: qsTr("Controller")
                    value: root.deviceModel && root.deviceModel.telemetryValid
                           ? root.deviceModel.controllerTemperatureCelsius.toFixed(0) + " °C" : "--"
                }
                MetricCard {
                    title: qsTr("Motor")
                    value: root.deviceModel && root.deviceModel.telemetryValid
                           ? root.deviceModel.motorTemperatureCelsius.toFixed(0) + " °C" : "--"
                }
            }

            Rectangle {
                visible: root.deviceModel && root.deviceModel.hasFault
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: faultText.implicitHeight + 32
                radius: 8
                color: "#321b17"
                border.width: 1
                border.color: "#8f4f3d"

                Text {
                    id: faultText
                    anchors.fill: parent
                    anchors.margins: 16
                    text: qsTr("Device fault: %1").arg(root.deviceModel
                                                       ? root.deviceModel.faultText : "")
                    color: "#ffb39b"
                    font.pixelSize: 13
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
            }
        }
    }

    component MetricCard: Rectangle {
        property string title: ""
        property string value: "--"
        property bool batteryMode: false
        property bool batteryValid: false
        property real batteryPercent: 0

        Layout.fillWidth: true
        Layout.preferredHeight: 96
        radius: 8
        color: root.surfaceColor
        border.width: 1
        border.color: "#262c30"

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 7

            Text {
                width: parent.width
                text: title
                color: root.secondaryTextColor
                font.pixelSize: 12
            }

            Text {
                width: parent.width
                visible: !batteryMode
                text: value
                color: root.textColor
                font.pixelSize: 21
                font.bold: true
                elide: Text.ElideRight
            }

            BMBatteryIndicator {
                width: Math.min(116, parent.width)
                height: 34
                visible: batteryMode
                valid: batteryValid
                percent: batteryPercent
                fillColor: batteryPercent < 20 ? "#ff5c6f" : root.goldColor
                textColor: root.textColor
            }
        }
    }
}
