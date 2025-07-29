/*
 * 应用程序工具栏组件
 * 提供统一的顶部工具栏样式和功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: root
    height: 50
    color: Material.primary

    // 对外暴露的属性
    property string title: "域名邮箱管理器"
    property bool isConfigured: false
    property string currentDomain: "未配置"
    property bool showConfigStatus: true
    property bool showDomainInfo: true
    property bool showMenuButton: false

    // 对外暴露的信号
    signal menuClicked()
    signal configStatusClicked()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // 菜单按钮（可选）
        Button {
            visible: root.showMenuButton
            text: "☰"
            font.pixelSize: 16
            implicitWidth: 40
            implicitHeight: 40
            background: Rectangle {
                color: "transparent"
                radius: 20
                border.color: "white"
                border.width: 1
                opacity: parent.hovered ? 0.8 : 0.6
            }
            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: root.menuClicked()
        }

        // 应用程序标题
        Label {
            text: root.title
            color: "white"
            font.bold: true
            font.pixelSize: 18
        }

        Item { Layout.fillWidth: true }

        // 域名信息
        RowLayout {
            visible: root.showDomainInfo
            spacing: 10

            Label {
                text: "域名:"
                color: "white"
                font.pixelSize: 12
                opacity: 0.8
            }

            Label {
                text: root.currentDomain
                color: "white"
                font.pixelSize: 12
                font.bold: true
            }
        }

        // 分隔线
        Rectangle {
            visible: root.showConfigStatus && root.showDomainInfo
            width: 1
            height: 20
            color: "white"
            opacity: 0.3
        }

        // 配置状态指示器
        RowLayout {
            visible: root.showConfigStatus
            spacing: 8

            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: root.isConfigured ? "#4CAF50" : "#F44336"

                // 呼吸动画效果
                SequentialAnimation {
                    running: !root.isConfigured
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: parent
                        property: "opacity"
                        from: 1.0
                        to: 0.3
                        duration: 1000
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        target: parent
                        property: "opacity"
                        from: 0.3
                        to: 1.0
                        duration: 1000
                        easing.type: Easing.InOutSine
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.configStatusClicked()

                    ToolTip.visible: containsMouse
                    ToolTip.text: root.isConfigured ? "配置已完成" : "配置未完成，点击查看详情"
                    ToolTip.delay: 500
                }
            }

            Label {
                text: root.isConfigured ? "已配置" : "未配置"
                color: "white"
                font.pixelSize: 12
                opacity: 0.9
            }
        }

        // 当前时间显示
        Label {
            id: timeLabel
            text: new Date().toLocaleTimeString()
            color: "white"
            font.pixelSize: 12
            opacity: 0.8

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeLabel.text = new Date().toLocaleTimeString()
            }
        }
    }

    // 底部阴影效果
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#40000000" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // 公共方法
    function updateConfigStatus(configured, domain) {
        root.isConfigured = configured
        root.currentDomain = domain || "未配置"
    }

    function showNotification(message, type) {
        // 可以在这里添加顶部通知栏的显示逻辑
        console.log("工具栏通知:", type, message)
    }
}
