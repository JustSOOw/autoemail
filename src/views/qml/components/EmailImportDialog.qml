/*
 * 邮箱数据导入对话框组件
 * 提供文件选择、格式验证、冲突处理策略选择等功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Dialog {
    id: root

    // ==================== 自定义属性 ====================
    
    property string selectedFilePath: ""
    property bool isImporting: false
    property real importProgress: 0.0
    property string importStatus: "准备导入..."
    property var importResult: null
    
    // 导入选项
    property string conflictStrategy: "skip"
    property bool validateEmails: true
    property bool importTags: true
    property bool importMetadata: false
    
    // ==================== 基础设置 ====================
    
    title: "导入邮箱数据"
    modal: true
    width: 600
    height: 500
    anchors.centerIn: parent
    
    // ==================== 信号 ====================

    signal importRequested(string filePath, string format, var options)
    signal importCancelled()
    signal previewRequested(string filePath, string format)
    signal fileSelectionRequested()  // 请求文件选择
    
    // ==================== 主要内容 ====================
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 文件选择区域
        GroupBox {
            title: "📁 选择导入文件"
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 15

                RowLayout {
                    Layout.fillWidth: true

                    TextField {
                        id: filePathField
                        Layout.fillWidth: true
                        placeholderText: "请选择要导入的邮箱数据文件..."
                        readOnly: true
                        text: getDisplayPath(root.selectedFilePath)
                    }

                    Button {
                        text: "浏览..."
                        Material.background: Material.Blue
                        onClicked: root.fileSelectionRequested()
                    }
                }

                // 文件信息显示
                Rectangle {
                    Layout.fillWidth: true
                    height: fileInfoColumn.height + 20
                    color: "#f5f5f5"
                    radius: 8
                    visible: root.selectedFilePath !== ""

                    ColumnLayout {
                        id: fileInfoColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 5

                        Label {
                            text: "文件信息:"
                            font.bold: true
                            font.pixelSize: 12
                        }

                        Label {
                            text: "格式: " + getFileFormat(root.selectedFilePath)
                            font.pixelSize: 11
                            color: "#666"
                        }

                        Label {
                            text: "大小: " + getFileSize(root.selectedFilePath)
                            font.pixelSize: 11
                            color: "#666"
                        }
                    }
                }

                Label {
                    text: "💡 支持的格式: JSON (.json), CSV (.csv), Excel (.xlsx)"
                    font.pixelSize: 12
                    color: "#666"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }

        // 导入选项
        GroupBox {
            title: "⚙️ 导入选项"
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 15

                // 冲突处理策略
                ColumnLayout {
                    spacing: 8

                    Label {
                        text: "冲突处理策略:"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    ComboBox {
                        id: conflictStrategyCombo
                        Layout.fillWidth: true
                        model: [
                            {text: "跳过重复邮箱 (推荐)", value: "skip", description: "遇到重复邮箱时跳过，不影响其他数据"},
                            {text: "更新现有邮箱", value: "update", description: "用导入数据更新现有邮箱信息"},
                            {text: "报错停止导入", value: "error", description: "遇到重复邮箱时停止整个导入过程"}
                        ]
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: 0
                        
                        onCurrentIndexChanged: {
                            root.conflictStrategy = model[currentIndex].value
                        }
                    }

                    Label {
                        text: conflictStrategyCombo.model[conflictStrategyCombo.currentIndex].description
                        font.pixelSize: 11
                        color: "#666"
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                // 其他选项
                ColumnLayout {
                    spacing: 8

                    CheckBox {
                        id: validateEmailsCheck
                        text: "验证邮箱格式"
                        checked: root.validateEmails
                        onCheckedChanged: root.validateEmails = checked
                    }

                    CheckBox {
                        id: importTagsCheck
                        text: "导入标签信息"
                        checked: root.importTags
                        onCheckedChanged: root.importTags = checked
                    }

                    CheckBox {
                        id: importMetadataCheck
                        text: "导入元数据信息"
                        checked: root.importMetadata
                        onCheckedChanged: root.importMetadata = checked
                    }
                }
            }
        }

        // 进度显示区域
        Rectangle {
            Layout.fillWidth: true
            height: progressColumn.height + 20
            color: "#e3f2fd"
            radius: 8
            visible: root.isImporting

            ColumnLayout {
                id: progressColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10

                Label {
                    text: "导入进度"
                    font.bold: true
                    font.pixelSize: 14
                }

                ProgressBar {
                    Layout.fillWidth: true
                    value: root.importProgress
                    indeterminate: root.importProgress === 0
                }

                Label {
                    text: root.importStatus
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 12
                }
            }
        }

        // 预览按钮
        Button {
            text: "🔍 预览数据"
            Layout.alignment: Qt.AlignHCenter
            visible: root.selectedFilePath !== "" && !root.isImporting
            onClicked: {
                var format = getFileFormat(root.selectedFilePath)
                root.previewRequested(root.selectedFilePath, format)
            }
        }

        Item { Layout.fillHeight: true }

        // 按钮区域
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 15

            Button {
                text: "取消"
                enabled: !root.isImporting
                onClicked: {
                    if (root.isImporting) {
                        root.importCancelled()
                    }
                    root.close()
                }
            }

            Button {
                text: root.isImporting ? "导入中..." : "开始导入"
                Material.background: Material.Green
                enabled: !root.isImporting && root.selectedFilePath !== ""
                onClicked: startImport()
            }
        }
    }

    // ==================== 文件选择处理 ====================

    // 文件选择通过后端Python代码处理，避免QML模块兼容性问题

    // ==================== 内部方法 ====================
    
    function startImport() {
        if (root.selectedFilePath === "") {
            return
        }

        var format = getFileFormat(root.selectedFilePath)
        var options = {
            conflictStrategy: root.conflictStrategy,
            validateEmails: root.validateEmails,
            importTags: root.importTags,
            importMetadata: root.importMetadata
        }

        root.isImporting = true
        root.importProgress = 0
        root.importStatus = "正在解析文件..."

        root.importRequested(root.selectedFilePath, format, options)
    }

    function getFileFormat(filePath) {
        if (!filePath) return "unknown"
        
        var lowerPath = filePath.toLowerCase()
        if (lowerPath.endsWith(".json")) return "json"
        if (lowerPath.endsWith(".csv")) return "csv"
        if (lowerPath.endsWith(".xlsx")) return "xlsx"
        return "unknown"
    }

    function getDisplayPath(filePath) {
        if (!filePath) return ""
        
        // 只显示文件名，不显示完整路径
        var parts = filePath.split(/[/\\]/)
        return parts[parts.length - 1]
    }

    function getFileSize(filePath) {
        // 这里应该从后端获取文件大小，暂时返回占位符
        return "计算中..."
    }

    function resetDialog() {
        root.selectedFilePath = ""
        root.isImporting = false
        root.importProgress = 0
        root.importStatus = "准备导入..."
        root.importResult = null
        
        // 重置选项为默认值
        conflictStrategyCombo.currentIndex = 0
        validateEmailsCheck.checked = true
        importTagsCheck.checked = true
        importMetadataCheck.checked = false
    }

    // 当对话框关闭时重置状态
    onClosed: resetDialog()
}
