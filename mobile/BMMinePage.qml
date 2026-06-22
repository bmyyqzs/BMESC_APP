import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Item {
    id: root

    property var deviceModel
    readonly property real pageMargin: Math.max(24, Math.min(40, width * 0.065))
    readonly property bool connected: deviceModel ? deviceModel.connected : false
    readonly property bool isEnglish: deviceModel ? deviceModel.isEnglish : false
    signal langToggled()

    function t(zh, en) {
        return root.isEnglish ? en : zh
    }

    function showInfo(title, body) {
        infoTitle.text = title
        infoBody.text = body
        infoModal.open()
    }

    function showFaultLogs() {
        faultLogModal.open()
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: root.width
            spacing: 18

            Surface {
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                Layout.topMargin: 6
                height: settingsColumn.implicitHeight

                Column {
                    id: settingsColumn
                    width: parent.width

                    ActionRow {
                        label: root.t("语言", "Language")
                        value: root.isEnglish ? "English" : "简体中文"
                        onClicked: root.langToggled()
                    }
                    ActionRow {
                        label: root.t("单位", "Units")
                        value: root.deviceModel && root.deviceModel.useImperialUnits ? "mph" : "km/h"
                        onClicked: if (root.deviceModel) root.deviceModel.useImperialUnits = !root.deviceModel.useImperialUnits
                    }
                    ActionRow {
                        label: root.t("故障日志", "Fault Logs")
                        value: root.deviceModel && root.deviceModel.faultLogCount > 0
                               ? root.t("%1 条", "%1 items").arg(root.deviceModel.faultLogCount)
                               : root.t("无记录", "None")
                        onClicked: root.showFaultLogs()
                    }
                    ActionRow {
                        label: root.t("支持与反馈", "Support")
                        value: root.t("查看", "View")
                        onClicked: root.showInfo(root.t("支持与反馈", "Support"),
                                                 root.t("如遇到连接失败、数据异常或设备安全提示，请记录设备名称、节点 ID 和发生时间，并发邮件到 op727142092@gmail.com。",
                                                        "If connection fails, data looks abnormal, or a safety warning appears, record the device name, node ID, and time, then email op727142092@gmail.com."))
                    }
                    ActionRow {
                        label: root.t("隐私政策", "Privacy Policy")
                        value: root.t("查看", "View")
                        onClicked: root.showInfo(root.t("隐私政策", "Privacy Policy"),
                                                 root.t("蓝牙权限仅用于发现和连接附近 BMESC 设备。遥测数据用于本地状态显示，不用于账号或云端绑定。",
                                                        "Bluetooth permission is used only to find and connect nearby BMESC devices. Telemetry is used for local status display, not accounts or cloud binding."))
                    }
                    ActionRow {
                        label: root.t("用户协议", "User Agreement")
                        value: root.t("查看", "View")
                        onClicked: root.showInfo(root.t("用户协议", "User Agreement"),
                                                 root.t("请在安全环境中使用设备。App 展示的数据用于辅助判断设备状态，不替代设备本身的安全检查。",
                                                        "Use the device in a safe environment. App data helps judge device status and does not replace the device's own safety checks."))
                    }
                    ActionRow {
                        label: root.t("关于 BMESC", "About BMESC")
                        value: root.t("查看", "View")
                        showDivider: false
                        onClicked: root.showInfo(root.t("关于 BMESC", "About BMESC"),
                                                 root.t("BMESC 是一个面向电机驱动应用的软硬件品牌，围绕 VESC 生态提供电机控制硬件设备与移动端管理工具。\n\n" +
                                                        "BMESC 品牌主要包含 BMESC 硬件设备 与 BMESC APP 两部分。\n\n" +
                                                        "BMESC 硬件设备\n" +
                                                        "用于实现电机驱动与控制，支持电机运行、功率输出、状态反馈、参数配置和故障诊断等功能，适用于电动车、平衡车、滑板车、机器人及其他电机驱动场景。\n\n" +
                                                        "BMESC APP\n" +
                                                        "是配套 BMESC 硬件设备使用的移动端管理工具。用户可以通过 APP 查看速度、电量、里程、最高速度、故障日志等常用信息，更直观地了解设备运行状态。\n\n" +
                                                        "BMESC 将持续围绕 VESC 生态进行软硬件优化与适配，为更多电机驱动应用提供稳定、实用、易用的工具和驱动器支持。\n\n" +
                                                        "如需了解更多信息、技术交流或商务合作，请联系：\n" +
                                                        "op727142092@gmail.com",
                                                        "BMESC is a software and hardware brand for motor-drive applications, providing motor-control hardware devices and mobile management tools around the VESC ecosystem.\n\n" +
                                                        "The BMESC brand mainly includes two parts: BMESC hardware devices and the BMESC app.\n\n" +
                                                        "BMESC Hardware Devices\n" +
                                                        "Used for motor drive and control, supporting motor operation, power output, status feedback, parameter configuration, and fault diagnosis. They are suitable for electric vehicles, balance vehicles, scooters, robots, and other motor-drive scenarios.\n\n" +
                                                        "BMESC App\n" +
                                                        "A mobile management tool used with BMESC hardware devices. Users can view common information such as speed, battery level, mileage, top speed, and fault logs through the app to better understand device operating status.\n\n" +
                                                        "BMESC will continue optimizing and adapting software and hardware around the VESC ecosystem, providing stable, practical, and easy-to-use tools and driver support for more motor-drive applications.\n\n" +
                                                        "For more information, technical discussion, or business cooperation, contact:\n" +
                                                        "op727142092@gmail.com"))
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
            }
        }
    }

    Popup {
        id: faultLogModal
        parent: Overlay.overlay
        width: Math.min(root.width * 0.9, 348)
        height: Math.min(root.height * 0.76, 560)
        x: Math.max(0, Math.round((parent.width - width) / 2))
        y: Math.max(0, Math.round((parent.height - height) / 2))
        modal: true
        focus: true
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 24
            color: "#111620"
            border.width: 1
            border.color: Qt.rgba(0.78, 0.61, 0.43, 0.40)
        }

        Overlay.modal: Rectangle { color: "#b8000000" }

        contentItem: Item {
            RowLayout {
                id: faultLogHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        Layout.fillWidth: true
                        text: root.t("故障日志", "Fault Logs")
                        color: "#f4f1ea"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.deviceModel && root.deviceModel.faultLogCount > 0
                              ? root.t("最近 %1 条本地记录", "%1 recent local records").arg(root.deviceModel.faultLogCount)
                              : root.t("暂无历史故障", "No fault history")
                        color: "#9aa3b2"
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                id: faultLogDivider
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: faultLogHeader.bottom
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 14
                height: 1
                color: "#283038"
            }

            Item {
                id: faultLogBody
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: faultLogDivider.bottom
                anchors.bottom: faultLogActions.top
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 14
                anchors.bottomMargin: 14

                Text {
                    anchors.centerIn: parent
                    visible: !root.deviceModel || root.deviceModel.faultLogCount === 0
                    width: parent.width
                    text: root.t("设备出现故障提示时，App 会自动保存时间、设备和关键状态。",
                                 "When a device fault appears, the app saves the time, device, and key status locally.")
                    color: "#9aa3b2"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Flickable {
                    id: faultLogFlickable
                    anchors.fill: parent
                    visible: root.deviceModel && root.deviceModel.faultLogCount > 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    interactive: contentHeight > height
                    contentWidth: width
                    contentHeight: faultLogList.implicitHeight

                    Column {
                        id: faultLogList
                        width: faultLogFlickable.width - (faultLogScrollBar.visible ? 8 : 0)
                        spacing: 10

                        Repeater {
                            model: root.deviceModel ? root.deviceModel.faultLogs : []

                            FaultLogRow {
                                width: parent.width
                                log: modelData
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        id: faultLogScrollBar
                        policy: faultLogFlickable.contentHeight > faultLogFlickable.height
                                ? ScrollBar.AlwaysOn
                                : ScrollBar.AlwaysOff
                        active: true
                    }
                }
            }

            RowLayout {
                id: faultLogActions
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.bottomMargin: 20
                height: 42
                spacing: 10

                Button {
                    id: clearFaultLogsButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    enabled: root.deviceModel && root.deviceModel.faultLogCount > 0
                    onClicked: clearFaultLogDialog.open()
                    background: Rectangle {
                        radius: 999
                        color: clearFaultLogsButton.enabled ? Qt.rgba(1, 0.36, 0.44, clearFaultLogsButton.down ? 0.16 : 0.08) : "#171c23"
                        border.width: 1
                        border.color: clearFaultLogsButton.enabled ? Qt.rgba(1, 0.36, 0.44, 0.34) : "#283038"
                    }
                    contentItem: Text {
                        text: root.t("清除日志", "Clear Logs")
                        color: clearFaultLogsButton.enabled ? "#ff8b8b" : "#67717f"
                        font.pixelSize: 13
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    id: closeFaultLogsButton
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 42
                    onClicked: faultLogModal.close()
                    background: Rectangle {
                        radius: 999
                        color: closeFaultLogsButton.down ? "#b78a5c" : "#c69c6e"
                    }
                    contentItem: Text {
                        text: root.t("完成", "Done")
                        color: "#17120a"
                        font.pixelSize: 13
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Dialog {
        id: clearFaultLogDialog
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        modal: true
        title: root.t("清除故障日志", "Clear Fault Logs")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (root.deviceModel) {
                root.deviceModel.clearFaultLogs()
            }
        }

        Label {
            width: Math.min(root.width * 0.76, 280)
            text: root.t("将清除本机保存的历史故障日志，不会复位设备当前故障状态。",
                         "This clears fault logs saved on this phone. It will not reset the current device fault state.")
            wrapMode: Text.WordWrap
        }
    }

    Popup {
        id: infoModal
        parent: Overlay.overlay
        width: Math.min(root.width * 0.84, 328)
        x: Math.max(0, Math.round((parent.width - width) / 2))
        y: Math.max(0, Math.round((parent.height - height) / 2))
        modal: true
        focus: true
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 24
            color: "#111620"
            border.width: 1
            border.color: Qt.rgba(0.78, 0.61, 0.43, 0.40)
        }

        Overlay.modal: Rectangle { color: "#b8000000" }

        contentItem: Column {
            padding: 20
            spacing: 14

            Text {
                id: infoTitle
                color: "#f4f1ea"
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                id: infoBody
                width: parent.width - 40
                color: "#c7d0dd"
                font.pixelSize: 13
                lineHeight: 1.25
                wrapMode: Text.WordWrap
            }
            Button {
                anchors.right: parent.right
                anchors.rightMargin: 20
                onClicked: infoModal.close()
                background: Rectangle {
                    radius: 999
                    color: parent.down ? "#b78a5c" : "#c69c6e"
                }
                contentItem: Text {
                    text: root.t("完成", "Done")
                    color: "#17120a"
                    font.pixelSize: 13
                    font.bold: true
                    leftPadding: 18
                    rightPadding: 18
                    topPadding: 9
                    bottomPadding: 9
                }
            }
        }
    }

    component Surface: Rectangle {
        radius: 22
        color: "#101318"
        border.width: 1
        border.color: "#283038"
    }

    component InfoRow: Item {
        property string label: ""
        property string value: ""
        property color valueColor: "#f4f1ea"
        property bool showDivider: true
        width: parent ? parent.width : 0
        height: 56
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: label
            color: "#9aa3b2"
            font.pixelSize: 14
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: value
            color: valueColor
            font.pixelSize: 14
            font.bold: true
            elide: Text.ElideMiddle
            width: parent.width * 0.52
            horizontalAlignment: Text.AlignRight
        }
        Rectangle {
            visible: showDivider
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: "#252b2f"
        }
    }

    component ActionRow: InfoRow {
        signal clicked()
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: "#7f8997"
            font.pixelSize: 22
        }
        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }

    component FaultLogRow: Rectangle {
        property var log
        implicitHeight: logColumn.implicitHeight + 24
        radius: 16
        color: "#151923"
        border.width: 1
        border.color: "#283038"

        Column {
            id: logColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 7

            RowLayout {
                width: parent.width
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: root.deviceModel
                          ? root.deviceModel.faultTextForCode(log && log.faultCode ? log.faultCode : "",
                                                              log && log.faultText ? log.faultText : "")
                          : root.t("未知异常，请停止使用并联系售后", "Unknown fault. Stop using the device and contact support.")
                    color: "#ff8b8b"
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    text: log && log.displayTime ? log.displayTime : "--"
                    color: "#7f8997"
                    font.pixelSize: 11
                }
            }

            Text {
                width: parent.width
                text: log && log.faultCode
                      ? root.t("故障代码：%1", "Fault code: %1").arg(log.faultCode)
                      : root.t("故障代码：未知", "Fault code: Unknown")
                color: "#f4f1ea"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: "%1 · %2".arg(log && log.deviceName ? log.deviceName : root.t("未知设备", "Unknown device"))
                                     .arg(log && log.selectedNodeName ? log.selectedNodeName : root.t("本机", "Local device"))
                color: "#9aa3b2"
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.t("电量 %1% · 电压 %2 V · 控制器 %3 °C",
                             "Battery %1% · Voltage %2 V · Controller %3 °C")
                      .arg(log && log.batteryPercent !== undefined ? Number(log.batteryPercent).toFixed(0) : "--")
                      .arg(log && log.inputVoltage !== undefined ? Number(log.inputVoltage).toFixed(1) : "--")
                      .arg(log && log.controllerTemperatureCelsius !== undefined ? Number(log.controllerTemperatureCelsius).toFixed(0) : "--")
                color: "#9aa3b2"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }
}
