import QtQuick 2.10
import QtQuick.Controls 2.10
import QtQuick.Layouts 1.3
import QtQuick.Window 2.10

import Vedder.vesc.utility 1.0

ApplicationWindow {
    id: appWindow

    property bool connected: VescIf.isPortConnected()
    property int notchLeft: 0
    property int notchRight: 0
    property int notchBot: 0
    property int notchTop: 0

    visible: true
    width: 500
    height: 850
    color: "#10171c"
    title: "BMESC"
    flags: Qt.platform.os === "ios"
           ? (Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint)
           : Qt.Window

    function updateNotch() {
        var margins = Utility.getSafeAreaMargins(appWindow)
        notchTop = margins["top"]
        notchLeft = margins["left"]
        notchRight = margins["right"]
        notchBot = Qt.platform.os === "ios" ? margins["bottom"] / 2 : margins["bottom"]
    }

    Component.onCompleted: updateNotch()

    Screen.orientationUpdateMask: Qt.LandscapeOrientation | Qt.PortraitOrientation
    Screen.onPrimaryOrientationChanged: updateNotch()

    header: Rectangle {
        color: "#10171c"
        height: 82 + notchTop

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: notchTop
            anchors.leftMargin: 20 + notchLeft
            anchors.rightMargin: 12 + notchRight
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: "BMESC"
                    color: "white"
                    font.pixelSize: 28
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    text: connected ? VescIf.getConnectedPortName() : "Bluetooth not connected"
                    color: connected ? "#7ff7d4" : "#9fabaf"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }

            Button {
                visible: connected
                text: "Disconnect"
                onClicked: VescIf.disconnectPort()
            }
        }
    }

    ConnectScreen {
        id: connectionScreen
        anchors.fill: parent
        opened: true
        allowHide: false
        fullLogo: false
        autoStartScan: true
    }

    Dialog {
        id: messageDialog
        modal: true
        focus: true
        standardButtons: Dialog.Ok
        width: Math.min(appWindow.width - 32 - notchLeft - notchRight, 440)
        x: (appWindow.width - width) / 2
        y: Math.max(notchTop + 20, (appWindow.height - height) / 2)

        property alias message: messageText.text

        Label {
            id: messageText
            width: parent.width
            wrapMode: Text.WordWrap
            color: Utility.getAppHexColor("lightText")
        }
    }

    Connections {
        target: VescIf

        function onPortConnectedChanged() {
            connected = VescIf.isPortConnected()
        }

        function onMessageDialog(title, msg, isGood, richText) {
            messageDialog.title = title
            messageDialog.message = msg
            messageDialog.open()
        }
    }
}
