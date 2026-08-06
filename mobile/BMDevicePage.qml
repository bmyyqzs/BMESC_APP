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
    readonly property bool telemetryValid: deviceModel ? deviceModel.telemetryValid : false
    readonly property bool hasFault: deviceModel ? deviceModel.hasFault : false
    readonly property string faultText: deviceModel && deviceModel.faultText.length > 0
                                        ? deviceModel.faultText : root.t("正常", "Normal")
    readonly property string uuidText: formatUuidHex(deviceModel ? deviceModel.deviceIdentifier : "")
    readonly property int hallCheckState: deviceModel ? deviceModel.hallCheckState : 0
    property bool hallCardRevealed: false
    property int hiddenTapCount: 0
    property double lastHiddenTapMs: 0

    signal requestConnect()
    signal requestDisconnect()

    function t(zh, en) {
        return root.isEnglish ? en : zh
    }

    function formatUuidHex(identifier) {
        if (!identifier || identifier.length === 0) {
            return "--"
        }

        var hex = identifier.replace(/[^0-9a-fA-F]/g, "").toUpperCase()
        return hex.length > 0 ? hex : identifier.toUpperCase()
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

    function registerHiddenTap() {
        var now = Date.now()
        hiddenTapCount = (now - lastHiddenTapMs <= 1200) ? hiddenTapCount + 1 : 1
        lastHiddenTapMs = now

        if (hiddenTapCount >= 5) {
            hallCardRevealed = true
            hiddenTapCount = 0
        }
    }

    ScrollView {
        id: deviceScrollView
        anchors.fill: parent
        contentWidth: availableWidth
        contentHeight: pageContent.implicitHeight
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: pageContent
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
                        transformOrigin: Item.Center
                        scale: enabled && down ? 0.96 : 1.0
                        opacity: enabled ? (down ? 0.92 : 1.0) : 0.72
                        onClicked: {
                            if (root.transportConnected) {
                                root.requestDisconnect()
                            } else {
                                root.startScan()
                            }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
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
                                    transformOrigin: Item.Center
                                    scale: enabled && down ? 0.96 : 1.0
                                    opacity: enabled ? (down ? 0.92 : 1.0) : 0.72
                                    onClicked: root.deviceModel.scanCanNodes()
                                    Behavior on scale {
                                        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                                    }
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

            Surface {
                visible: root.hallCardRevealed && root.deviceModel && root.deviceModel.refloatAvailable
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                Layout.preferredHeight: height
                height: visible ? refloatDashboard.implicitHeight + 34 : 0

                RefloatDashboard {
                    id: refloatDashboard
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                }
            }

            Surface {
                visible: root.hallCardRevealed
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                Layout.preferredHeight: height
                height: hallColumn.implicitHeight + 34

                Column {
                    id: hallColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 14

                    RowLayout {
                        width: parent.width
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: root.t("霍尔检测", "Hall Sensor Check")
                                color: "#f4f1ea"
                                font.pixelSize: 18
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.t("检测电机霍尔传感器是否正常", "Check if the motor hall sensors work")
                                color: "#9aa3b2"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }

                        StatusPill {
                            text: root.hallCheckState === 1
                                  ? root.t("检测中", "Checking")
                                  : (root.hallCheckState === 2
                                     ? root.t("正常", "OK")
                                     : (root.hallCheckState === 3
                                        ? root.t("错误", "Error")
                                        : root.t("未检测", "Unchecked")))
                            mode: root.hallCheckState === 2 ? "good"
                                  : root.hallCheckState === 3 ? "bad"
                                  : root.hallCheckState === 1 ? "gold" : "idle"
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#283038"
                    }

                    Text {
                        width: parent.width
                        text: root.hallCheckState === 1
                              ? root.t("正在检测，请保持轮子悬空...", "Checking, keep the wheel off the ground...")
                              : (root.hallCheckState === 2
                                 ? root.t("霍尔正常", "Hall sensors OK")
                                 : (root.hallCheckState === 3
                                    ? root.t("霍尔错误", "Hall sensor error")
                                    : root.t("检测时轮子会转动，请先确认轮子已悬空",
                                             "The wheel will spin during the check. Lift it off the ground first")))
                        color: root.hallCheckState === 1
                               ? "#f2d58a"
                               : (root.hallCheckState === 2
                                  ? "#64d6b0"
                                  : (root.hallCheckState === 3 ? "#ff8b8b" : "#9aa3b2"))
                        font.pixelSize: 13
                        font.bold: root.hallCheckState !== 0
                        wrapMode: Text.WordWrap
                    }

                    Button {
                        width: parent.width
                        height: 48
                        enabled: root.protocolReady && root.hallCheckState !== 1
                        transformOrigin: Item.Center
                        scale: enabled && down ? 0.96 : 1.0
                        opacity: enabled ? (down ? 0.92 : 1.0) : 0.72
                        onClicked: hallConfirmDialog.open()

                        Behavior on scale {
                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                        }

                        background: Rectangle {
                            radius: 14
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: parent.enabled ? "#dfbd91" : "#2a3034" }
                                GradientStop { position: 1.0; color: parent.enabled ? "#c69c6e" : "#20262c" }
                            }
                        }

                        contentItem: Text {
                            text: root.hallCheckState === 1
                                  ? root.t("检测中...", "Checking...")
                                  : root.t("开始检测", "Start Check")
                            color: parent.enabled ? "#17120a" : "#656b6f"
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Surface {
                visible: root.hallCardRevealed
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                Layout.preferredHeight: height
                height: terminalColumn.implicitHeight + 34

                Column {
                    id: terminalColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 14

                    RowLayout {
                        width: parent.width
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: root.t("终端", "Terminal")
                                color: "#f4f1ea"
                                font.pixelSize: 18
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.t("打印设备诊断信息，并在下方显示返回内容",
                                             "Print device diagnostics and show the output below")
                                color: "#9aa3b2"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }

                        StatusPill {
                            text: root.protocolReady ? root.t("可用", "Ready") : root.t("未连接", "Offline")
                            mode: root.protocolReady ? "good" : "idle"
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#283038"
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 10

                        TerminalButton {
                            Layout.fillWidth: true
                            text: root.t("故障代码", "Print Faults")
                            enabled: root.protocolReady && root.deviceModel
                            onClicked: root.deviceModel.printFaults()
                        }

                        TerminalButton {
                            Layout.fillWidth: true
                            text: root.t("打印线程", "Print Threads")
                            enabled: root.protocolReady && root.deviceModel
                            onClicked: root.deviceModel.printThreads()
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: Math.max(86, (terminalOutputText.visible
                                              ? terminalOutputText.paintedHeight
                                              : terminalHintText.paintedHeight) + 24)
                        radius: 12
                        color: "#0d1117"
                        border.width: 1
                        border.color: "#283038"

                        Text {
                            id: terminalHintText
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 12
                            width: parent.width - 24
                            visible: !terminalOutputText.visible
                            text: root.deviceModel && root.deviceModel.terminalStatusText.length > 0
                                  ? root.deviceModel.terminalStatusText
                                  : (root.protocolReady
                                     ? root.t("点击故障代码或打印线程后显示返回信息。",
                                              "Tap Print Faults or Print Threads to show output.")
                                     : root.t("连接设备后可打印诊断信息。",
                                              "Connect to a device to print diagnostics."))
                            color: "#9aa3b2"
                            font.pixelSize: 12
                            font.letterSpacing: 0
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            id: terminalOutputText
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 12
                            width: parent.width - 24
                            visible: root.deviceModel && root.deviceModel.terminalOutput.length > 0
                            text: visible ? root.deviceModel.terminalOutput : ""
                            color: "#f4f1ea"
                            font.pixelSize: 12
                            font.letterSpacing: 0
                            wrapMode: Text.WordWrap
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 10

                        TerminalButton {
                            Layout.fillWidth: true
                            text: root.t("复制", "Copy")
                            enabled: root.deviceModel && root.deviceModel.terminalOutput.length > 0
                            onClicked: {
                                root.deviceModel.copyTerminalOutput()
                                copySuccessPopup.open()
                                copySuccessTimer.restart()
                            }
                        }

                        TerminalButton {
                            Layout.fillWidth: true
                            text: root.t("清除", "Clear")
                            enabled: root.deviceModel && (root.deviceModel.terminalOutput.length > 0 ||
                                                          root.deviceModel.terminalStatusText.length > 0)
                            onClicked: root.deviceModel.clearTerminalOutput()
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

    MouseArea {
        anchors.fill: parent
        z: 10
        enabled: !root.hallCardRevealed
        acceptedButtons: Qt.LeftButton
        preventStealing: false
        propagateComposedEvents: true

        onPressed: {
            root.registerHiddenTap()
            mouse.accepted = false
        }
        onReleased: mouse.accepted = false
    }

    Dialog {
        id: hallConfirmDialog
        modal: true
        width: Math.min(root.width - 48, 340)
        x: (root.width - width) / 2
        y: Math.max(0, (root.height - implicitHeight) / 2)
        padding: 20

        background: Rectangle {
            radius: 18
            color: "#151923"
            border.width: 1
            border.color: "#283038"
        }

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        contentItem: Column {
            spacing: 14

            Text {
                width: parent.width
                text: root.t("霍尔检测", "Hall Sensor Check")
                color: "#f4f1ea"
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                width: parent.width
                text: root.t("检测过程中轮子会转动，请确保轮子已悬空并远离障碍物。点击确认后开始检测。",
                             "The wheel will spin during the check. Make sure the wheel is off the ground and clear of obstacles before confirming.")
                color: "#9aa3b2"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            RowLayout {
                width: parent.width
                spacing: 10

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    transformOrigin: Item.Center
                    scale: enabled && down ? 0.96 : 1.0
                    opacity: enabled ? (down ? 0.92 : 1.0) : 0.72
                    onClicked: hallConfirmDialog.close()

                    Behavior on scale {
                        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                    }

                    background: Rectangle {
                        radius: 12
                        color: "#202832"
                        border.width: 1
                        border.color: "#343b42"
                    }

                    contentItem: Text {
                        text: root.t("取消", "Cancel")
                        color: "#f4f1ea"
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    transformOrigin: Item.Center
                    scale: enabled && down ? 0.96 : 1.0
                    opacity: enabled ? (down ? 0.92 : 1.0) : 0.72
                    onClicked: {
                        hallConfirmDialog.close()
                        if (root.deviceModel) {
                            root.deviceModel.startHallCheck()
                        }
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                    }

                    background: Rectangle {
                        radius: 12
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#dfbd91" }
                            GradientStop { position: 1.0; color: "#c69c6e" }
                        }
                    }

                    contentItem: Text {
                        text: root.t("确认开始", "Confirm & Start")
                        color: "#17120a"
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Popup {
        id: copySuccessPopup
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        padding: 0
        width: Math.min(root.width - 72, copySuccessText.implicitWidth + 44)
        height: 48
        x: (root.width - width) / 2
        y: Math.max(24, root.height - height - 76)

        background: Rectangle {
            radius: 14
            color: "#202832"
            border.width: 1
            border.color: "#3a4652"
        }

        contentItem: Text {
            id: copySuccessText
            text: root.t("复制成功", "Copied")
            color: "#f4f1ea"
            font.pixelSize: 14
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Timer {
        id: copySuccessTimer
        interval: 1500
        repeat: false
        onTriggered: copySuccessPopup.close()
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

    component RefloatDashboard: Item {
        implicitHeight: refloatColumn.implicitHeight

        ColumnLayout {
            id: refloatColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: "Refloat"
                        color: "#f4f1ea"
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "UUID: " + root.uuidText
                        color: "#9aa3b2"
                        font.pixelSize: 10
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 2
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 112
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: root.telemetryValid ? root.deviceModel.inputVoltage.toFixed(1) + " V" : "--"
                        color: "#f4f1ea"
                        font.pixelSize: 17
                        font.bold: true
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.hasFault ? root.faultText
                              : (root.deviceModel ? root.deviceModel.refloatStatusText : "--")
                        color: root.hasFault ? "#ff8b8b"
                              : (root.deviceModel && (root.deviceModel.refloatStatusText === "RUNNING" || root.deviceModel.refloatStatusText === "READY") ? "#64d6b0" : "#9aa3b2")
                        font.pixelSize: root.hasFault ? 11 : 12
                        font.bold: true
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#283038"
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "ERPM"
                    value: root.telemetryValid ? Math.round(Math.abs(root.deviceModel.rpm)).toString() : "--"
                }
                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "Motor Current"
                    value: root.telemetryValid ? root.deviceModel.motorCurrentAmps.toFixed(1) + " A" : "--"
                }
                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "Duty"
                    value: root.telemetryValid ? root.deviceModel.dutyPercent.toFixed(1) + "%" : "--"
                }
                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "Battery Current"
                    value: root.telemetryValid ? root.deviceModel.inputCurrentAmps.toFixed(1) + " A" : "--"
                }
                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "Left Footpad"
                    value: root.deviceModel ? root.deviceModel.refloatFootpadLeftVoltage.toFixed(2) + " V" : "--"
                }
                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "Right Footpad"
                    value: root.deviceModel ? root.deviceModel.refloatFootpadRightVoltage.toFixed(2) + " V" : "--"
                }
                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "Motor Temp"
                    value: root.telemetryValid ? root.deviceModel.motorTemperatureCelsius.toFixed(1) + "°C" : "--"
                }
                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "Controller Temp"
                    value: root.telemetryValid ? root.deviceModel.controllerTemperatureCelsius.toFixed(1) + "°C" : "--"
                }
                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "Roll"
                    value: root.deviceModel && root.deviceModel.imuValid ? root.deviceModel.rollDegrees.toFixed(1) + "°" : "--"
                }
                RefloatDataCell {
                    Layout.fillWidth: true
                    label: "Pitch"
                    value: root.deviceModel && root.deviceModel.imuValid ? root.deviceModel.pitchDegrees.toFixed(1) + "°" : "--"
                }
            }
        }
    }

    component RefloatDataCell: Rectangle {
        property string label: ""
        property string value: "--"

        Layout.preferredHeight: 58
        radius: 8
        color: Qt.rgba(255, 255, 255, 0.035)
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.075)

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.top: parent.top
            anchors.topMargin: 9
            text: parent.value
            color: "#f4f1ea"
            font.pixelSize: 16
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            text: parent.label
            color: "#9aa3b2"
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    component TerminalButton: Button {
        height: 48
        transformOrigin: Item.Center
        scale: enabled && down ? 0.96 : 1.0
        opacity: enabled ? (down ? 0.92 : 1.0) : 0.72

        Behavior on scale {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }

        background: Rectangle {
            radius: 14
            gradient: Gradient {
                GradientStop { position: 0.0; color: parent.enabled ? "#dfbd91" : "#2a3034" }
                GradientStop { position: 1.0; color: parent.enabled ? "#c69c6e" : "#20262c" }
            }
        }

        contentItem: Text {
            text: parent.text
            color: parent.enabled ? "#17120a" : "#656b6f"
            font.pixelSize: 14
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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
        height: 92
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
