import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Item {
    id: root

    property var deviceModel
    property bool langEn: false
    readonly property real pageMargin: Math.max(24, Math.min(40, width * 0.065))
    readonly property bool connected: deviceModel ? deviceModel.connected : false
    signal langToggled()

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
                        label: qsTr("语言")
                        value: root.langEn ? "English" : qsTr("简体中文")
                        onClicked: root.langToggled()
                    }
                    ActionRow {
                        label: qsTr("单位")
                        value: root.deviceModel && root.deviceModel.useImperialUnits ? "mph" : "km/h"
                        onClicked: if (root.deviceModel) root.deviceModel.useImperialUnits = !root.deviceModel.useImperialUnits
                    }
                    ActionRow {
                        label: qsTr("故障日志")
                        value: root.deviceModel && root.deviceModel.faultLogCount > 0
                               ? qsTr("%1 条").arg(root.deviceModel.faultLogCount)
                               : qsTr("无记录")
                        onClicked: root.showFaultLogs()
                    }
                    ActionRow {
                        label: qsTr("支持与反馈")
                        value: qsTr("查看")
                        onClicked: root.showInfo(qsTr("支持与反馈"),
                                                 qsTr("如遇到连接失败、数据异常或设备安全提示，请记录设备名称、节点 ID 和发生时间，并发邮件到 op727142092@gmail.com。"))
                    }
                    ActionRow {
                        label: qsTr("隐私政策")
                        value: qsTr("查看")
                        onClicked: root.showInfo(qsTr("隐私政策"),
                                                 qsTr("蓝牙权限仅用于发现和连接附近 BM 设备。遥测数据用于本地状态显示，不用于账号或云端绑定。"))
                    }
                    ActionRow {
                        label: qsTr("用户协议")
                        value: qsTr("查看")
                        onClicked: root.showInfo(qsTr("用户协议"),
                                                 qsTr("请在安全环境中使用设备。App 展示的数据用于辅助判断设备状态，不替代设备本身的安全检查。"))
                    }
                    ActionRow {
                        label: qsTr("关于 BM")
                        value: qsTr("查看")
                        showDivider: false
                        onClicked: root.showInfo(qsTr("关于 BM"),
                                                 qsTr("BM 首版聚焦连接、遥测、设备信息、安全提示和合规入口。"))
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

        contentItem: ColumnLayout {
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("故障日志")
                        color: "#f4f1ea"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.deviceModel && root.deviceModel.faultLogCount > 0
                              ? qsTr("最近 %1 条本地记录").arg(root.deviceModel.faultLogCount)
                              : qsTr("暂无历史故障")
                        color: "#9aa3b2"
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                height: 1
                color: "#283038"
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                Text {
                    anchors.centerIn: parent
                    visible: !root.deviceModel || root.deviceModel.faultLogCount === 0
                    width: parent.width
                    text: qsTr("设备出现故障提示时，App 会自动保存时间、设备和关键状态。")
                    color: "#9aa3b2"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                ScrollView {
                    anchors.fill: parent
                    visible: root.deviceModel && root.deviceModel.faultLogCount > 0
                    contentWidth: availableWidth
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Column {
                        width: parent.width
                        spacing: 10

                        Repeater {
                            model: root.deviceModel ? root.deviceModel.faultLogs : []

                            FaultLogRow {
                                width: parent.width
                                log: modelData
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 20
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
                        text: qsTr("清除日志")
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
                        text: qsTr("完成")
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
        title: qsTr("清除故障日志")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (root.deviceModel) {
                root.deviceModel.clearFaultLogs()
            }
        }

        Label {
            width: Math.min(root.width * 0.76, 280)
            text: qsTr("将清除本机保存的历史故障日志，不会复位设备当前故障状态。")
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
                    text: qsTr("完成")
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
                    text: log && log.faultText ? log.faultText : qsTr("未知异常，请停止使用并联系售后")
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
                      ? qsTr("故障代码：%1").arg(log.faultCode)
                      : qsTr("故障代码：未知")
                color: "#f4f1ea"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: qsTr("%1 · %2").arg(log && log.deviceName ? log.deviceName : qsTr("未知设备"))
                                     .arg(log && log.selectedNodeName ? log.selectedNodeName : qsTr("本机"))
                color: "#9aa3b2"
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: qsTr("电量 %1% · 电压 %2 V · 控制器 %3 °C")
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
