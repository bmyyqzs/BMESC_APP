import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Item {
    id: root

    signal requestUnitSystem(bool useImperial)

    property string appVersion: "1.0.0"
    property string languageName: qsTr("Chinese / English")
    property bool notificationsEnabled: true
    property bool useImperialUnits: false
    readonly property string privacyPolicyUrl: "https://cdn.jsdelivr.net/gh/bmyyqzs/BMESC_APP@main/docs/app-store/privacy-policy.html"
    readonly property string userAgreementUrl: "https://cdn.jsdelivr.net/gh/bmyyqzs/BMESC_APP@main/docs/app-store/user-agreement.html"
    readonly property string supportUrl: "https://cdn.jsdelivr.net/gh/bmyyqzs/BMESC_APP@main/docs/app-store/support.html"
    readonly property string openSourceUrl: "https://cdn.jsdelivr.net/gh/bmyyqzs/BMESC_APP@main/docs/app-store/open-source.html"

    readonly property color pageColor: "#090b0d"
    readonly property color surfaceColor: "#13171a"
    readonly property color raisedColor: "#191e22"
    readonly property color goldColor: "#d6ad68"
    readonly property color textColor: "#f4f0e8"
    readonly property color secondaryTextColor: "#92999d"

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
            spacing: 10

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 20
                text: qsTr("Settings")
                color: root.textColor
                font.pixelSize: 28
                font.bold: true
            }

            SectionLabel {
                text: qsTr("Preferences")
            }

            SettingsGroup {
                SettingRow {
                    label: qsTr("Language")
                    value: root.languageName
                }
                SettingRow {
                    label: qsTr("Units")
                    value: root.useImperialUnits ? qsTr("Imperial") : qsTr("Metric")
                    onClicked: root.requestUnitSystem(!root.useImperialUnits)
                }
                SettingRow {
                    label: qsTr("Notifications")
                    value: root.notificationsEnabled ? qsTr("On") : qsTr("Off")
                    showDivider: false
                }
            }

            SectionLabel {
                text: qsTr("Support and legal")
            }

            SettingsGroup {
                SettingRow {
                    label: qsTr("Privacy policy")
                    value: qsTr("Open")
                    onClicked: {
                        Qt.openUrlExternally(root.privacyPolicyUrl)
                    }
                }
                SettingRow {
                    label: qsTr("User agreement")
                    value: qsTr("Open")
                    onClicked: {
                        Qt.openUrlExternally(root.userAgreementUrl)
                    }
                }
                SettingRow {
                    label: qsTr("Support")
                    value: qsTr("Open")
                    onClicked: {
                        Qt.openUrlExternally(root.supportUrl)
                    }
                }
                SettingRow {
                    label: qsTr("Open source licenses")
                    value: qsTr("Open")
                    onClicked: {
                        Qt.openUrlExternally(root.openSourceUrl)
                    }
                }
                SettingRow {
                    label: qsTr("About BMESC")
                    value: "v" + root.appVersion
                    showDivider: false
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 8
                text: qsTr("BMESC · Version %1").arg(root.appVersion)
                color: "#656b6f"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
            }
        }
    }

    component SectionLabel: Text {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        Layout.topMargin: 10
        color: root.secondaryTextColor
        font.pixelSize: 12
        font.bold: true
        font.capitalization: Font.AllUppercase
    }

    component SettingsGroup: Rectangle {
        default property alias rows: groupColumn.data

        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        Layout.preferredHeight: groupColumn.implicitHeight
        radius: 8
        color: root.surfaceColor
        border.width: 1
        border.color: "#262c30"

        Column {
            id: groupColumn
            width: parent.width
        }
    }

    component SettingRow: Item {
        property string label: ""
        property string value: ""
        property bool showDivider: true
        signal clicked()

        width: parent ? parent.width : 0
        height: 56

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: label
            color: root.textColor
            font.pixelSize: 14
            font.bold: true
        }

        Text {
            anchors.left: parent.horizontalCenter
            anchors.right: chevron.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: value
            color: root.secondaryTextColor
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }

        Text {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: root.goldColor
            font.pixelSize: 22
        }

        Rectangle {
            visible: showDivider
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            height: 1
            color: "#252b2f"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }
}
