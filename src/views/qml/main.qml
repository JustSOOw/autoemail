import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import EmailManager 1.0

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    minimumWidth: 1024
    minimumHeight: 768
    visible: true
    title: appName || "域名邮箱管理器"

    // Material Design主题
    Material.theme: Material.Light
    Material.primary: Material.Blue
    Material.accent: Material.Cyan

    // 应用程序状态
    property bool isConfigured: configController ? configController.isConfigured() : false
    property string currentDomain: emailController ? emailController.getCurrentDomain() : "未配置"
    property var statistics: emailController ? emailController.getStatistics() : ({})

    // 初始化
    Component.onCompleted: {
        console.log("应用程序启动完成")
        if (configController) {
            configController.loadConfig()
        }
        if (emailController) {
            emailController.refreshEmailList()
        }
    }
    
    // 主布局
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // 顶部工具栏
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: Material.primary

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10

                Label {
                    text: window.title
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                }

                Item { Layout.fillWidth: true }

                // 配置状态指示器
                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: window.isConfigured ? "#4CAF50" : "#F44336"

                    ToolTip.visible: configStatusArea.containsMouse
                    ToolTip.text: window.isConfigured ? "已配置" : "未配置"

                    MouseArea {
                        id: configStatusArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                Label {
                    text: window.currentDomain
                    color: "white"
                    font.pixelSize: 12
                }
            }
        }

        // 标签栏
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Material.background: "#FAFAFA"

            TabButton {
                text: "🏠 邮箱生成"
                font.pixelSize: 14
                width: implicitWidth
            }
            TabButton {
                text: "📋 邮箱管理"
                font.pixelSize: 14
                width: implicitWidth
            }
            TabButton {
                text: "🏷️ 标签管理"
                font.pixelSize: 14
                width: implicitWidth
            }
            TabButton {
                text: "⚙️ 配置管理"
                font.pixelSize: 14
                width: implicitWidth
            }
        }
        
        // 页面内容
        StackLayout {
            id: stackLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // 邮箱生成页面
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
                            spacing: 15

                            // 域名信息
                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: "📍 当前域名"
                                    font.bold: true
                                    font.pixelSize: 16
                                    color: "#333"
                                }

                                Label {
                                    id: domainLabel
                                    text: window.currentDomain
                                    font.pixelSize: 14
                                    color: window.isConfigured ? "#4CAF50" : "#F44336"
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#e0e0e0"
                            }

                            // 统计信息
                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: "📊 统计信息"
                                    font.bold: true
                                    font.pixelSize: 16
                                    color: "#333"
                                }

                                Label {
                                    text: "总邮箱数: " + (window.statistics.total_emails || 0)
                                    font.pixelSize: 14
                                    color: "#666"
                                }

                                Label {
                                    text: "今日创建: " + (window.statistics.today_created || 0)
                                    font.pixelSize: 14
                                    color: "#666"
                                }

                                Label {
                                    text: "活跃状态: " + (window.statistics.active_emails || 0)
                                    font.pixelSize: 14
                                    color: "#666"
                                }

                                Label {
                                    text: "成功率: " + (window.statistics.success_rate || 100) + "%"
                                    font.pixelSize: 14
                                    color: "#666"
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                    
                    // 中央操作区域
                    Rectangle {
                        Layout.preferredWidth: 320
                        Layout.fillHeight: true
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 20

                            Label {
                                text: "🎯 邮箱生成"
                                font.bold: true
                                font.pixelSize: 18
                                color: "#333"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // 生成模式选择
                            Column {
                                Layout.fillWidth: true
                                spacing: 10

                                Label {
                                    text: "生成模式:"
                                    font.pixelSize: 14
                                    color: "#666"
                                }

                                ButtonGroup {
                                    id: prefixTypeGroup
                                }

                                RadioButton {
                                    id: randomNameRadio
                                    text: "随机名字"
                                    checked: true
                                    ButtonGroup.group: prefixTypeGroup
                                }

                                RadioButton {
                                    id: randomStringRadio
                                    text: "随机字符串"
                                    ButtonGroup.group: prefixTypeGroup
                                }

                                RadioButton {
                                    id: customPrefixRadio
                                    text: "自定义前缀"
                                    ButtonGroup.group: prefixTypeGroup
                                }
                            }

                            // 自定义前缀输入
                            TextField {
                                id: customPrefixField
                                Layout.fillWidth: true
                                placeholderText: "输入自定义前缀..."
                                enabled: customPrefixRadio.checked
                                font.pixelSize: 14
                            }

                            // 标签输入
                            TextField {
                                id: tagsField
                                Layout.fillWidth: true
                                placeholderText: "标签 (用逗号分隔)..."
                                font.pixelSize: 14
                            }

                            // 生成按钮
                            Button {
                                id: generateButton
                                text: "🎯 生成新邮箱"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
                                font.pixelSize: 16
                                Material.background: Material.Blue
                                enabled: window.isConfigured

                                onClicked: {
                                    generateButton.enabled = false

                                    var prefixType = "random_name"
                                    if (randomStringRadio.checked) prefixType = "random_string"
                                    else if (customPrefixRadio.checked) prefixType = "custom"

                                    emailController.generateCustomEmail(
                                        prefixType,
                                        customPrefixField.text,
                                        tagsField.text
                                    )
                                }
                            }

                            // 进度条
                            ProgressBar {
                                id: progressBar
                                Layout.fillWidth: true
                                value: 0
                                visible: value > 0
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                    
                    // 右侧结果和日志区域
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 15

                            Label {
                                text: "📝 操作日志"
                                font.bold: true
                                font.pixelSize: 16
                                color: "#333"
                            }

                            // 最新生成的邮箱显示
                            Rectangle {
                                id: latestEmailCard
                                Layout.fillWidth: true
                                height: 80
                                color: "#f8f9fa"
                                radius: 6
                                border.color: "#e9ecef"
                                visible: latestEmailLabel.text !== ""

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 15

                                    Label {
                                        text: "✅ 最新生成的邮箱:"
                                        font.pixelSize: 12
                                        color: "#666"
                                    }

                                    Label {
                                        id: latestEmailLabel
                                        text: ""
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#2196F3"

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                // 复制到剪贴板的功能可以在这里实现
                                                console.log("复制邮箱地址:", latestEmailLabel.text)
                                            }
                                        }
                                    }
                                }
                            }

                            // 日志区域
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TextArea {
                                    id: logArea
                                    readOnly: true
                                    wrapMode: TextArea.Wrap
                                    font.family: "Consolas, Monaco, monospace"
                                    font.pixelSize: 12
                                    color: "#333"
                                    text: "[" + new Date().toLocaleTimeString() + "] 应用程序启动完成\n[" + new Date().toLocaleTimeString() + "] 等待用户操作..."

                                    function addLog(message) {
                                        var timestamp = new Date().toLocaleTimeString()
                                        text += "\n[" + timestamp + "] " + message
                                        // 自动滚动到底部
                                        cursorPosition = length
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 邮箱管理页面
            Rectangle {
                color: "#f5f5f5"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Label {
                        text: "📋 邮箱管理"
                        font.bold: true
                        font.pixelSize: 24
                        color: "#333"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: "此页面将显示所有生成的邮箱列表，支持搜索、筛选和管理功能。\n\n功能开发中，敬请期待..."
                        font.pixelSize: 16
                        color: "#666"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // 标签管理页面
            Rectangle {
                color: "#f5f5f5"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Label {
                        text: "🏷️ 标签管理"
                        font.bold: true
                        font.pixelSize: 24
                        color: "#333"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: "此页面将提供标签的创建、编辑、删除和管理功能。\n\n功能开发中，敬请期待..."
                        font.pixelSize: 16
                        color: "#666"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // 配置管理页面
            Rectangle {
                color: "#f5f5f5"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Label {
                        text: "⚙️ 配置管理"
                        font.bold: true
                        font.pixelSize: 24
                        color: "#333"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // 域名配置区域
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 15

                            Label {
                                text: "🌐 域名配置"
                                font.bold: true
                                font.pixelSize: 18
                                color: "#333"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                TextField {
                                    id: domainField
                                    Layout.fillWidth: true
                                    placeholderText: "请输入域名 (例如: example.com)"
                                    font.pixelSize: 14
                                    text: window.currentDomain !== "未配置" ? window.currentDomain : ""
                                }

                                Button {
                                    text: "🔍 验证"
                                    Material.background: Material.Orange

                                    onClicked: {
                                        if (configController && domainField.text.trim()) {
                                            configController.validateDomain(domainField.text.trim())
                                        }
                                    }
                                }

                                Button {
                                    text: "💾 保存"
                                    Material.background: Material.Green

                                    onClicked: {
                                        if (configController && domainField.text.trim()) {
                                            configController.setDomain(domainField.text.trim())
                                        }
                                    }
                                }
                            }

                            Label {
                                id: domainStatusLabel
                                text: window.isConfigured ? "✅ 域名已配置" : "❌ 请配置域名"
                                font.pixelSize: 14
                                color: window.isConfigured ? "#4CAF50" : "#F44336"
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    Label {
                        text: "更多配置选项开发中，敬请期待..."
                        font.pixelSize: 14
                        color: "#666"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }

    // 状态栏
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 32
        color: "#f8f9fa"
        border.color: "#e9ecef"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 15

            Label {
                id: statusLabel
                text: "就绪"
                font.pixelSize: 12
                color: "#333"
            }

            Rectangle {
                width: 1
                height: 16
                color: "#dee2e6"
            }

            Label {
                text: "域名: " + window.currentDomain
                font.pixelSize: 12
                color: "#666"
            }

            Rectangle {
                width: 1
                height: 16
                color: "#dee2e6"
            }

            Label {
                text: "邮箱总数: " + (window.statistics.total_emails || 0)
                font.pixelSize: 12
                color: "#666"
            }

            Item { Layout.fillWidth: true }

            Label {
                id: timeLabel
                text: new Date().toLocaleTimeString()
                font.pixelSize: 12
                color: "#666"

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: timeLabel.text = new Date().toLocaleTimeString()
                }
            }
        }
    }

    // 连接邮箱控制器信号
    Connections {
        target: emailController

        function onEmailGenerated(email, status, message) {
            if (status === "success") {
                latestEmailLabel.text = email
                logArea.addLog("✅ " + message)
                // 更新统计信息
                window.statistics = emailController.getStatistics()
            } else {
                logArea.addLog("❌ " + message)
            }
            generateButton.enabled = true
        }

        function onStatusChanged(message) {
            statusLabel.text = message
            logArea.addLog("ℹ️ " + message)
        }

        function onProgressChanged(value) {
            progressBar.value = value / 100.0
        }

        function onVerificationCodeReceived(email, code) {
            logArea.addLog("📧 验证码 (" + email + "): " + code)
        }

        function onErrorOccurred(errorType, errorMessage) {
            logArea.addLog("❌ " + errorType + ": " + errorMessage)
        }

        function onStatisticsUpdated(stats) {
            window.statistics = stats
        }
    }

    // 连接配置控制器信号
    Connections {
        target: configController

        function onConfigLoaded(configData) {
            window.currentDomain = configData.domain || "未配置"
            window.isConfigured = configData.is_configured || false
            logArea.addLog("⚙️ 配置加载完成")
        }

        function onConfigSaved(success, message) {
            if (success) {
                logArea.addLog("✅ " + message)
                // 重新加载配置状态
                window.currentDomain = configController.getCurrentDomain()
                window.isConfigured = configController.isConfigured()
            } else {
                logArea.addLog("❌ " + message)
            }
        }

        function onDomainValidated(isValid, message) {
            domainStatusLabel.text = isValid ? "✅ " + message : "❌ " + message
            domainStatusLabel.color = isValid ? "#4CAF50" : "#F44336"
            logArea.addLog((isValid ? "✅ " : "❌ ") + "域名验证: " + message)
        }

        function onStatusChanged(message) {
            statusLabel.text = message
        }

        function onErrorOccurred(errorType, errorMessage) {
            logArea.addLog("❌ " + errorType + ": " + errorMessage)
        }
    }
}