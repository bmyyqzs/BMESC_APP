import QtQuick 2.15
import QtQuick.Controls 2.15

// Home tab host. The commercial MVP keeps connection and node management in the
// Device tab; the Home tab remains the realtime product dashboard.
StackView {
    id: flow

    property var deviceModel
    property var theme
    signal requestConnect()

    readonly property bool realtimeActive: currentItem && currentItem.isHomeDashboard === true

    function showConnect() {
        flow.pop(null)
    }

    function showDashboard() {
        flow.pop(null)
    }

    function showDevice() {
        flow.pop(null)
    }

    initialItem: homeComponent

    Component {
        id: homeComponent

        BMHomePage {
            property bool isHomeDashboard: true
            deviceModel: flow.deviceModel
            theme: flow.theme
            onRequestConnect: flow.requestConnect()
            onRequestDashboard: flow.showDashboard()
            onRequestDevice: flow.showDevice()
        }
    }
}
