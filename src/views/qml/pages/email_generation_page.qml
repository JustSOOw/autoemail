/*
 * 邮箱申请页面
 * 提供邮箱生成功能，包括不同的生成模式和实时日志显示
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: root
    color: "#f5f5f5"

    // 对外暴露的属性
    property bool isConfigured: false
    property string currentDomain: "未配置"
    property var statistics: ({})

    // 对外暴露的信号
    signal statusChanged(string message)
    signal logMessage(string message)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 左侧配置信息面板
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
                        text: root.currentDomain
                        font.pixelSize: 14
                        color: root.isConfigured ? "#4CAF50" : "#F44336"
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
                        text: "总邮箱数: " + (root.statistics.total_emails || 0)
                        font.pixelSize: 14
                        color: "#666"
                    }

                    Label {
                        text: "今日创建: " + (root.statistics.today_created || 0)
                        font.pixelSize: 14
                        color: "#666"
                    }

                    Label {
                        text: "活跃状态: " + (root.statistics.active_emails || 0)
                        font.pixelSize: 14
                        color: "#666"
                    }

                    Label {
                        text: "成功率: " + (root.statistics.success_rate || 100) + "%"
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

                // 备注输入
                TextField {
                    id: notesField
                    Layout.fillWidth: true
                    placeholderText: "备注信息..."
                    font.pixelSize: 14
                }

                // 批量生成选项
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CheckBox {
                        id: batchModeCheckBox
                        text: "批量生成"
                        font.pixelSize: 14
                    }

                    SpinBox {
                        id: batchCountSpinBox
                        from: 1
                        to: 100
                        value: 5
                        enabled: batchModeCheckBox.checked
                        suffix: " 个"
                    }
                }

                // 生成按钮
                Button {
                    id: generateButton
                    text: batchModeCheckBox.checked ? "🎯 批量生成邮箱" : "🎯 生成新邮箱"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    font.pixelSize: 16
                    Material.background: Material.Blue
                    enabled: root.isConfigured && !isGenerating

                    property bool isGenerating: false

                    onClicked: {
                        isGenerating = true

                        var prefixType = "random_name"
                        if (randomStringRadio.checked) prefixType = "random_string"
                        else if (customPrefixRadio.checked) prefixType = "custom"

                        var tags = tagsField.text.split(",").map(function(tag) {
                            return tag.trim()
                        }).filter(function(tag) {
                            return tag.length > 0
                        })

                        // 调用控制器方法
                        if (emailController) {
                            if (batchModeCheckBox.checked) {
                                // 批量生成
                                emailController.batchGenerateEmails(
                                    batchCountSpinBox.value,
                                    prefixType,
                                    customPrefixField.text,
                                    tags,
                                    notesField.text
                                )
                            } else {
                                // 单个生成
                                emailController.generateCustomEmail(
                                    prefixType,
                                    customPrefixField.text,
                                    tagsField.text,
                                    notesField.text
                                )
                            }
                        }
                    }
                }

                // 进度条
                ProgressBar {
                    id: progressBar
                    Layout.fillWidth: true
                    value: 0
                    visible: value > 0
                }

                // 快速操作区域
                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    color: "#f8f9fa"
                    radius: 6
                    border.color: "#e9ecef"
                    visible: !generateButton.isGenerating

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Label {
                            text: "⚡ 快速操作"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#666"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Button {
                                text: "📧 测试邮箱"
                                font.pixelSize: 10
                                implicitHeight: 28
                                Layout.fillWidth: true
                                enabled: latestEmailLabel.text !== ""
                                onClicked: {
                                    if (emailController && latestEmailLabel.text) {
                                        emailController.getVerificationCode(latestEmailLabel.text)
                                    }
                                }
                            }

                            Button {
                                text: "📋 复制"
                                font.pixelSize: 10
                                implicitHeight: 28
                                Layout.fillWidth: true
                                enabled: latestEmailLabel.text !== ""
                                onClicked: {
                                    // 复制到剪贴板
                                    console.log("复制邮箱:", latestEmailLabel.text)
                                    root.logMessage("📋 邮箱地址已复制")
                                }
                            }

                            Button {
                                text: "🔄 重置"
                                font.pixelSize: 10
                                implicitHeight: 28
                                Layout.fillWidth: true
                                onClicked: clearInputs()
                            }
                        }
                    }
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
                                    // 复制到剪贴板的功能
                                    console.log("复制邮箱地址:", latestEmailLabel.text)
                                    root.logMessage("📋 邮箱地址已复制到剪贴板")
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
                        text: "[" + new Date().toLocaleTimeString() + "] 邮箱生成页面已加载\n[" + new Date().toLocaleTimeString() + "] 等待用户操作..."

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

    // 内部方法
    function updateLatestEmail(email) {
        latestEmailLabel.text = email
    }

    function updateProgress(value) {
        progressBar.value = value / 100.0
    }

    function addLogMessage(message) {
        logArea.addLog(message)
    }

    function enableGenerateButton() {
        generateButton.isGenerating = false
    }

    function disableGenerateButton() {
        generateButton.isGenerating = true
    }

    // 批量生成结果处理
    function handleBatchResult(result) {
        if (result.success > 0) {
            addLogMessage("✅ 批量生成成功: " + result.success + " 个邮箱")
            if (result.emails && result.emails.length > 0) {
                updateLatestEmail(result.emails[0].email_address)
            }
        }
        if (result.failed > 0) {
            addLogMessage("❌ 生成失败: " + result.failed + " 个邮箱")
        }
        if (result.errors && result.errors.length > 0) {
            result.errors.forEach(function(error) {
                addLogMessage("❌ 错误: " + error)
            })
        }
    }

    // 验证输入
    function validateInput() {
        if (!root.isConfigured) {
            addLogMessage("❌ 请先完成域名配置")
            return false
        }

        if (customPrefixRadio.checked && customPrefixField.text.trim().length === 0) {
            addLogMessage("❌ 请输入自定义前缀")
            return false
        }

        return true
    }

    // 清空输入字段
    function clearInputs() {
        customPrefixField.text = ""
        tagsField.text = ""
        notesField.text = ""
        randomNameRadio.checked = true
    }
}
