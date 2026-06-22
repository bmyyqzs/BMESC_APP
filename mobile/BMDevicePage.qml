import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Item {
    id: root

    property var deviceModel
    readonly property real pageMargin: Math.max(24, Math.min(40, width * 0.065))
    readonly property bool transportConnected: deviceModel ? deviceModel.connected : false
    readonly property bool protocolReady: deviceModel ? deviceModel.protocolReady : false
    readonly property bool scanning: deviceModel ? deviceModel.scanning : false
    readonly property bool canScanning: deviceModel ? deviceModel.canScanning : false
    readonly property bool connecting: deviceModel ? deviceModel.connecting : false
    readonly property string connectionState: deviceModel ? deviceModel.connectionUiState : "disconnected"
    readonly property bool failed: connectionState === "failed"
    readonly property bool hasBleDevices: deviceModel && deviceModel.discoveredBleDevices.length > 0
    readonly property real nodeCardHeight: Math.max(92, nodeListColumn.childrenRect.height + nodeFooter.height)
    readonly property bool isEnglish: deviceModel ? deviceModel.isEnglish : false

    signal requestConnect()
    signal requestDisconnect()

    function t(zh, en) {
        return root.isEnglish ? en : zh
    }

    function startScan() {
        if (deviceModel) {
            deviceModel.clearConnectionError()
            deviceModel.startBleScan()
        }
    }

    function connectDevice(identifier) {
        if (deviceModel) {
            deviceModel.connectDevice(identifier)
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: root.width
            spacing: 18

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                Layout.topMargin: 6
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.t("查找附近设备，选择直连设备或多节点设备",
                                 "Find nearby devices, then choose a direct or multi-node device")
                    color: "#9aa3b2"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }
            }

            Surface {
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                height: 128

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text {
                                text: root.scanning ? root.t("正在搜索附近设备", "Searching nearby devices")
                                      : root.connecting ? root.t("正在连接设备", "Connecting device")
                                      : connectionState === "reading" ? root.t("正在读取设备信息", "Reading device information")
                                      : root.failed ? root.t("连接失败", "Connection failed")
                                      : root.protocolReady ? root.t("已连接设备", "Device connected")
                                      : root.hasBleDevices ? root.t("已发现附近设备", "Nearby devices found")
                                                           : root.t("暂无扫描结果", "No scan results")
                                color: "#f4f1ea"
                                font.pixelSize: 20
                                font.bold: true
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.scanning ? root.t("扫描结果会实时显示在下方列表", "Scan results will appear below")
                                      : root.connecting ? root.t("蓝牙已发起连接，请保持设备靠近手机", "Bluetooth connection started. Keep the device near your phone")
                                      : connectionState === "reading" ? root.t("蓝牙已连接，正在确认设备信息和协议状态", "Bluetooth is connected. Confirming device information and protocol status")
                                      : root.failed ? root.t("请确认设备已开机、未被其他手机占用，并靠近手机", "Make sure the device is powered on, nearby, and not in use by another phone")
                                      : root.protocolReady ? root.deviceModel.deviceName + root.t(" 已连接", " connected")
                                      : root.hasBleDevices ? root.t("选择设备后开始连接", "Select a device to connect")
                                                           : root.t("点击重新扫描开始查找附近设备", "Tap rescan to find nearby devices")
                                color: "#9aa3b2"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }

                        StatusPill {
                            text: root.protocolReady ? root.t("已连接", "Connected")
                                  : root.connecting ? root.t("连接中", "Connecting")
                                  : connectionState === "reading" ? root.t("识别中", "Reading")
                                  : root.scanning ? root.t("扫描中", "Scanning")
                                  : root.failed ? root.t("可重试", "Retry")
                                  : root.t("可连接", "Ready")
                            mode: root.protocolReady ? "good"
                                  : root.failed ? "bad"
                                  : (root.scanning || root.connecting ? "gold" : "idle")
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        enabled: !root.connecting
                        onClicked: {
                            if (root.transportConnected) {
                                root.requestDisconnect()
                            } else {
                                root.startScan()
                            }
                        }
                        background: Rectangle {
                            radius: 999
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: parent.down ? "#d2a775" : "#dfbd91" }
                                GradientStop { position: 1.0; color: parent.down ? "#b78355" : "#c69c6e" }
                            }
                        }
                        contentItem: Text {
                            text: root.transportConnected ? root.t("断开当前连接", "Disconnect Current Device")
                                  : (root.scanning ? root.t("扫描中", "Scanning") : root.t("重新扫描", "Rescan"))
                            color: "#17120a"
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            SectionTitle {
                visible: !root.transportConnected
                text: root.t("BLE 设备", "BLE Devices")
            }

            Surface {
                visible: !root.transportConnected
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                height: Math.max(92, bleColumn.childrenRect.height)
                clip: true

                Column {
                    id: bleColumn
                    width: parent.width

                    EmptyRow {
                        visible: !root.hasBleDevices
                        title: root.scanning ? root.t("正在扫描", "Scanning") : root.t("暂无设备", "No devices")
                        subtitle: root.scanning ? root.t("请保持设备开机并靠近手机", "Keep the device powered on and near your phone")
                                                : root.t("点击重新扫描开始查找附近设备", "Tap rescan to find nearby devices")
                    }

                    Repeater {
                        model: root.deviceModel ? root.deviceModel.discoveredBleDevices : []

                        DeviceRow {
                            readonly property bool connectingThisDevice: root.connecting &&
                                                                         root.deviceModel.connectingIdentifier === modelData.identifier
                            name: modelData.name
                            subtitle: modelData.subtitle ? modelData.subtitle : root.t("BLE 设备 · 点击连接", "BLE device · Tap to connect")
                            actionText: connectingThisDevice ? root.t("连接中 %1s", "Connecting %1s").arg(root.deviceModel.connectCountdownSeconds)
                                        : (modelData.connected ? root.t("已连接", "Connected") : root.t("连接", "Connect"))
                            actionMode: modelData.connected ? "good" : (root.failed ? "bad" : "gold")
                            interactive: !root.connecting || connectingThisDevice
                            onClicked: root.connectDevice(modelData.identifier)
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                height: nodeContent.height
                Layout.preferredHeight: height
                visible: root.protocolReady

                ColumnLayout {
                    id: nodeContent
                    width: parent.width
                    height: childrenRect.height
                    spacing: 12

                    SectionTitle {
                        Layout.leftMargin: 0
                        Layout.rightMargin: 0
                        text: root.t("设备节点", "Device Nodes")
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.t("多节点设备已连接，请选择一个节点，首页会显示该节点实时数据",
                                     "A multi-node device is connected. Select a node to show its live data on Home")
                        color: "#9aa3b2"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.t("切换节点前会停止当前遥测，避免显示旧数据。",
                                     "Telemetry pauses while switching nodes to avoid showing stale data.")
                        color: "#9aa3b2"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Surface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.nodeCardHeight
                        height: root.nodeCardHeight
                        clip: true

                        Column {
                            anchors.fill: parent

                            Column {
                                id: nodeListColumn
                                width: parent.width
                                height: childrenRect.height

                                EmptyRow {
                                    visible: !root.deviceModel || root.deviceModel.canNodes.length === 0
                                    title: root.t("暂无节点", "No nodes")
                                    subtitle: root.t("点击重新扫描节点", "Tap to rescan nodes")
                                }

                                Repeater {
                                    model: root.deviceModel ? root.deviceModel.canNodes : []

                                    NodeRow {
                                        nodeId: modelData.displayId
                                        name: modelData.name
                                        firmware: modelData.firmware
                                        stateText: modelData.state
                                        selected: modelData.selected
                                        interactive: modelData.enabled
                                        onClicked: root.deviceModel.selectCanNode(modelData.id)
                                    }
                                }
                            }

                            Item {
                                id: nodeFooter
                                width: parent.width
                                height: 72

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    height: 1
                                    color: "#252b2f"
                                }

                                Button {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 18
                                    anchors.rightMargin: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 42
                                    enabled: !root.canScanning
                                    onClicked: root.deviceModel.scanCanNodes()
                                    background: Rectangle {
                                        radius: 16
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: parent.down ? "#d2a775" : "#dfbd91" }
                                            GradientStop { position: 1.0; color: parent.down ? "#b78355" : "#c69c6e" }
                                        }
                                    }
                                    contentItem: Text {
                                        text: root.canScanning ? root.t("扫描中", "Scanning") : root.t("重新扫描节点", "Rescan Nodes")
                                        color: "#17120a"
                                        font.pixelSize: 15
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
            }
        }
    }

    component SectionTitle: Text {
        Layout.fillWidth: true
        Layout.leftMargin: root.pageMargin
        Layout.rightMargin: root.pageMargin
        text: ""
        color: "#f4f1ea"
        font.pixelSize: 14
        font.bold: true
    }

    component Surface: Rectangle {
        radius: 22
        color: "#101318"
        border.width: 1
        border.color: "#283038"
    }

    component StatusPill: Rectangle {
        property string text: ""
        property string mode: "idle"
        implicitWidth: label.implicitWidth + 22
        implicitHeight: 30
        radius: 999
        color: mode === "good" ? "#162a24"
              : mode === "bad" ? "#321921"
              : mode === "gold" ? "#2c2418" : "#15191e"
        border.width: 1
        border.color: mode === "good" ? "#3f705f"
                    : mode === "bad" ? "#7a3442"
                    : mode === "gold" ? "#8d704f" : "#343b42"
        Text {
            id: label
            anchors.centerIn: parent
            text: parent.text
            color: parent.mode === "good" ? "#64d6b0"
                  : parent.mode === "bad" ? "#ff8b8b"
                  : parent.mode === "gold" ? "#dfbd91" : "#9aa3b2"
            font.pixelSize: 12
            font.bold: true
        }
    }

    component EmptyRow: Item {
        property string title: ""
        property string subtitle: ""
        width: parent ? parent.width : 0
        height: 76
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            Text { text: title; color: "#f4f1ea"; font.pixelSize: 16; font.bold: true }
            Text { text: subtitle; color: "#9aa3b2"; font.pixelSize: 12 }
        }
    }

    component DeviceRow: Item {
        property string name: ""
        property string subtitle: ""
        property string actionText: ""
        property string actionMode: "gold"
        property bool interactive: true
        signal clicked()
        width: parent ? parent.width : 0
        height: 78
        opacity: interactive ? 1.0 : 0.72

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: action.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            Text { width: parent.width; text: name; color: "#f4f1ea"; font.pixelSize: 16; font.bold: true; elide: Text.ElideRight }
            Text { width: parent.width; text: subtitle; color: "#9aa3b2"; font.pixelSize: 12; elide: Text.ElideRight }
        }

        Text {
            id: action
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: actionText + " ›"
            color: actionMode === "good" ? "#64d6b0" : actionMode === "bad" ? "#ff8b8b" : "#dfbd91"
            font.pixelSize: 14
            font.bold: true
        }

        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: "#252b2f" }
        MouseArea { anchors.fill: parent; enabled: parent.interactive; onClicked: parent.clicked() }
    }

    component NodeRow: Item {
        property string nodeId: ""
        property string name: ""
        property string firmware: ""
        property string stateText: ""
        property bool selected: false
        property bool interactive: true
        signal clicked()
        width: parent ? parent.width : 0
        height: 96
        opacity: interactive ? 1.0 : 0.46

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            radius: 18
            color: selected ? "#173548" : (interactive ? "transparent" : "#11151a")
            border.width: selected ? 1 : 0
            border.color: "#2f9ac3"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14

            ColumnLayout {
                Layout.preferredWidth: 60
                spacing: 4
                Text { text: root.t("节点", "Node"); color: "#9aa3b2"; font.pixelSize: 11 }
                Text { text: nodeId; color: !interactive ? "#67717f" : (selected ? "#8ddfff" : "#dfbd91"); font.pixelSize: 22; font.bold: true }
                Text { visible: selected; text: root.t("已选择", "Selected"); color: "#64d6b0"; font.pixelSize: 11 }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text { Layout.fillWidth: true; text: name; color: !interactive ? "#7a8491" : (selected ? "#ffffff" : "#f4f1ea"); font.pixelSize: 15; font.bold: true; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: root.t("固件版本 ", "Firmware ") + firmware; color: !interactive ? "#67717f" : (selected ? "#b7d7e3" : "#9aa3b2"); font.pixelSize: 12; elide: Text.ElideRight }
            }

            Text {
                text: stateText
                color: interactive ? "#64d6b0" : "#67717f"
                font.pixelSize: 13
                font.bold: true
            }
        }

        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: selected ? "transparent" : "#252b2f" }
        MouseArea { anchors.fill: parent; enabled: parent.interactive; onClicked: parent.clicked() }
    }
}
