/*
 * 调试面板组件
 * 提供开发和调试时的信息显示和工具
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: root
    width: 300
    height: 400
    color: "#f8f9fa"
    border.color: "#dee2e6"
    border.width: 1
    radius: 8
    visible: false

    // 对外暴露的属性
    property var globalState: ({})
    property var statistics: ({})
    property bool isConfigured: false
    property string currentDomain: ""

    // 标题栏
    Rectangle {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: "#6c757d"
        radius: 8

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 8
            color: "#6c757d"
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Label {
                text: "🔧 调试面板"
                color: "white"
                font.bold: true
                font.pixelSize: 14
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "✕"
                implicitWidth: 24
                implicitHeight: 24
                background: Rectangle {
                    color: "transparent"
                    radius: 12
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.visible = false
            }
        }
    }

    // 内容区域
    ScrollView {
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10

        ColumnLayout {
            width: parent.width
            spacing: 15

            // 系统状态
            GroupBox {
                title: "系统状态"
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: "配置状态: " + (root.isConfigured ? "✅ 已配置" : "❌ 未配置")
                        font.pixelSize: 12
                        color: root.isConfigured ? "#28a745" : "#dc3545"
                    }

                    Label {
                        text: "当前域名: " + root.currentDomain
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "内存使用: " + Qt.application.arguments.length + " 参数"
                        font.pixelSize: 12
                    }
                }
            }

            // 全局状态
            GroupBox {
                title: "全局状态"
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: "邮箱数量: " + (root.globalState.emailList ? root.globalState.emailList.length : 0)
                        font.pixelSize: 12
                    }

                    Label {
                        text: "标签数量: " + (root.globalState.tagList ? root.globalState.tagList.length : 0)
                        font.pixelSize: 12
                    }

                    Label {
                        text: "当前页码: " + (root.globalState.currentPage || 1)
                        font.pixelSize: 12
                    }

                    Label {
                        text: "加载状态: " + (root.globalState.isLoading ? "加载中" : "空闲")
                        font.pixelSize: 12
                    }

                    Label {
                        text: "选中邮箱: " + (root.globalState.selectedEmails ? root.globalState.selectedEmails.length : 0)
                        font.pixelSize: 12
                    }
                }
            }

            // 统计信息
            GroupBox {
                title: "统计信息"
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: "总邮箱数: " + (root.statistics.total_emails || 0)
                        font.pixelSize: 12
                    }

                    Label {
                        text: "今日创建: " + (root.statistics.today_created || 0)
                        font.pixelSize: 12
                    }

                    Label {
                        text: "活跃邮箱: " + (root.statistics.active_emails || 0)
                        font.pixelSize: 12
                    }

                    Label {
                        text: "成功率: " + (root.statistics.success_rate || 100) + "%"
                        font.pixelSize: 12
                    }
                }
            }

            // 调试工具
            GroupBox {
                title: "调试工具"
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Button {
                        text: "模拟邮箱生成"
                        Layout.fillWidth: true
                        font.pixelSize: 12
                        onClicked: {
                            console.log("模拟邮箱生成")
                            simulateEmailGeneration()
                        }
                    }

                    Button {
                        text: "清空全局状态"
                        Layout.fillWidth: true
                        font.pixelSize: 12
                        onClicked: {
                            console.log("清空全局状态")
                            clearGlobalState()
                        }
                    }

                    Button {
                        text: "打印状态信息"
                        Layout.fillWidth: true
                        font.pixelSize: 12
                        onClicked: {
                            console.log("=== 调试信息 ===")
                            console.log("全局状态:", JSON.stringify(root.globalState, null, 2))
                            console.log("统计信息:", JSON.stringify(root.statistics, null, 2))
                            console.log("配置状态:", root.isConfigured)
                            console.log("当前域名:", root.currentDomain)
                        }
                    }

                    Button {
                        text: "触发垃圾回收"
                        Layout.fillWidth: true
                        font.pixelSize: 12
                        onClicked: {
                            gc()
                            console.log("垃圾回收已触发")
                        }
                    }
                }
            }

            // 性能信息
            GroupBox {
                title: "性能信息"
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: "FPS: " + fpsCounter.fps.toFixed(1)
                        font.pixelSize: 12
                    }

                    Label {
                        text: "渲染时间: " + fpsCounter.renderTime.toFixed(2) + "ms"
                        font.pixelSize: 12
                    }

                    Label {
                        text: "当前时间: " + new Date().toLocaleTimeString()
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    // FPS计数器
    Item {
        id: fpsCounter
        property real fps: 0
        property real renderTime: 0
        property int frameCount: 0
        property real lastTime: 0

        Timer {
            interval: 1000
            running: root.visible
            repeat: true
            onTriggered: {
                var currentTime = Date.now()
                if (fpsCounter.lastTime > 0) {
                    fpsCounter.fps = fpsCounter.frameCount / ((currentTime - fpsCounter.lastTime) / 1000)
                }
                fpsCounter.frameCount = 0
                fpsCounter.lastTime = currentTime
            }
        }

        Timer {
            interval: 16 // ~60fps
            running: root.visible
            repeat: true
            onTriggered: {
                var startTime = Date.now()
                fpsCounter.frameCount++
                fpsCounter.renderTime = Date.now() - startTime
            }
        }
    }

    // 公共方法
    function show() {
        root.visible = true
    }

    function hide() {
        root.visible = false
    }

    function toggle() {
        root.visible = !root.visible
    }

    function simulateEmailGeneration() {
        // 模拟邮箱生成
        var newEmail = {
            id: Date.now(),
            email_address: "test" + Date.now() + "@example.com",
            domain: "example.com",
            status: "active",
            created_at: new Date().toISOString(),
            tags: ["测试"],
            notes: "调试面板生成的测试邮箱"
        }

        if (root.globalState.emailList) {
            root.globalState.emailList.push(newEmail)
        }
    }

    function clearGlobalState() {
        root.globalState = {
            emailList: [],
            tagList: [],
            currentPage: 1,
            totalPages: 1,
            isLoading: false,
            selectedEmails: []
        }
    }
}
