import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

// Home page matched to the target screenshot (main.png): a compact "连接设备" card
// (title + 未连接 pill + 连接 button) and a "实时速度" card with the sphere gauge and
// three KPI tiles. Background transparent over BMBackground.
Item {
    id: root

    property var deviceModel
    property var theme
    readonly property real pageMargin: 24

    signal requestConnect()
    signal requestDashboard()
    signal requestDevice()

    readonly property bool transportConnected: deviceModel ? deviceModel.connected : false
    readonly property bool protocolReady: deviceModel ? deviceModel.protocolReady : false
    readonly property bool telemetryValid: deviceModel ? deviceModel.telemetryValid : false
    readonly property bool imperial: deviceModel ? deviceModel.useImperialUnits : false

    readonly property real speedKph: deviceModel ? deviceModel.speedMetersPerSecond * 3.6 : 0
    readonly property real maxSpeedKph: deviceModel ? deviceModel.sessionMaxSpeedMetersPerSecond * 3.6 : 0
    readonly property real displaySpeed: imperial ? speedKph * 0.621371192 : speedKph
    readonly property real displayMaxSpeed: imperial ? maxSpeedKph * 0.621371192 : maxSpeedKph
    readonly property string speedUnit: imperial ? "MPH" : "KM/H"
    readonly property bool hasFault: deviceModel ? deviceModel.hasFault : false
    readonly property string faultText: deviceModel && deviceModel.faultText.length > 0
                                        ? deviceModel.faultText : qsTr("正常")
    readonly property string deviceStatusText: !transportConnected
                                                ? qsTr("未连接")
                                                : (!protocolReady
                                                   ? qsTr("正在识别设备")
                                                : (!telemetryValid
                                                   ? qsTr("读取中")
                                                   : (hasFault
                                                      ? qsTr("需检查 · %1").arg(faultText)
                                                      : qsTr("正常"))))
    readonly property color deviceStatusColor: !transportConnected
                                                ? "#9aa3b2"
                                                : (!protocolReady
                                                   ? "#f2d58a"
                                                : (!telemetryValid
                                                   ? "#f2d58a"
                                                   : (hasFault ? "#ff8b8b" : "#64d6b0")))

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: root.width
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                Layout.topMargin: 14
                spacing: 10

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    enabled: !root.transportConnected
                    onClicked: root.requestConnect()

                    background: Rectangle {
                        radius: 16
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: parent.down ? "#d2a775" : "#dfbd91" }
                            GradientStop { position: 1.0; color: parent.down ? "#b78355" : "#c69c6e" }
                        }
                    }

                    contentItem: Text {
                        text: !root.transportConnected ? qsTr("连接设备")
                              : (!root.protocolReady ? qsTr("正在识别设备") : qsTr("实时数据已显示"))
                        color: "#17120a"
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    Layout.preferredWidth: 94
                    Layout.preferredHeight: 52
                    visible: root.transportConnected
                    enabled: root.transportConnected
                    onClicked: {
                        if (root.deviceModel) root.deviceModel.disconnectDevice()
                    }

                    background: Rectangle {
                        radius: 16
                        color: Qt.rgba(1, 0.36, 0.44, 0.045)
                        border.width: 1
                        border.color: Qt.rgba(1, 0.36, 0.44, 0.32)
                    }

                    contentItem: Text {
                        text: qsTr("断开")
                        color: "#ff5c6f"
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                text: qsTr("请确认设备已开机并靠近手机，连接后查看实时状态")
                      + (root.transportConnected && !root.protocolReady
                         ? qsTr("；当前正在读取设备信息")
                         : "")
                color: "#9aa3b2"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            // ---- 实时速度 card ----
            GlassCard {
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                cardHeight: gaugeColumn.implicitHeight + 34

                Column {
                    id: gaugeColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        width: parent.width
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text {
                                Layout.fillWidth: true
                                text: root.protocolReady && root.deviceModel
                                      ? root.deviceModel.deviceName : qsTr("未连接设备")
                                color: "#f4f1ea"
                                font.pixelSize: 21
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.protocolReady
                                      ? qsTr("实时速度、电量和设备状态")
                                      : qsTr("连接后显示速度、电量和设备状态")
                                color: "#9aa3b2"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                        Pill { text: root.telemetryValid ? qsTr("数据正常") : qsTr("等待数据") }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#283038"
                    }

                    Item {
                        width: parent.width
                        height: 250

                        BMRingGauge {
                            anchors.centerIn: parent
                            width: Math.min(230, parent.width * 0.86)
                            height: width
                            value: root.telemetryValid ? root.displaySpeed : 0
                            maxValue: root.imperial ? 40 : 60
                            unit: root.speedUnit
                            accentColor: root.theme ? root.theme.gold2 : "#dfbd91"
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: metricRow.height + statusMetric.height
                        radius: 18
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        clip: true

                        Column {
                            anchors.fill: parent

                            Row {
                                id: metricRow
                                width: parent.width
                                height: 78
                                spacing: 0

                                Kpi {
                                    width: parent.width / 3
                                    label: qsTr("电量")
                                    batteryMode: true
                                    batteryValid: root.telemetryValid
                                    batteryPercent: root.telemetryValid ? root.deviceModel.batteryPercent : 0
                                }
                                Kpi {
                                    width: parent.width / 3
                                    label: qsTr("里程")
                                    value: root.telemetryValid
                                           ? (root.imperial
                                              ? (root.deviceModel.odometerKm * 0.621371192).toFixed(1) + " mi"
                                              : root.deviceModel.odometerKm.toFixed(1) + " km")
                                           : "--"
                                }
                                Kpi {
                                    width: parent.width / 3
                                    label: qsTr("最高速度")
                                    value: root.telemetryValid ? root.displayMaxSpeed.toFixed(1) : "--"
                                }
                            }

                            StatusRow {
                                id: statusMetric
                                width: parent.width
                                label: qsTr("设备状态")
                                value: root.deviceStatusText
                                valueColor: root.deviceStatusColor
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
            }
        }
    }

    component GlassCard: Rectangle {
        property int cardHeight: 100
        Layout.preferredHeight: cardHeight
        radius: 18
        border.width: 1
        border.color: "#283038"
        color: "#151923"
    }

    component Pill: Rectangle {
        property alias text: pillText.text
        implicitWidth: pillText.implicitWidth + 22
        implicitHeight: 30
        radius: 999
        color: Qt.rgba(0.85, 0.71, 0.42, 0.10)
        border.width: 1
        border.color: Qt.rgba(0.85, 0.71, 0.42, 0.52)
        Text {
            id: pillText
            anchors.centerIn: parent
            color: "#f2d58a"
            font.pixelSize: 13
            font.bold: true
        }
    }

    component Kpi: Rectangle {
        property string label: ""
        property string value: ""
        property bool batteryMode: false
        property bool batteryValid: false
        property real batteryPercent: 0
        readonly property real valueCenterY: 53
        height: 78
        radius: 0
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.08)
        Text {
            id: kpiLabel
            anchors.horizontalCenter: parent.horizontalCenter
            y: 22
            text: label
            color: "#9aa3b2"
            font.pixelSize: 12
        }

        BMBatteryIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            y: valueCenterY - height / 2
            width: 47
            height: 15
            visible: batteryMode
            valid: batteryValid
            percent: batteryPercent
            fillColor: batteryPercent < 20 ? "#ff5c6f" : "#dfbd91"
            textColor: "#f4f1ea"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: valueCenterY - height / 2
            height: implicitHeight
            visible: !batteryMode
            text: value
            color: "#f4f1ea"
            font.pixelSize: 16
            font.bold: true
        }
    }

    component StatusRow: Rectangle {
        property string label: ""
        property string value: ""
        property color valueColor: "#f4f1ea"

        height: 62
        radius: 0
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.08)

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: label
            color: "#9aa3b2"
            font.pixelSize: 13
        }

        Item {
            id: statusValueWindow
            anchors.left: parent.horizontalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            height: statusValue.implicitHeight
            clip: true

            Text {
                id: statusValue
                property bool scrolling: statusValueWindow.width > 0 && implicitWidth > statusValueWindow.width

                text: value
                color: valueColor
                font.pixelSize: 15
                font.bold: true
                x: scrolling ? 0 : statusValueWindow.width - implicitWidth

                onTextChanged: x = scrolling ? 0 : statusValueWindow.width - implicitWidth
                onScrollingChanged: x = scrolling ? 0 : statusValueWindow.width - implicitWidth
            }

            SequentialAnimation {
                running: statusValue.scrolling
                loops: Animation.Infinite

                PauseAnimation { duration: 900 }
                NumberAnimation {
                    target: statusValue
                    property: "x"
                    to: statusValueWindow.width - statusValue.implicitWidth
                    duration: Math.max(3200, statusValue.implicitWidth * 34)
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: 900 }
                ScriptAction { script: statusValue.x = 0 }
            }
        }
    }
}
