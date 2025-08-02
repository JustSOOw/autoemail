/*
 * 配置管理页面
 * 提供域名配置、安全设置、系统配置等功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import "../components"

Rectangle {
    id: root
    color: "#f5f5f5"

    // 对外暴露的属性
    property bool isConfigured: false
    property string currentDomain: "未配置"
    property var configData: ({})

    // 对外暴露的信号
    signal validateDomain(string domain)
    signal saveDomain(string domain)
    signal saveConfig(var config)
    signal resetConfig()
    signal exportConfig()
    signal importConfig(string configJson)

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 20
            Layout.fillWidth: true

            // 页面标题
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
                Layout.preferredHeight: 280
                Layout.minimumHeight: 280
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
                            text: root.currentDomain !== "未配置" ? root.currentDomain : ""

                            // 实时验证域名格式
                            property bool isValidFormat: {
                                var domain = text.trim()
                                if (domain.length === 0) return false

                                // 简单的域名格式验证
                                var domainRegex = /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.([a-zA-Z]{2,}\.)*[a-zA-Z]{2,}$/
                                return domainRegex.test(domain)
                            }

                            color: text.length > 0 ? (isValidFormat ? "#333" : "#F44336") : "#333"
                        }

                        Button {
                            text: "🔍 验证"
                            Material.background: Material.Orange
                            enabled: domainField.isValidFormat && !isValidating

                            property bool isValidating: false

                            onClicked: {
                                if (domainField.text.trim()) {
                                    isValidating = true
                                    root.validateDomain(domainField.text.trim())
                                }
                            }
                        }

                        Button {
                            text: "💾 保存"
                            Material.background: Material.Green
                            enabled: domainField.isValidFormat
                            onClicked: {
                                if (domainField.text.trim()) {
                                    root.saveDomain(domainField.text.trim())
                                }
                            }
                        }
                    }

                    // 域名格式提示
                    Label {
                        visible: domainField.text.length > 0 && !domainField.isValidFormat
                        text: "⚠️ 域名格式不正确，请输入有效的域名"
                        font.pixelSize: 12
                        color: "#F44336"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        id: domainStatusLabel
                        text: root.isConfigured ? "✅ 域名已配置" : "❌ 请配置域名"
                        font.pixelSize: 14
                        color: root.isConfigured ? "#4CAF50" : "#F44336"
                    }

                    // 域名配置说明
                    Rectangle {
                        Layout.fillWidth: true
                        height: 60
                        color: "#f8f9fa"
                        radius: 4
                        border.color: "#e9ecef"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 5

                            Label {
                                text: "💡 配置说明"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#666"
                            }

                            Label {
                                text: "请确保域名已在Cloudflare托管，并配置了相应的DNS记录。验证成功后即可开始使用邮箱生成功能。"
                                font.pixelSize: 11
                                color: "#666"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // 安全配置区域
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 320
                Layout.minimumHeight: 320
                color: "white"
                radius: 8
                border.color: "#e0e0e0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    Label {
                        text: "🔒 安全配置"
                        font.bold: true
                        font.pixelSize: 18
                        color: "#333"
                    }

                    CheckBox {
                        id: encryptDataCheckBox
                        text: "加密敏感数据"
                        checked: root.configData.encrypt_sensitive_data || true
                        font.pixelSize: 14

                        ToolTip.text: "启用后将对配置文件中的敏感信息进行AES加密存储"
                        ToolTip.visible: hovered
                    }

                    CheckBox {
                        id: autoLockCheckBox
                        text: "启用自动锁定"
                        checked: root.configData.auto_lock_enabled || false
                        font.pixelSize: 14

                        ToolTip.text: "在指定时间内无操作时自动锁定应用程序"
                        ToolTip.visible: hovered
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: autoLockCheckBox.checked

                        Label {
                            text: "自动锁定时间:"
                            font.pixelSize: 14
                            color: autoLockCheckBox.checked ? "#666" : "#ccc"
                        }

                        RowLayout {
                            SpinBox {
                                id: autoLockTimeSpinBox
                                from: 5
                                to: 120
                                value: root.configData.auto_lock_timeout || 30
                            }

                            Label {
                                text: "分钟"
                                font.pixelSize: 14
                                color: "#666"
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            text: "日志级别:"
                            font.pixelSize: 14
                            color: "#666"
                        }

                        ComboBox {
                            id: logLevelComboBox
                            model: ["DEBUG", "INFO", "WARNING", "ERROR"]
                            currentIndex: {
                                var level = root.configData.log_level || "INFO"
                                return model.indexOf(level)
                            }

                            ToolTip.text: "设置应用程序的日志记录级别"
                            ToolTip.visible: hovered
                        }
                    }

                    // 数据备份选项
                    CheckBox {
                        id: autoBackupCheckBox
                        text: "自动备份数据"
                        checked: root.configData.auto_backup_enabled || false
                        font.pixelSize: 14

                        ToolTip.text: "定期自动备份邮箱数据和配置信息"
                        ToolTip.visible: hovered
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: autoBackupCheckBox.checked

                        Label {
                            text: "备份间隔:"
                            font.pixelSize: 14
                            color: autoBackupCheckBox.checked ? "#666" : "#ccc"
                        }

                        ComboBox {
                            id: backupIntervalCombo
                            model: ["每天", "每周", "每月"]
                            currentIndex: 1
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // 系统配置区域
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                Layout.minimumHeight: 280
                color: "white"
                radius: 8
                border.color: "#e0e0e0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    Label {
                        text: "🖥️ 系统配置"
                        font.bold: true
                        font.pixelSize: 18
                        color: "#333"
                    }

                    CheckBox {
                        id: showNotificationsCheckBox
                        text: "显示通知"
                        checked: root.configData.show_notifications || true
                        font.pixelSize: 14

                        ToolTip.text: "显示系统通知消息"
                        ToolTip.visible: hovered
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // 操作按钮区域
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                Layout.minimumHeight: 120
                color: "white"
                radius: 8
                border.color: "#e0e0e0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    Label {
                        text: "🛠️ 配置操作"
                        font.bold: true
                        font.pixelSize: 18
                        color: "#333"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        Button {
                            text: "💾 保存配置"
                            Material.background: Material.Blue
                            Layout.preferredWidth: 120
                            onClicked: saveAllConfig()
                        }

                        Button {
                            text: "🔄 重置配置"
                            Material.background: Material.Orange
                            Layout.preferredWidth: 120
                            onClicked: resetConfirmDialog.open()
                        }

                        Button {
                            text: "📤 导出配置"
                            Material.background: Material.Green
                            Layout.preferredWidth: 120
                            onClicked: root.exportConfig()
                        }

                        Button {
                            text: "📥 导入配置"
                            Material.background: Material.Purple
                            Layout.preferredWidth: 120
                            onClicked: importFileDialog.open()
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // 重置确认对话框
    Dialog {
        id: resetConfirmDialog
        title: "确认重置"
        modal: true
        anchors.centerIn: parent

        ColumnLayout {
            spacing: 20

            Label {
                text: "确定要重置所有配置到默认值吗？\n此操作不可撤销。"
                wrapMode: Text.WordWrap
                Layout.preferredWidth: 300
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: resetConfirmDialog.close()
                }

                Button {
                    text: "重置"
                    Material.background: Material.Red
                    onClicked: {
                        root.resetConfig()
                        resetConfirmDialog.close()
                    }
                }
            }
        }
    }

    // 导入文件对话框（简化版本）
    Dialog {
        id: importFileDialog
        title: "导入配置"
        modal: true
        anchors.centerIn: parent
        width: 400

        ColumnLayout {
            spacing: 15
            width: parent.width

            Label {
                text: "请粘贴配置JSON内容:"
                font.pixelSize: 14
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 200

                TextArea {
                    id: importTextArea
                    placeholderText: "粘贴配置JSON内容..."
                    wrapMode: TextArea.Wrap
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: {
                        importTextArea.text = ""
                        importFileDialog.close()
                    }
                }

                Button {
                    text: "导入"
                    Material.background: Material.Blue
                    enabled: importTextArea.text.trim().length > 0
                    onClicked: {
                        root.importConfig(importTextArea.text.trim())
                        importTextArea.text = ""
                        importFileDialog.close()
                    }
                }
            }
        }
    }

    // 内部方法
    function saveAllConfig() {
        // 验证配置
        if (!validateConfiguration()) {
            return
        }

        var config = {
            // 域名配置
            domain: domainField.text.trim(),

            // 安全配置
            encrypt_sensitive_data: encryptDataCheckBox.checked,
            auto_lock_enabled: autoLockCheckBox.checked,
            auto_lock_timeout: autoLockTimeSpinBox.value,
            log_level: logLevelComboBox.currentText,
            auto_backup_enabled: autoBackupCheckBox.checked,
            backup_interval: backupIntervalCombo.currentText,

            // 系统配置
            show_notifications: showNotificationsCheckBox.checked
        }

        root.saveConfig(config)
    }

    function validateConfiguration() {
        // 验证域名格式
        if (domainField.text.trim().length > 0 && !domainField.isValidFormat) {
            globalStatusMessage.showError("域名格式不正确")
            return false
        }

        // 验证自动锁定时间
        if (autoLockCheckBox.checked && (autoLockTimeSpinBox.value < 5 || autoLockTimeSpinBox.value > 120)) {
            globalStatusMessage.showError("自动锁定时间必须在5-120分钟之间")
            return false
        }

        return true
    }

    function updateDomainStatus(isValid, message) {
        domainStatusLabel.text = (isValid ? "✅ " : "❌ ") + message
        domainStatusLabel.color = isValid ? "#4CAF50" : "#F44336"
    }

    function loadConfigData(config) {
        root.configData = config

        // 更新UI控件
        if (config.domain) {
            domainField.text = config.domain
        }

        // 安全配置
        encryptDataCheckBox.checked = config.encrypt_sensitive_data !== undefined ? config.encrypt_sensitive_data : true
        autoLockCheckBox.checked = config.auto_lock_enabled || false
        autoLockTimeSpinBox.value = config.auto_lock_timeout || 30
        autoBackupCheckBox.checked = config.auto_backup_enabled || false

        var logLevelIndex = logLevelComboBox.model.indexOf(config.log_level || "INFO")
        if (logLevelIndex >= 0) {
            logLevelComboBox.currentIndex = logLevelIndex
        }

        var backupIntervalIndex = backupIntervalCombo.model.indexOf(config.backup_interval || "每周")
        if (backupIntervalIndex >= 0) {
            backupIntervalCombo.currentIndex = backupIntervalIndex
        }

        // 系统配置
        showNotificationsCheckBox.checked = config.show_notifications !== undefined ? config.show_notifications : true
    }

    function resetToDefaults() {
        // 重置所有配置到默认值
        domainField.text = ""
        encryptDataCheckBox.checked = true
        autoLockCheckBox.checked = false
        autoLockTimeSpinBox.value = 30
        autoBackupCheckBox.checked = false
        logLevelComboBox.currentIndex = 1 // INFO
        backupIntervalCombo.currentIndex = 1 // 每周
        showNotificationsCheckBox.checked = true
    }
}
