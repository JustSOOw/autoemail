import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    visible: true
    title: "域名邮箱管理器"
    
    // Material Design主题
    Material.theme: Material.Light
    Material.primary: Material.Blue
    Material.accent: Material.Cyan
    
    // 主布局
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        
        // 标签栏
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            TabButton {
                text: "🏠 邮箱申请"
                font.pixelSize: 14
            }
            TabButton {
                text: "📋 邮箱管理"
                font.pixelSize: 14
            }
            TabButton {
                text: "⚙️ 配置管理"
                font.pixelSize: 14
            }
        }
        
        // 页面内容
        StackLayout {
            id: stackLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex
            
            // 邮箱申请页面
            Rectangle {
                color: "#f5f5f5"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20
                    
                    // 左侧配置信息
                    Rectangle {
                        Layout.preferredWidth: 250
                        Layout.fillHeight: true
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            
                            Label {
                                text: "📍 当前域名"
                                font.bold: true
                                font.pixelSize: 16
                            }
                            
                            Label {
                                id: domainLabel
                                text: emailController.getCurrentDomain()
                                font.pixelSize: 14
                                color: "#666"
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#e0e0e0"
                                Layout.topMargin: 10
                                Layout.bottomMargin: 10
                            }
                            
                            Label {
                                text: "📊 统计信息"
                                font.bold: true
                                font.pixelSize: 16
                            }
                            
                            Label {
                                text: "今日生成: 0"
                                font.pixelSize: 14
                                color: "#666"
                            }
                            
                            Label {
                                text: "成功率: 100%"
                                font.pixelSize: 14
                                color: "#666"
                            }
                            
                            Item { Layout.fillHeight: true }
                        }
                    }
                    
                    // 中央操作区域
                    Rectangle {
                        Layout.preferredWidth: 300
                        Layout.fillHeight: true
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 20
                            
                            Button {
                                id: generateButton
                                text: "🎯 生成新邮箱"
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 50
                                font.pixelSize: 16
                                Material.background: Material.Blue
                                
                                onClicked: {
                                    generateButton.enabled = false
                                    emailController.generateEmail()
                                }
                            }
                            
                            ProgressBar {
                                id: progressBar
                                Layout.preferredWidth: 200
                                value: 0
                                visible: value > 0
                            }
                            
                            Button {
                                text: "📧 获取验证码"
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 40
                                enabled: false
                                
                                onClicked: {
                                    emailController.getVerificationCode("test@example.com")
                                }
                            }
                        }
                    }
                    
                    // 右侧日志区域
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            
                            Label {
                                text: "📝 实时日志"
                                font.bold: true
                                font.pixelSize: 16
                            }
                            
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                TextArea {
                                    id: logArea
                                    readOnly: true
                                    wrapMode: TextArea.Wrap
                                    font.family: "Consolas, Monaco, monospace"
                                    font.pixelSize: 12
                                    text: "[12:34:56] 应用程序启动\n[12:34:57] 等待用户操作..."
                                }
                            }
                        }
                    }
                }
            }
            
            // 邮箱管理页面
            Rectangle {
                color: "#f5f5f5"
                
                Label {
                    anchors.centerIn: parent
                    text: "📋 邮箱管理页面\n\n功能开发中..."
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            // 配置管理页面
            Rectangle {
                color: "#f5f5f5"
                
                Label {
                    anchors.centerIn: parent
                    text: "⚙️ 配置管理页面\n\n功能开发中..."
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
    
    // 状态栏
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 30
        color: "#f0f0f0"
        border.color: "#e0e0e0"
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 5
            
            Label {
                id: statusLabel
                text: "就绪"
                font.pixelSize: 12
            }
            
            Item { Layout.fillWidth: true }
            
            Label {
                text: new Date().toLocaleTimeString()
                font.pixelSize: 12
                color: "#666"
            }
        }
    }
    
    // 连接信号
    Connections {
        target: emailController
        
        function onEmailGenerated(email, status) {
            if (status === "success") {
                logArea.text += "\n[" + new Date().toLocaleTimeString() + "] 邮箱生成成功: " + email
            } else {
                logArea.text += "\n[" + new Date().toLocaleTimeString() + "] 邮箱生成失败"
            }
            generateButton.enabled = true
        }
        
        function onStatusChanged(message) {
            statusLabel.text = message
            logArea.text += "\n[" + new Date().toLocaleTimeString() + "] " + message
        }
        
        function onProgressChanged(value) {
            progressBar.value = value / 100.0
        }
        
        function onVerificationCodeReceived(code) {
            logArea.text += "\n[" + new Date().toLocaleTimeString() + "] 验证码: " + code
        }
    }
}