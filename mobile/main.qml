/*
    Copyright 2017 - 2019 Benjamin Vedder	benjamin@vedder.se

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

import QtQuick 2.10
import QtQuick.Controls 2.10
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.10

import Vedder.vesc.bleuart 1.0
import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0
import Vedder.vesc.utility 1.0
import Vedder.vesc.vesc3ditem 1.0
import BM.Product 1.0

ApplicationWindow {
    id: appWindow
    property Commands mCommands: VescIf.commands()
    property ConfigParams mMcConf: VescIf.mcConfig()
    property ConfigParams mAppConf: VescIf.appConfig()
    property ConfigParams mInfoConf: VescIf.infoConfig()
    property var mBle: VescIf.bleDeviceObject()
    property bool transportConnected: productDevice.connected
    property bool protocolReady: productDevice.protocolReady
    property bool fwReadCorrectly: false

    ProductDeviceModel {
        id: productDevice
        vesc: VescIf
        highRateTelemetry: protocolReady && mainSwipeView.currentIndex === 0
    }

    Connections {
        target: productDevice

        function onRequestShowHome() {
            appWindow.navigateToPage(0)
        }
    }

    BMTheme {
        id: theme
    }

    function navigateToPage(pageIndex) {
        if (pageIndex < 0 || pageIndex >= rep.model.length) {
            return
        }

        tabBar.setCurrentIndex(pageIndex)
        mainSwipeView.setCurrentIndex(pageIndex)
    }

    function openConnectionPage() {
        navigateToPage(1)
        productDevice.startBleScan()
    }

    visible: true
    width: 390
    height: 844
    title: qsTr("BMESC")

    readonly property bool isEnglish: productDevice.isEnglish

    function t(zh, en) {
        return isEnglish ? en : zh
    }

    // App-level premium gradient background (prototype body/frame glows).
    background: BMBackground {}

    // Full screen iPhone X workaround:
    property int notchLeft: 0
    property int notchRight: 0
    property int notchBot: 0
    property int notchTop: 0

    // https://github.com/ekke/c2gQtWS_x/blob/master/qml/main.qml
    flags: Qt.platform.os === "ios" ? (Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint) : Qt.Window

    function updateNotch() {
        notchTop   = Utility.getSafeAreaMargins(appWindow)["top"]
        notchLeft  = Utility.getSafeAreaMargins(appWindow)["left"]
        notchRight = Utility.getSafeAreaMargins(appWindow)["right"]
        if (Qt.platform.os === "ios") {
            // leaving too much room at the bottom
            notchBot = Utility.getSafeAreaMargins(appWindow)["bottom"] / 2
        } else {
            notchBot = Utility.getSafeAreaMargins(appWindow)["bottom"]
        }
    }

    Timer {
        id: oriTimer
        interval: 100; running: true; repeat: false
        onTriggered: {
            updateNotch()
        }
    }

    Screen.orientationUpdateMask: Qt.LandscapeOrientation | Qt.PortraitOrientation
    Screen.onPrimaryOrientationChanged: {
        oriTimer.start()
    }

    Component.onCompleted: {
        updateNotch()
        VescIf.setIntroDone(true)
        if (Qt.application.arguments.indexOf("--bm-seed-fault-logs") !== -1) {
            productDevice.seedFaultLogsForTesting(16)
        }
        startupInitTimer.start()
    }

    Timer {
        id: startupInitTimer
        interval: 250
        repeat: false
        running: false
        onTriggered: {
            Utility.keepScreenOn(VescIf.keepScreenOn())
            Utility.allowScreenRotation(VescIf.getAllowScreenRotation())
            Utility.stopGnssForegroundService()
        }
    }

    Controls {
        id: controls
        parentWidth: appWindow.width
        parentHeight: mainSwipeView.height
        dialogParent: mainSwipeView
    }

    MultiSettings {
        id: multiSettings
        dialogParent: mainSwipeView
    }

    Loader {
        id: settingsLoader
        anchors.fill: parent
        asynchronous: true
        visible: status == Loader.Ready
        sourceComponent: Settings {
            id: settings
            dialogParent: mainSwipeView
        }
    }

    Loader {
        id: canDrawerLoader
        anchors.fill: parent
        asynchronous: true
        visible: status == Loader.Ready
        sourceComponent: Drawer {
            id: canDrawer
            edge: Qt.RightEdge
            width: Math.min(0.6 * appWindow.width, 0.8 * appWindow.height)
            height: appWindow.height > appWindow.width ?  appWindow.height - footer.height - headerBar.height : appWindow.height
            y: appWindow.height > appWindow.width ?  headerBar.height : 0
            dragMargin: 20
            interactive: false

            Overlay.modal: Rectangle {
                color: "#AA000000"
            }

            CanScreen {
                id: canScreen
                anchors.fill: parent
                dialogParent: mainSwipeView
            }

            onVisibleChanged: {
                if (visible) {
                    canScreen.scanIfEmpty()
                }
            }
        }
    }

    Drawer {
        id: drawer
        width: Math.min(0.5 *appWindow.width, 0.75 *appWindow.height)
        height: appWindow.height > appWindow.width ?  appWindow.height - footer.height - headerBar.height : appWindow.height
        y: appWindow.height > appWindow.width ?  headerBar.height : 0
        dragMargin: 20
        interactive: false
        visible: false

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 0

            Image {
                id: image
                Layout.preferredWidth: Math.min(parent.width, parent.height)*0.8
                Layout.preferredHeight: (sourceSize.height * Layout.preferredWidth) / sourceSize.width
                Layout.margins: Math.min(parent.width, parent.height)*0.1
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                source: "qrc:/res/branding/bm_logo_transparent.png"
                antialiasing: true

            }

            Button {
                id: reconnectButton
                Layout.fillWidth: true
                text: transportConnected ? "Disconnect" : "Connect"
                flat: true
                onClicked: {
                    if (transportConnected) {
                        VescIf.disconnectPort()
                    } else {
                        openConnectionPage()
                    }

                    drawer.close()
                }
            }

            Item {
                // Spacer
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Button {
                Layout.fillWidth: true
                text: "Settings"
                flat: true

                onClicked: {
                    drawer.close()
                    settingsLoader.item.openDialog()
                }
            }

            Button {
                Layout.fillWidth: true
                text: "About"
                flat: true
                onClicked: {
                    VescIf.emitMessageDialog(
                                "About",
                                Utility.aboutText(),
                                true, true)
                }
            }

            Button {
                Layout.fillWidth: true
                text: "Changelog"
                flat: true

                onClicked: {
                    VescIf.emitMessageDialog(
                                "BMESC Changelog",
                                Utility.vescToolChangeLog(),
                                true, false)
                }
            }

            Button {
                Layout.fillWidth: true
                text: "License"
                flat: true

                onClicked: {
                    if (Qt.platform.os == "ios"){
                        VescIf.emitMessageDialog(
                                    mInfoConf.getLongName("ios_license_text"),
                                    mInfoConf.getDescription("ios_license_text"),
                                    true, true)
                    } else {
                        VescIf.emitMessageDialog(
                                    mInfoConf.getLongName("gpl_text"),
                                    mInfoConf.getDescription("gpl_text"),
                                    true, true)
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                text: "Privacy Policy"
                flat: true

                onClicked: {
                    Qt.openUrlExternally("https://gcore.jsdelivr.net/gh/bmyyqzs/BMESC_APP@main/docs/app-store/privacy-policy.html")
                }
            }
        }
    }

    SwipeView {
        id: mainSwipeView
        currentIndex: 0
        onCurrentIndexChanged: {
            if (tabBar.currentIndex !== currentIndex) {
                tabBar.setCurrentIndex(currentIndex)
            }
        }
        anchors.fill: parent
        anchors.leftMargin: notchLeft*0.75
        anchors.rightMargin: notchRight*0.75
        clip: true
        contentItem: ListView {
            model: mainSwipeView.contentModel
            interactive: mainSwipeView.interactive
            currentIndex: mainSwipeView.currentIndex

            spacing: mainSwipeView.spacing
            orientation: mainSwipeView.orientation
            snapMode: ListView.SnapOneItem
            boundsBehavior: Flickable.StopAtBounds

            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 0
            highlightMoveDuration: 250

            maximumFlickVelocity: 8 * (mainSwipeView.orientation ===
                                       Qt.Horizontal ? width : height)
        }

        // Home tab: full connect -> device -> realtime flow lives inside this StackView.
        Page {
            background: Rectangle { color: "transparent" }
            BMHomeFlow {
                id: homeFlow
                anchors.fill: parent
                deviceModel: productDevice
                theme: theme
                onRequestConnect: appWindow.openConnectionPage()
            }
        }

        Page {
            background: Rectangle { color: "transparent" }
            BMDevicePage {
                anchors.fill: parent
                deviceModel: productDevice
                onRequestConnect: productDevice.startBleScan()
                onRequestDisconnect: productDevice.disconnectDevice()
            }
        }

        Page {
            background: Rectangle { color: "transparent" }
            BMMinePage {
                anchors.fill: parent
                deviceModel: productDevice
                onLangToggled: productDevice.toggleLanguage()
            }
        }
    }

    // Connection-status plumbing kept alive for the legacy timers / Connections below.
    // The visible connection state is shown on the home card (phase 2), so these are hidden.
    Item {
        visible: false
        Rectangle {
            id: connectedRect
            Text { id: connectedText }
        }
    }

    header: Rectangle {
        id: headerBar
        color: "transparent"
        height: notchTop + 76

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            text: tabBar.currentIndex === 2 ? appWindow.t("我的", "Mine")
                  : (tabBar.currentIndex === 1 ? appWindow.t("设备", "Device") : appWindow.t("首页", "Home"))
            color: "#f4f1ea"
            font.pixelSize: 22
            font.bold: true
        }

        Rectangle {
            id: languageSwitch
            visible: tabBar.currentIndex === 0
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 22 + notchLeft * 0.75
            anchors.bottomMargin: 14
            width: 76
            height: 32
            radius: 999
            color: "#15191f"
            border.width: 1
            border.color: "#343b42"

            Rectangle {
                x: appWindow.isEnglish ? parent.width / 2 + 2 : 2
                y: 2
                width: parent.width / 2 - 4
                height: parent.height - 4
                radius: 999
                color: "#c69c6e"
                Behavior on x { NumberAnimation { duration: 140 } }
            }

            Row {
                anchors.fill: parent
                Text {
                    width: parent.width / 2
                    height: parent.height
                    text: "中"
                    color: appWindow.isEnglish ? "#9aa3b2" : "#17120a"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    width: parent.width / 2
                    height: parent.height
                    text: "EN"
                    color: appWindow.isEnglish ? "#17120a" : "#9aa3b2"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: productDevice.toggleLanguage()
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 38 + notchRight * 0.75
            anchors.bottomMargin: 15
            width: Math.max(76, statusText.implicitWidth + 34)
            height: 30
            radius: 999
            color: "#15191f"
            border.width: 1
            border.color: protocolReady ? "#356653"
                          : (transportConnected ? "#8d704f" : "#2e353d")

            Rectangle {
                width: 6
                height: 6
                radius: 3
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: protocolReady ? theme.success
                      : (transportConnected ? "#dfbd91" : "#6f7886")
            }

            Text {
                id: statusText
                anchors.left: parent.left
                anchors.leftMargin: 25
                anchors.right: parent.right
                anchors.rightMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                text: protocolReady ? appWindow.t("已连接", "Connected")
                      : (transportConnected ? appWindow.t("识别中", "Reading") : appWindow.t("未连接", "Offline"))
                color: protocolReady ? theme.success
                      : (transportConnected ? "#dfbd91" : "#c1c7d0")
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    TabButton {
        id: uiHwButton
        visible: uiHwPage.visible
        text: "HwUi"
        width: tabBar.buttonWidth
    }

    Page {
        id: uiHwPage
        visible: false

        Item {
            id: uiHw
            anchors.fill: parent
            property var tabBarItem: tabBar
            property var swipeViewItem: mainSwipeView
        }
    }

    TabButton {
        id: uiAppButton
        visible: uiAppPage.visible
        text: "AppUi"
        width: tabBar.buttonWidth
    }

    Page {
        id: uiAppPage
        visible: false

        Item {
            id: uiApp
            anchors.fill: parent
            property var tabBarItem: tabBar
            property var swipeViewItem: mainSwipeView
        }
    }

    TabButton {
        id: confMotorButton
        visible: confPageMotor.visible
        text: "Motor Cfg"
        width: tabBar.buttonWidth
    }

    TabButton {
        id: confAppButton
        visible: confPageApp.visible
        text: "App Cfg"
        width: tabBar.buttonWidth
    }

    TabButton {
        id: confCustomButton
        visible: confCustomPage.visible
        text: "Custom Cfg"
        width: tabBar.buttonWidth
    }

    Page {
        id: confPageMotor
        visible: false

        Loader {
            id: confMotorLoader
            anchors.fill: parent
            asynchronous: true
            sourceComponent: ConfigPageMotor {
                anchors.fill: parent
                dialogParent: mainSwipeView
                anchors.leftMargin: 10
                anchors.rightMargin: 10
            }
        }
    }

    Page {
        id: confPageApp
        visible: false

        Loader {
            id: confAppLoader
            anchors.fill: parent
            asynchronous: true
            sourceComponent: ConfigPageApp {
                dialogParent: mainSwipeView
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
            }
        }
    }

    Page {
        id: confCustomPage
        visible: false

        Loader {
            id: confCustomLoader
            anchors.fill: parent
            asynchronous: true
            sourceComponent: ConfigPageCustom {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
            }
        }
    }

    footer: Rectangle {
        id: navBar
        clip: true
        color: "#e6050609"
        width: parent.width
        height: 92 + notchBot

        TabBar {
            id: tabBar
            currentIndex: 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 8
            height: 68
            spacing: 0
            Material.accent: "transparent"

            onCurrentIndexChanged: {
                if (mainSwipeView.currentIndex !== currentIndex) {
                    mainSwipeView.setCurrentIndex(currentIndex)
                }
            }

            property int buttonWidth: tabBar.width / Math.max(1, rep.model.length)

            background: Rectangle { color: "transparent" }

            Repeater {
                id: rep
                model: [
                    {
                        label: appWindow.t("首页", "Home"),
                        icon: "qrc:/res/icons/bm_tab_home.png",
                        activeIcon: "qrc:/res/icons/bm_tab_home_active.png"
                    },
                    {
                        label: appWindow.t("设备", "Device"),
                        icon: "qrc:/res/icons/bm_tab_device.png",
                        activeIcon: "qrc:/res/icons/bm_tab_device_active.png"
                    },
                    {
                        label: appWindow.t("我的", "Mine"),
                        icon: "qrc:/res/icons/bm_tab_mine.png",
                        activeIcon: "qrc:/res/icons/bm_tab_mine_active.png"
                    }
                ]

                TabButton {
                    id: tabBtn
                    width: tabBar.buttonWidth
                    height: 68
                    Material.accent: "transparent"

                    background: Rectangle { color: "transparent" }

                    contentItem: Item {
                        implicitWidth: tabBtn.width
                        implicitHeight: tabBtn.height

                        Image {
                            id: tabIcon
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 2
                            width: 34
                            height: 34
                            source: tabBtn.checked ? modelData.activeIcon : modelData.icon
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: tabIcon.bottom
                            anchors.topMargin: 3
                            text: modelData.label
                            color: tabBtn.checked ? theme.gold2 : "#6f7886"
                            font.pixelSize: 14
                            font.bold: tabBtn.checked
                        }

                    }
                }
            }
        }
    }

    Timer {
        id: statusTimer
        interval: 1600
        running: false
        repeat: false
        onTriggered: {
            connectedText.text = VescIf.getConnectedPortName()
            connectedRect.color = Utility.getAppHexColor("lightBackground")
        }
    }

    Timer {
        id: uiTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!statusTimer.running && connectedText.text !== VescIf.getConnectedPortName()) {
                connectedText.text = VescIf.getConnectedPortName()
            }
        }
    }

    Timer {
        id: confTimer
        interval: 1000
        running: true
        repeat: true

        property bool mcConfRx: false
        property bool appConfRx: false

        onTriggered: {
            if (VescIf.isPortConnected() && VescIf.getLastFwRxParams().hwTypeStr() === "VESC") {
                if (!mcConfRx) {
                    mCommands.getMcconf()
                }

                if (!appConfRx) {
                    mCommands.getAppConf()
                }
            }
        }
    }

    Timer {
        id: bleDisconnectTimer
        interval: 1000
        running: false
        repeat: true
        property int trysLeft: 0

        onTriggered: {
            if(trysLeft < 1 || fwReadCorrectly) {
                bleDisconnectTimer.stop()
                if (!VescIf.isPortConnected()) {
                    openConnectionPage()
                }
                return
            }

            // A BLE setup and firmware handshake can take several seconds.
            // Do not tear down an active attempt by starting it again every tick.
            if (mBle.isConnecting() || mBle.isConnected()) {
                return
            }

            if(VescIf.getLastBleAddr().length > 0) {
                VescIf.connectBle(VescIf.getLastBleAddr())
                trysLeft = trysLeft - 1
            } else {
                trysLeft = 0
            }
        }
    }

    Dialog {
        id: vescDialog
        standardButtons: Dialog.Ok
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20 - notchLeft - notchRight
        height: Math.min(implicitHeight, parent.height - 40 - notchBot - notchTop)
        x: (parent.width - width) / 2
        y: (parent.height - height + notchTop) / 2
        parent: mainSwipeView

        ScrollView {
            id: vescDialogScroll
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            Text {
                id: vescDialogLabel
                color: {color = Utility.getAppHexColor("lightText")}
                linkColor: {linkColor = Utility.getAppHexColor("lightAccent")}
                verticalAlignment: Text.AlignVCenter
                anchors.fill: parent
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                textFormat: Text.RichText
                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }
        }
    }

    property var hwUiObj: 0
    property var appUiObj: 0

    function objectTextMatches(obj, patterns) {
        var values = []

        try {
            if (obj.text !== undefined && obj.text !== null) {
                values.push(String(obj.text))
            }
        } catch (e) {}

        try {
            if (obj.title !== undefined && obj.title !== null) {
                values.push(String(obj.title))
            }
        } catch (e) {}

        try {
            if (obj.tabTitle !== undefined && obj.tabTitle !== null) {
                values.push(String(obj.tabTitle))
            }
        } catch (e) {}

        try {
            if (obj.objectName !== undefined && obj.objectName !== null) {
                values.push(String(obj.objectName))
            }
        } catch (e) {}

        try {
            if (obj.source !== undefined && obj.source !== null) {
                values.push(String(obj.source))
            }
        } catch (e) {}

        for (var i = 0; i < values.length; i++) {
            var lower = values[i].toLowerCase()
            for (var j = 0; j < patterns.length; j++) {
                if (lower.indexOf(patterns[j]) >= 0) {
                    return true
                }
            }
        }

        return false
    }

    function hideObjectTreeEntry(obj) {
        try { obj.visible = false } catch (e) {}
        try { obj.enabled = false } catch (e) {}
        try { obj.opacity = 0 } catch (e) {}
        try { obj.height = 0 } catch (e) {}
        try { obj.width = 0 } catch (e) {}
    }

    function trimAppUiObjectTree(obj) {
        if (!obj) {
            return
        }

        if (objectTextMatches(obj, ["tunes control data"])) {
            hideObjectTreeEntry(obj)
        } else if (objectTextMatches(obj, ["settings-96", "settingsbutton", "settingbutton"])) {
            hideObjectTreeEntry(obj)
        } else {
            var textIsSettings = false
            try {
                textIsSettings = obj.text !== undefined && String(obj.text).toLowerCase() === "settings"
            } catch (e) {}

            if (textIsSettings) {
                hideObjectTreeEntry(obj)
            }
        }

        try {
            if (obj.children) {
                for (var i = 0; i < obj.children.length; i++) {
                    trimAppUiObjectTree(obj.children[i])
                }
            }
        } catch (e) {}
    }

    function updateHwAppUi () {
        if (hwUiObj != 0) {
            hwUiObj.destroy()
            hwUiObj = 0
        }

        if (appUiObj != 0) {
            appUiObj.destroy()
            appUiObj = 0
        }

        mainSwipeView.interactive = true
        headerBar.visible = true
        tabBar.enabled = true
        uiHwPage.visible = false
        uiHwPage.parent = null
        uiHwButton.parent = null
        uiAppPage.visible = false
        uiAppPage.parent = null
        uiAppButton.parent = null

        if (appUiObj != 0) {
            appUiObj.destroy()
            appUiObj = 0
        }
    }

    Timer {
        id: trimAppUiTimer
        interval: 250
        repeat: false
        running: false
        onTriggered: {
            trimAppUiObjectTree(appUiObj)
        }
    }

    Timer {
        id: confCustomTimer
        running: false
        triggeredOnStart: true
        interval: 500
        repeat: true
        onTriggered: {
            stop()
            confCustomPage.visible = false
            confCustomPage.parent = null
            confCustomButton.parent = null
        }
    }

    function updateConfCustom () {
        confCustomTimer.start()
    }

    function indexOffset() {
        var res = 0
        if (uiHwButton.visible) {
            res++
        }
        if (uiAppButton.visible) {
            res++
        }
        return res
    }

    Connections {
        target: VescIf
        function onPortConnectedChanged() {
            connectedText.text = VescIf.getConnectedPortName()
            if (!VescIf.isPortConnected()) {
                confTimer.mcConfRx = false
                confTimer.appConfRx = false
                fwReadCorrectly = false
                navigateToPage(0)
            }

            if (VescIf.useWakeLock()) {
                VescIf.setWakeLock(VescIf.isPortConnected())
            }
        }

        function onUnintentionalBleDisconnect() {
            bleDisconnectTimer.trysLeft = 5
            bleDisconnectTimer.start()
        }

        function onStatusMessage(msg, isGood) {
            connectedText.text = msg
            connectedRect.color = isGood ? Utility.getAppHexColor("lightAccent") : Utility.getAppHexColor("red")
            statusTimer.restart()
        }

        function onMessageDialog(title, msg, isGood, richText) {
            if (!richText && msg.trim().startsWith("#")) {
                vescDialogLabel.textFormat = Text.MarkdownText
            } else {
                vescDialogLabel.textFormat = richText ? Text.RichText : Text.AutoText
            }

            vescDialog.title = title
            vescDialogLabel.text = (richText ? "<style>a:link { color: lightblue; }</style>" : "") + msg
            vescDialogScroll.ScrollBar.vertical.position = 0
            vescDialog.open()
        }

        function onFwRxChanged(rx, limited) {
            if (rx) {
                confPageMotor.visible = false
                confPageApp.visible = false
                confPageMotor.parent = null
                confPageApp.parent = null
                confMotorButton.parent = null
                confAppButton.parent = null

                if (VescIf.getFwSupportsConfiguration()) {
                    confTimer.restart()
                    confTimer.mcConfRx = false
                    confTimer.appConfRx = false

                    mCommands.getMcconf()
                    mCommands.getAppConf()
                }

                fwReadCorrectly = true
                bleDisconnectTimer.stop()
            } else {
                updateConfCustom()
            }

            updateHwAppUi()
        }

        function onQmlLoadDone() {
            // Commercial mobile flow does not load hardware-provided custom UI.
            // Keep the connection alive and continue using the BM product screens.
        }

        function onCustomConfigLoadDone() {
            updateConfCustom()
        }
    }

    Connections {
        target: mMcConf

        function onUpdated() {
            confTimer.mcConfRx = true
        }
    }

    Connections {
        target: mAppConf

        function onUpdated() {
            confTimer.appConfRx = true
        }
    }

    Connections {
        target: mCommands
        function onValuesImuReceived(values, mask) {
            // RT IMU page is intentionally hidden in this trimmed build.
        }

        function onDeserializeConfigFailed(isMc, isApp) {
            if (isMc) {
                confTimer.mcConfRx = true
            }

            if (isApp) {
                confTimer.appConfRx = true
            }
        }
    }

}
