import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

// Discover page matched to the target screenshot (serach.png): a single 用户动态
// (Second Phase Community) card containing two items. Background transparent.
Item {
    id: root
    readonly property real pageMargin: Math.max(24, Math.min(40, width * 0.065))

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: root.width
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: root.pageMargin
                Layout.rightMargin: root.pageMargin
                Layout.topMargin: 22
                Layout.preferredHeight: communityColumn.implicitHeight + 40
                radius: 30
                border.width: 1
                border.color: "#283038"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1a1e23" }
                    GradientStop { position: 1.0; color: "#111418" }
                }

                Column {
                    id: communityColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 25
                    spacing: 20

                    Column {
                        width: parent.width
                        spacing: 7
                        Text {
                            text: qsTr("用户动态")
                            color: "#f4f1ea"
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Text {
                            text: qsTr("Second Phase Community")
                            color: "#9aa3b2"
                            font.pixelSize: 15
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: [
                            qsTr("骑行轨迹、速度曲线、视频动态与评论点赞。"),
                            qsTr("挑战活动：7 日 100km、稳定巡航速度榜。")
                        ]

                        Rectangle {
                            width: communityColumn.width
                            height: itemText.implicitHeight + 36
                            radius: 22
                            color: "#0b0e14"
                            border.width: 1
                            border.color: "#283038"

                            Text {
                                id: itemText
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 22
                                anchors.rightMargin: 22
                                text: modelData
                                color: "#c7d0dd"
                                font.pixelSize: 16
                                font.bold: true
                                wrapMode: Text.WordWrap
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
}
