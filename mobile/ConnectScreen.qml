/*
    Copyright 2021 Benjamin Vedder	benjamin@vedder.se

    This file is part of VESC Tool.

    VESC Tool is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VESC Tool is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.bleuart 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.utility 1.0
import Vedder.vesc.udpserversimple 1.0

Item {
    id: rootItem
    property int animationDuration: 500
    property var mBle: VescIf.bleDeviceObject()
    property Commands mCommands: VescIf.commands()
    property bool opened: true
    property bool pingTcpHub: false
    property bool scanning: false
    property bool pullToRefreshArmed: false
    property bool fullLogo: true
    property bool allowHide: true
    property bool autoStartScan: true
    property bool connectionAttemptActive: false
    property string connectingAddress: ""
    property string connectingName: ""

    onOpenedChanged: {
        if(opened){
            animationDuration = 500
            y = 0
            if (autoStartScan) {
                autoStartScanTimer.restart()
            }
        } else {
            y = Qt.binding(function() {return parent.height})
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: animationDuration
            easing.type: Easing.InOutSine
        }
    }

    Rectangle {
        color: Utility.getAppHexColor("darkBackground")
        anchors.fill: parent
    }

    // Prevents events from passing to components behind
    MouseArea {
        anchors.fill: parent
        enabled: rootItem.allowHide
        acceptedButtons: Qt.AllButtons
        onWheel: {wheel.accepted=true}
        hoverEnabled: true
    }

    function startBleScan() {
        if (scanning) {
            return
        }

        if (Utility.hasLocationPermission()) {
            scanning = true
            scanDotTimer.running = true
            bleModel.clear()
            vescsUdp = []
            mBle.startScan()
        } else {
            bleScanStart.open()
        }
    }

    function pullToRefreshLabel() {
        if (scanning) {
            return "Scanning..."
        }

        if (pullToRefreshArmed) {
            return "Release to rescan"
        }

        return "Pull down to rescan"
    }

    function beginBleConnection(address, deviceName) {
        if (connectionAttemptActive) {
            return
        }

        if (!address || address.length === 0) {
            VescIf.emitMessageDialog(qsTr("Connect"),
                                     qsTr("This Bluetooth device has no valid identifier."),
                                     false, false)
            return
        }

        connectionAttemptActive = true
        connectingAddress = address
        connectingName = deviceName ? deviceName.split("\n")[0] : qsTr("Bluetooth device")
        console.log("[BLE UI] Connect requested:", connectingName, connectingAddress)
        disableDialog()
        workaroundTimerConnect.bleAddr = address
        workaroundTimerConnect.start()
    }

    function finishConnectionAttempt() {
        connectionAttemptActive = false
        connectingAddress = ""
        connectingName = ""
        enableDialog()
    }

    onYChanged: {
        if (y > 1) {
            enableDialog()
        }
        if(!opened & y == height){
            animationDuration = 0
        }
    }

    Timer {
        id: autoStartScanTimer
        interval: 350
        repeat: false
        running: false
        onTriggered: {
            if (rootItem.autoStartScan && rootItem.visible && rootItem.opened) {
                startBleScan()
            }
        }
    }

    Timer {
        id: workaroundTimerConnect
        property string bleAddr: ""
        interval: 1
        repeat: false
        running: false
        onTriggered: {
            console.log("[BLE UI] Starting BLE connection:", workaroundTimerConnect.bleAddr)
            VescIf.connectBle(workaroundTimerConnect.bleAddr)
        }
    }

    Component.onCompleted: {
        if (autoStartScan) {
            autoStartScanTimer.start()
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 10
        anchors.topMargin: 0
        anchors.leftMargin: notchLeft
        anchors.rightMargin: notchRight
        spacing: 0

        Rectangle {
            Layout.preferredHeight: 0
            Layout.fillWidth: true
            opacity: 0
        }

        Image {
            id: image
            visible: false
            Layout.preferredWidth: visible ? Math.min(column.width, column.height*0.8) * 0.8 : 0
            Layout.preferredHeight: visible ? (sourceSize.height * Layout.preferredWidth) / sourceSize.width : 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.topMargin: 0
            Layout.bottomMargin: 0
            source: fullLogo
                    ? "qrc" + Utility.getThemePath() + "/logo.png"
                    : "qrc" + Utility.getThemePath() + "/symbol_v_wide.png"
            DragHandler {
                id: handler
                target: rootItem
                enabled: rootItem.allowHide
                margin: 0
                xAxis.enabled: false
                yAxis.maximum: rootItem.height
                yAxis.minimum: 0

                onActiveChanged: {
                    if (handler.active) {
                        animationDuration = 3
                    } else {
                        animationDuration = 500
                        if(opened) {
                            if (rootItem.y > (rootItem.height / 4)) {
                                rootItem.opened = false
                            } else {
                                rootItem.y = 0
                            }
                        }
                    }
                }
            }
        }

        Timer {
            id: scanDotTimer
            interval: 500
            running: false
            repeat: true

            property int dots: 0
            onTriggered: {
                dots++;
                if (dots > 3) {
                    dots = 0;
                }
            }
        }

        ListModel {
            id: bleModel
        }

        ListView {
            id: bleList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 0
            focus: true
            clip: true
            spacing: 5
            z:2
            boundsBehavior: Flickable.DragOverBounds

            header: Item {
                width: bleList.width
                height: scanning ? 56 : Math.max(0, Math.min(-bleList.contentY, 56))
                visible: height > 0
                clip: true

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    BusyIndicator {
                        running: scanning
                        visible: scanning
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                    }

                    Text {
                        color: Utility.getAppHexColor("lightText")
                        text: pullToRefreshLabel()
                        visible: scanning || parent.parent.height > 18
                    }
                }
            }

            onContentYChanged: {
                if (contentY < -60 && !scanning) {
                    pullToRefreshArmed = true
                } else if (contentY > -20 && !scanning) {
                    pullToRefreshArmed = false
                }
            }

            onDraggingChanged: {
                if (!dragging && pullToRefreshArmed && !scanning) {
                    startBleScan()
                    pullToRefreshArmed = false
                }
            }

            onMovementEnded: {
                pullToRefreshArmed = false
            }

            Component {
                id: bleDelegate

                Rectangle {
                    width: bleList.width
                    height: 120
                    color: Utility.getAppHexColor("normalBackground")
                    radius: 10

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Rectangle {
                            Layout.leftMargin: 10
                            Layout.fillWidth: true
                            opacity: 1.0
                            color: preferred ? (Utility.getAppHexColor("vescGreenMedium")) : (Utility.getAppHexColor("vescGreenDark") )
                            height: column.height + 10
                            radius: height / 2

                            ColumnLayout {
                                id: column
                                anchors.centerIn: parent
                                Image {
                                    id: image
                                    fillMode: Image.PreserveAspectFit
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    source: "qrc" + Utility.getThemePath() +  ({
                                       0: "icons/bluetooth.png",
                                       1: "icons/USB-96.png",
                                       2: "icons/LAN-96.png",
                                       3: "icons/Globe-96.png"
                                   }[connectionType]) 
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    text: name
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Utility.getAppHexColor("lightText")
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        ColumnLayout {
                            visible: connectionType === 0

                            Text {
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                                Layout.rightMargin: 5
                                color: Utility.getAppHexColor("lightText")
                                text: "Preferred"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Switch {
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                                enabled: true
                                checked: preferred
                                onToggled: {
                                    VescIf.storeBlePreferred(bleAddr, checked)
                                    bleModel.clear()
                                    mBle.emitScanDone()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.rightMargin: 10
                            spacing: -5

                            Button {
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                                Layout.preferredHeight: 55
                                Layout.preferredWidth: {
                                    if (connectionType === 0) {
                                        nameButton.width
                                    } else if (connectionType === 3) {
                                        passButton.width
                                    } else {
                                        nameButton.width
                                    }
                                }

                                enabled: !rootItem.connectionAttemptActive
                                text: rootItem.connectionAttemptActive &&
                                      rootItem.connectingAddress === bleAddr
                                      ? qsTr("Connecting...")
                                      : qsTr("Connect")

                                onClicked: {
                                    console.log("[Connect UI] Connect button clicked:", connectionType, bleAddr)
                                    if (connectionType === 1) {
                                        if (bleAddr === "") {
                                            VescIf.autoconnect()
                                        } else {
                                            VescIf.connectSerial(bleAddr, 115200)
                                        }
                                    } else if (connectionType === 2) {
                                        VescIf.connectTcp(bleAddr, tcpPort)
                                    } else if (connectionType === 3) {
                                        VescIf.connectTcpHubUuid(hubUuid)
                                    } else {
                                        rootItem.beginBleConnection(bleAddr, name)
                                    }
                                }
                            }

                            Button {
                                id: passButton
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                                Layout.preferredHeight: 55
                                text: "Update Password"
                                visible: connectionType === 3

                                onClicked: {
                                    hubPassDialog.uuid = hubUuid
                                    hubPassDialog.open()
                                }
                            }

                            Button {
                                id: nameButton
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                                Layout.preferredHeight: 55
                                text: "Set Name"
                                visible: connectionType === 0

                                onClicked: {
                                    bleNameDialog.addr = bleAddr
                                    stringInput.text = setName
                                    bleNameDialog.open()
                                }
                            }
                        }
                    }
                }
            }

            model: bleModel
            delegate: bleDelegate
        }
    }

    property var vescsUdp: []

    UdpServerSimple {
        Component.onCompleted: {
            startServerBroadcast(65109)
        }

        onDataRx: {
            var tokens = Utility.arr2str(data).split("::")
            if (tokens.length === 3) {
                var found = false
                
                for (var i = 0; i < vescsUdp.length;i++) {
                    if (vescsUdp[i].ip === tokens[1]) {
                        vescsUdp[i].updateTime = new Date().getTime()
                        found = true
                        break
                    }
                }

                if (!found) {
                    vescsUdp[vescsUdp.length] = {
                        "name" : tokens[0],
                        "ip" : tokens[1],
                        "port" : parseInt(tokens[2]),
                        "updateTime" : new Date().getTime()
                    }
                    mBle.emitScanDone()
                }
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 500

        onTriggered: {
            var removed = false
            for (var i = 0; i < vescsUdp.length;i++) {
                var age = new Date().getTime() - vescsUdp[i].updateTime
                if (age > 5000) {
                    vescsUdp.splice(i, 1)
                    removed = true
                    i--;
                    if (i < 0) {
                        break
                    }
                }
            }

            if (removed) {
                bleModel.clear()
                mBle.emitScanDone()
            }

            // Re-scan serial regularly
            if (Utility.hasSerialport()) {
                mBle.emitScanDone()
            }
        }
    }

    Connections {
        target: mBle
        function formatBleDevice(name, addr){
            var shortAddr = addr
            if(Qt.platform.os == "ios" || Qt.platform.os == "mac") {
                var ids = addr.split('-')
                shortAddr = 
                    ids[0].slice(1,3) + '-' +
                    ids[1].slice(0,2) + '-' +
                    ids[2].slice(0,2) + '-' +
                    ids[3].slice(0,2) + '-' + 
                    ids[4].slice(0,2)
            }
            
            var bleName = VescIf.getBleName(addr)
            var displayName
            if (bleName.length > 0) {
                displayName = bleName
            } else {
                displayName = name
            }
            displayName += "\n[" + shortAddr + "]"
            
            return {
                "name": displayName,
                "setName": bleName,
                "preferred": VescIf.getBlePreferred(addr),
                "bleAddr": addr,
                "tcpPort": 0,
                "hubUuid": "",
                "connectionType": 0
            }        
        }
        
        function formatUDPDevice(device){
           return {
                "name": device.name + " (TCP)\n" + device.ip + ":" + device.port,
                "setName": "",
                "preferred": true,
                "bleAddr": device.ip,
                "tcpPort": device.port,
                "hubUuid": "",
                "connectionType": 2
            }
        }
        
        function formatSerialPort(port){
            return {
                "name": "Serial " + 
                    (port.isVesc ? "STM32" : port.isEsp ? "ESP32" : "") + 
                    "\n" + port.systemPath,
                "setName": "",
                "preferred": true,
                "bleAddr": port.systemPath,
                "tcpPort": 0,
                "hubUuid": "",
                "connectionType": 1
            }
        }
        
        function formatTcpHubDevice(tcpHubDevice){
           return {                         
               "name": tcpHubDevice.id + " (TCP Hub)\n" + tcpHubDevice.server,
               "setName": "",
               "preferred": true,
               "bleAddr": "",
               "tcpPort": 0,
               "hubUuid": tcpHubDevice.uuid(),
               "connectionType": 3
           }
        }
        function isModelUpdated(array, model) {
            if (array.length !== model.count) return true
            for (var i = 0; i < array.length; ++i) {
                if (JSON.stringify(model.get(i)) !== JSON.stringify(array[i])) {
                    return true
                }
            }
            return false
        }
        function onScanDone(bleDevices, done) {
            if (done) {
                scanDotTimer.running = false
                scanning = false
            }
            var devices = [];
            
            for (var addr in bleDevices){
                devices.push(formatBleDevice(bleDevices[addr], addr))
            }
            
            for(var udpDevice of vescsUdp){
                devices.push(formatUDPDevice(udpDevice))
            }
            
            if (Utility.hasSerialport()) {
                for (var serialPort of VescIf.listSerialPorts()){
                    if (serialPort.isVesc || serialPort.isEsp){
                        devices.push(formatSerialPort(serialPort))
                    }
                }
            }
           
            if (pingTcpHub){
                pingTcpHub = false
                disableDialog()
                var hubDevs = VescIf.getTcpHubDevs()
                for (tcpHubDevice of hubDevs) {
                    if (tcpHubDevice.ping()) {
                        devices.push(formatTcpHubDevice(tcpHubDevice))
                    }
                }
                enableDialog()
            }
            devices.sort((a, b) => (a.connectionType - b.connectionType) || a.name.localeCompare(b.name));
            
           if (isModelUpdated(devices, bleModel)){
               bleModel.clear()
               for (var device of devices){
                   bleModel.append(device)
               }
           }
        }

        function onBleError(info) {
            console.warn("[BLE UI] Connection failed:", info)
            connectionAttemptActive = false
            connectingAddress = ""
            connectingName = ""
            VescIf.emitMessageDialog("BLE Error", info, false, false)
            enableDialog()
        }

        function onConnected() {
            console.log("[BLE UI] Connection established:", connectingAddress)
            finishConnectionAttempt()
        }
    }

    Connections {
        target: VescIf

        function onPortConnectedChanged() {
            if (VescIf.isPortConnected()) {
                finishConnectionAttempt()
            } else if (connectionAttemptActive && !mBle.isConnecting()) {
                finishConnectionAttempt()
            }
        }
    }

    function disableDialog() {
        commDialog.open()
        column.enabled = false
        disableTimeoutTimer.stop()
        disableTimeoutTimer.start()
    }

    function enableDialog() {
        commDialog.close()
        column.enabled = true
        disableTimeoutTimer.stop()
    }

    Timer {
        id: disableTimeoutTimer
        running: false
        repeat: false
        interval: 15000

        onTriggered: {
            connectionAttemptActive = false
            connectingAddress = ""
            connectingName = ""
            enableDialog()
            VescIf.emitMessageDialog("Connect",
                                     "Connection timed out",
                                     false, false)
        }
    }

    Dialog {
        id: commDialog
        title: connectingName.length > 0
               ? qsTr("Connecting to %1...").arg(connectingName)
               : qsTr("Connecting...")
        closePolicy: Popup.NoAutoClose
        modal: true
        focus: true

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20 - notchLeft - notchRight
        x: parent.width/2 - width/2
        y: parent.height / 2 - height / 2
        parent: rootItem.parent
        ProgressBar {
            anchors.fill: parent
            indeterminate: visible
        }
    }

    Dialog {
        property string addr: ""

        id: bleNameDialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        focus: true
        title: "Set BLE Device Name"

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20 - notchLeft - notchRight
        height: 200
        closePolicy: Popup.CloseOnEscape
        x: parent.width/2 - width/2
        y: Math.max(parent.height / 4 - height / 2, 20)
        parent: rootItem.parent

        Rectangle {
            anchors.fill: parent
            height: stringInput.implicitHeight + 14
            border.width: 2
            border.color: Utility.getAppHexColor("lightestBackground")
            color: Utility.getAppHexColor("normalBackground")
            radius: 3
            TextInput {
                id: stringInput
                color: Utility.getAppHexColor("lightText")
                anchors.fill: parent
                anchors.margins: 7
                font.pointSize: 12
                focus: true
            }
        }

        onAccepted: {
            VescIf.storeBleName(addr, stringInput.text)
            VescIf.storeSettings()
            bleModel.clear()
            mBle.emitScanDone()
        }
    }

    Dialog {
        property string uuid: ""

        id: hubPassDialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        focus: true
        title: "Set TCP Hub Password"

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20 - notchLeft - notchRight
        height: 200
        closePolicy: Popup.CloseOnEscape
        x: parent.width/2 - width/2
        y: Math.max(parent.height / 4 - height / 2, 20)
        parent: rootItem.parent

        Rectangle {
            anchors.fill: parent
            height: hubPassInput.implicitHeight + 14
            border.width: 2
            border.color: Utility.getAppHexColor("lightestBackground")
            color: Utility.getAppHexColor("normalBackground")
            radius: 3
            TextInput {
                id: hubPassInput
                color: Utility.getAppHexColor("lightText")
                anchors.fill: parent
                anchors.margins: 7
                font.pointSize: 12
                focus: true
            }
        }

        onAccepted: {
            VescIf.updateTcpHubPassword(uuid, hubPassInput.text)
        }
    }

    Dialog {
        id: bleEn
        standardButtons: Dialog.Ok
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: parent
        parent: rootItem.parent
        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        title: "BLE scan"

        Text {
            color: Utility.getAppHexColor("lightText")
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text: "BLE scan does not seem to be possible. Make sure that the " +
                  "location service is enabled on your device."
        }
    }

    Dialog {
        id: bleScanStart
        standardButtons: Dialog.Ok | Dialog.No
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: parent
        //y: 10 + parent.height / 2 - height / 2
        //x: parent.width/2 - width/2
        //width: parent.width - 20 - notchLeft - notchRight
        parent: rootItem.parent
        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        onAccepted: {
            scanning = true
            scanDotTimer.running = true
            bleModel.clear()
            vescsUdp = []
            mBle.startScan()

            if (!Utility.isBleScanEnabled()) {
                bleEn.open()
            }
        }

        onRejected: {
            VescIf.emitMessageDialog(
                        "Location Permission",
                        "VESC Tool cannot scan for bluetoot devices or log data with location information without the " +
                        "the location permission. Please accept the request in order to use these features.",
                        false, false)
        }

        title: "BLE scan"

        Text {
            color: Utility.getAppHexColor("lightText")
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text:
                "VESC Tool needs to access the location of your device to scan for " +
                "Bluetooth devices as well as for recording your location when doing " +
                "realtime data logging.\n\n" +

                "In order to keep logging when VESC Tool is in the background and/or when the " +
                "screen is off, the permission to log data in the background is also required. " +
                "Otherwise the logs will only get location information together with the motor " +
                "data when the screen is on and VESC Tool is in the foreground."
        }
    }
}
