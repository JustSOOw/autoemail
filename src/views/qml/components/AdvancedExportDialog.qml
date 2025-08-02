/*
 * 高级导出对话框组件
 * 支持多格式导出、预览、进度显示、任务管理等功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

Dialog {
    id: root

    // ==================== 自定义属性 ====================
    
    property var exportData: []
    property string exportType: "emails" // emails, tags, statistics
    property bool isExporting: false
    property real exportProgress: 0.0
    property string currentTask: ""
    property var exportHistory: []
    
    // ==================== 基础设置 ====================
    
    title: "高级数据导出"
    modal: true
    width: 600
    height: 500
    anchors.centerIn: parent
    
    // ==================== 信号 ====================
    
    signal exportRequested(var options)
    signal exportCancelled()
    signal previewRequested(var options)

    // ==================== 主要内容 ====================
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.md
        spacing: DesignSystem.spacing.md

        // 标题区域
        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: "📤 数据导出"
                font.pixelSize: DesignSystem.typography.headline.medium
                font.weight: DesignSystem.typography.weight.semiBold
                color: ThemeManager.colors.onSurface
            }
            
            Item { Layout.fillWidth: true }
            
            Label {
                text: "共 " + root.exportData.length + " 条记录"
                font.pixelSize: DesignSystem.typography.body.small
                color: ThemeManager.colors.onSurfaceVariant
            }
        }

        // 导出选项卡
        TabBar {
            id: exportTabBar
            Layout.fillWidth: true
            
            TabButton {
                text: "格式选择"
                width: implicitWidth
            }
            
            TabButton {
                text: "字段配置"
                width: implicitWidth
            }
            
            TabButton {
                text: "预览"
                width: implicitWidth
            }
        }

        // 选项卡内容
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: exportTabBar.currentIndex

            // 格式选择页面
            ScrollView {
                ColumnLayout {
                    width: parent.width
                    spacing: DesignSystem.spacing.md

                    // 导出格式
                    GroupBox {
                        Layout.fillWidth: true
                        title: "导出格式"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: DesignSystem.spacing.sm
                            
                            property string selectedFormat: "csv"
                            
                            Repeater {
                                model: [
                                    {format: "csv", name: "CSV (逗号分隔)", desc: "适用于Excel和数据分析", icon: "📊"},
                                    {format: "json", name: "JSON", desc: "适用于程序处理和API", icon: "🔧"},
                                    {format: "xlsx", name: "Excel", desc: "适用于Office办公", icon: "📈"},
                                    {format: "pdf", name: "PDF", desc: "适用于打印和分享", icon: "📄"}
                                ]
                                
                                RadioButton {
                                    Layout.fillWidth: true
                                    text: modelData.icon + " " + modelData.name
                                    checked: parent.selectedFormat === modelData.format
                                    
                                    contentItem: ColumnLayout {
                                        anchors.left: parent.indicator.right
                                        anchors.leftMargin: DesignSystem.spacing.sm
                                        
                                        Label {
                                            text: modelData.icon + " " + modelData.name
                                            font.pixelSize: DesignSystem.typography.body.medium
                                            font.weight: DesignSystem.typography.weight.medium
                                            color: ThemeManager.colors.onSurface
                                        }
                                        
                                        Label {
                                            text: modelData.desc
                                            font.pixelSize: DesignSystem.typography.label.small
                                            color: ThemeManager.colors.onSurfaceVariant
                                        }
                                    }
                                    
                                    onClicked: parent.selectedFormat = modelData.format
                                }
                            }
                        }
                    }

                    // 导出选项
                    GroupBox {
                        Layout.fillWidth: true
                        title: "导出选项"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: DesignSystem.spacing.sm
                            
                            CheckBox {
                                id: includeHeadersCheck
                                text: "包含列标题"
                                checked: true
                            }
                            
                            CheckBox {
                                id: includeMetadataCheck
                                text: "包含元数据（创建时间、修改时间等）"
                                checked: false
                            }
                            
                            CheckBox {
                                id: compressCheck
                                text: "压缩导出文件"
                                checked: false
                                visible: parent.parent.selectedFormat !== "pdf"
                            }
                        }
                    }

                    // 文件设置
                    GroupBox {
                        Layout.fillWidth: true
                        title: "文件设置"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: DesignSystem.spacing.sm
                            
                            RowLayout {
                                Layout.fillWidth: true
                                
                                Label {
                                    text: "文件名:"
                                    font.pixelSize: DesignSystem.typography.body.medium
                                }
                                
                                EnhancedTextField {
                                    id: filenameField
                                    Layout.fillWidth: true
                                    text: "export_" + new Date().toISOString().slice(0,10)
                                    variant: EnhancedTextField.TextFieldVariant.Outlined
                                }
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                
                                Label {
                                    text: "保存位置:"
                                    font.pixelSize: DesignSystem.typography.body.medium
                                }
                                
                                EnhancedTextField {
                                    id: savePathField
                                    Layout.fillWidth: true
                                    text: "~/Downloads"
                                    readOnly: true
                                    variant: EnhancedTextField.TextFieldVariant.Outlined
                                }
                                
                                EnhancedButton {
                                    text: "浏览"
                                    variant: EnhancedButton.ButtonVariant.Outlined
                                    onClicked: folderDialog.open()
                                }
                            }
                        }
                    }
                }
            }

            // 字段配置页面
            ScrollView {
                ColumnLayout {
                    width: parent.width
                    spacing: DesignSystem.spacing.md

                    Label {
                        text: "选择要导出的字段"
                        font.pixelSize: DesignSystem.typography.headline.small
                        font.weight: DesignSystem.typography.weight.semiBold
                        color: ThemeManager.colors.onSurface
                    }

                    // 字段选择列表
                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 300
                        model: getAvailableFields()
                        
                        delegate: CheckBox {
                            width: parent.width
                            text: modelData.name
                            checked: modelData.selected
                            
                            contentItem: RowLayout {
                                anchors.left: parent.indicator.right
                                anchors.leftMargin: DesignSystem.spacing.sm
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    
                                    Label {
                                        text: modelData.name
                                        font.pixelSize: DesignSystem.typography.body.medium
                                        color: ThemeManager.colors.onSurface
                                    }
                                    
                                    Label {
                                        text: modelData.description
                                        font.pixelSize: DesignSystem.typography.label.small
                                        color: ThemeManager.colors.onSurfaceVariant
                                    }
                                }
                                
                                Label {
                                    text: modelData.type
                                    font.pixelSize: DesignSystem.typography.label.small
                                    color: DesignSystem.colors.primary
                                    
                                    background: Rectangle {
                                        color: Qt.rgba(DesignSystem.colors.primary.r, 
                                                      DesignSystem.colors.primary.g, 
                                                      DesignSystem.colors.primary.b, 0.1)
                                        radius: 4
                                    }
                                    
                                    padding: 4
                                }
                            }
                            
                            onCheckedChanged: {
                                modelData.selected = checked
                            }
                        }
                    }

                    // 快速选择按钮
                    RowLayout {
                        Layout.fillWidth: true
                        
                        EnhancedButton {
                            text: "全选"
                            variant: EnhancedButton.ButtonVariant.Outlined
                            onClicked: selectAllFields(true)
                        }
                        
                        EnhancedButton {
                            text: "全不选"
                            variant: EnhancedButton.ButtonVariant.Outlined
                            onClicked: selectAllFields(false)
                        }
                        
                        EnhancedButton {
                            text: "常用字段"
                            variant: EnhancedButton.ButtonVariant.Outlined
                            onClicked: selectCommonFields()
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // 预览页面
            ScrollView {
                ColumnLayout {
                    width: parent.width
                    spacing: DesignSystem.spacing.md

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: "导出预览"
                            font.pixelSize: DesignSystem.typography.headline.small
                            font.weight: DesignSystem.typography.weight.semiBold
                            color: ThemeManager.colors.onSurface
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        EnhancedButton {
                            text: "刷新预览"
                            variant: EnhancedButton.ButtonVariant.Outlined
                            onClicked: generatePreview()
                        }
                    }

                    // 预览区域
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 300
                        color: ThemeManager.colors.surfaceVariant
                        radius: DesignSystem.radius.md
                        border.width: 1
                        border.color: ThemeManager.colors.outline

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: DesignSystem.spacing.sm

                            TextArea {
                                id: previewText
                                text: "点击'刷新预览'查看导出内容..."
                                readOnly: true
                                font.family: "Consolas, Monaco, monospace"
                                font.pixelSize: DesignSystem.typography.body.small
                                color: ThemeManager.colors.onSurfaceVariant
                                wrapMode: TextArea.Wrap
                            }
                        }
                    }

                    // 预览统计
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: "预览行数: " + getPreviewLineCount()
                            font.pixelSize: DesignSystem.typography.label.small
                            color: ThemeManager.colors.onSurfaceVariant
                        }
                        
                        Label {
                            text: "预计文件大小: " + getEstimatedFileSize()
                            font.pixelSize: DesignSystem.typography.label.small
                            color: ThemeManager.colors.onSurfaceVariant
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }

        // 进度显示区域
        Rectangle {
            Layout.fillWidth: true
            height: 80
            visible: root.isExporting
            color: ThemeManager.colors.surfaceVariant
            radius: DesignSystem.radius.md
            border.width: 1
            border.color: ThemeManager.colors.outline

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: DesignSystem.spacing.md
                spacing: DesignSystem.spacing.sm

                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "正在导出..."
                        font.pixelSize: DesignSystem.typography.body.medium
                        font.weight: DesignSystem.typography.weight.medium
                        color: ThemeManager.colors.onSurface
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Label {
                        text: Math.round(root.exportProgress * 100) + "%"
                        font.pixelSize: DesignSystem.typography.body.medium
                        color: DesignSystem.colors.primary
                    }
                }

                ProgressBar {
                    Layout.fillWidth: true
                    value: root.exportProgress
                    
                    background: Rectangle {
                        color: ThemeManager.colors.outline
                        radius: 2
                    }
                    
                    contentItem: Rectangle {
                        color: DesignSystem.colors.primary
                        radius: 2
                    }
                }

                Label {
                    text: root.currentTask
                    font.pixelSize: DesignSystem.typography.label.small
                    color: ThemeManager.colors.onSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // 操作按钮
        RowLayout {
            Layout.fillWidth: true
            
            EnhancedButton {
                text: "导出历史"
                variant: EnhancedButton.ButtonVariant.Text
                onClicked: exportHistoryDialog.open()
            }
            
            Item { Layout.fillWidth: true }
            
            EnhancedButton {
                text: "取消"
                variant: EnhancedButton.ButtonVariant.Outlined
                enabled: !root.isExporting
                onClicked: root.close()
            }
            
            EnhancedButton {
                text: root.isExporting ? "停止导出" : "开始导出"
                variant: EnhancedButton.ButtonVariant.Filled
                customColor: root.isExporting ? DesignSystem.colors.error : DesignSystem.colors.primary
                
                onClicked: {
                    if (root.isExporting) {
                        stopExport()
                    } else {
                        startExport()
                    }
                }
            }
        }
    }

    // ==================== 文件夹选择对话框 ====================

    FileDialog {
        id: folderDialog
        title: "选择保存位置"
        selectFolder: true
        onAccepted: {
            savePathField.text = folderDialog.fileUrl.toString().replace("file://", "")
        }
    }

    // ==================== 导出历史对话框 ====================

    Dialog {
        id: exportHistoryDialog
        title: "导出历史"
        modal: true
        width: 500
        height: 400
        anchors.centerIn: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacing.md
            spacing: DesignSystem.spacing.md

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "📋 导出历史记录"
                    font.pixelSize: DesignSystem.typography.headline.small
                    font.weight: DesignSystem.typography.weight.semiBold
                    color: ThemeManager.colors.onSurface
                }

                Item { Layout.fillWidth: true }

                EnhancedButton {
                    text: "清空历史"
                    variant: EnhancedButton.ButtonVariant.Text
                    customColor: DesignSystem.colors.error
                    onClicked: clearExportHistory()
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.exportHistory

                delegate: Rectangle {
                    width: parent.width
                    height: 80
                    color: index % 2 === 0 ? ThemeManager.colors.surface : ThemeManager.colors.surfaceVariant
                    radius: DesignSystem.radius.sm

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: DesignSystem.spacing.sm
                        spacing: DesignSystem.spacing.md

                        // 文件图标
                        Label {
                            text: getFileIcon(modelData.format)
                            font.pixelSize: DesignSystem.icons.size.large
                        }

                        // 文件信息
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: modelData.filename
                                font.pixelSize: DesignSystem.typography.body.medium
                                font.weight: DesignSystem.typography.weight.medium
                                color: ThemeManager.colors.onSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Label {
                                text: modelData.format.toUpperCase() + " • " + modelData.size + " • " + modelData.records + " 条记录"
                                font.pixelSize: DesignSystem.typography.label.small
                                color: ThemeManager.colors.onSurfaceVariant
                            }

                            Label {
                                text: "导出时间: " + new Date(modelData.timestamp).toLocaleString()
                                font.pixelSize: DesignSystem.typography.label.small
                                color: ThemeManager.colors.onSurfaceVariant
                            }
                        }

                        // 操作按钮
                        ColumnLayout {
                            spacing: DesignSystem.spacing.xs

                            EnhancedButton {
                                text: "📂"
                                variant: EnhancedButton.ButtonVariant.Text
                                implicitWidth: 32
                                implicitHeight: 32
                                ToolTip.text: "打开文件位置"
                                onClicked: openFileLocation(modelData.path)
                            }

                            EnhancedButton {
                                text: "🔄"
                                variant: EnhancedButton.ButtonVariant.Text
                                implicitWidth: 32
                                implicitHeight: 32
                                ToolTip.text: "重新导出"
                                onClicked: reExport(modelData)
                            }
                        }
                    }
                }

                // 空状态
                Label {
                    visible: parent.count === 0
                    anchors.centerIn: parent
                    text: "暂无导出历史"
                    font.pixelSize: DesignSystem.typography.body.medium
                    color: ThemeManager.colors.onSurfaceVariant
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item { Layout.fillWidth: true }

                EnhancedButton {
                    text: "关闭"
                    variant: EnhancedButton.ButtonVariant.Outlined
                    onClicked: exportHistoryDialog.close()
                }
            }
        }
    }

    // ==================== 方法 ====================
    
    function getAvailableFields() {
        if (root.exportType === "emails") {
            return [
                {name: "邮箱地址", description: "完整的邮箱地址", type: "文本", selected: true},
                {name: "域名", description: "邮箱域名部分", type: "文本", selected: true},
                {name: "状态", description: "邮箱当前状态", type: "文本", selected: true},
                {name: "标签", description: "关联的标签", type: "数组", selected: false},
                {name: "备注", description: "用户备注信息", type: "文本", selected: false},
                {name: "创建时间", description: "邮箱创建时间", type: "日期", selected: true},
                {name: "最后使用", description: "最后使用时间", type: "日期", selected: false}
            ]
        }
        return []
    }
    
    function selectAllFields(selected) {
        var fields = getAvailableFields()
        for (var i = 0; i < fields.length; i++) {
            fields[i].selected = selected
        }
    }
    
    function selectCommonFields() {
        var fields = getAvailableFields()
        var commonFields = ["邮箱地址", "域名", "状态", "创建时间"]
        
        for (var i = 0; i < fields.length; i++) {
            fields[i].selected = commonFields.indexOf(fields[i].name) !== -1
        }
    }
    
    function generatePreview() {
        // 生成预览内容
        var preview = "正在生成预览..."
        previewText.text = preview
        
        // 模拟预览生成
        Qt.callLater(function() {
            var sampleData = root.exportData.slice(0, 5) // 只显示前5条
            var preview = generateSampleExport(sampleData)
            previewText.text = preview
        })
    }
    
    function generateSampleExport(data) {
        // 根据选择的格式和字段生成示例导出内容
        return "邮箱地址,域名,状态,创建时间\ntest@example.com,example.com,活跃,2024-01-01\n..."
    }
    
    function getPreviewLineCount() {
        return previewText.text.split('\n').length
    }
    
    function getEstimatedFileSize() {
        var size = root.exportData.length * 50 // 估算每行50字节
        if (size < 1024) return size + " B"
        if (size < 1024 * 1024) return Math.round(size / 1024) + " KB"
        return Math.round(size / (1024 * 1024)) + " MB"
    }
    
    function startExport() {
        var options = {
            format: "csv", // 从UI获取
            filename: filenameField.text,
            savePath: savePathField.text,
            fields: getSelectedFields(),
            includeHeaders: includeHeadersCheck.checked,
            includeMetadata: includeMetadataCheck.checked,
            compress: compressCheck.checked
        }
        
        root.isExporting = true
        root.exportProgress = 0.0
        root.currentTask = "准备导出..."
        
        root.exportRequested(options)
        
        // 模拟导出进度
        exportProgressTimer.start()
    }
    
    function stopExport() {
        root.isExporting = false
        exportProgressTimer.stop()
        root.exportCancelled()
    }
    
    function getSelectedFields() {
        var fields = getAvailableFields()
        var selected = []
        for (var i = 0; i < fields.length; i++) {
            if (fields[i].selected) {
                selected.push(fields[i].name)
            }
        }
        return selected
    }

    // ==================== 导出进度模拟 ====================
    
    Timer {
        id: exportProgressTimer
        interval: 100
        repeat: true
        
        onTriggered: {
            root.exportProgress += 0.02
            
            if (root.exportProgress < 0.3) {
                root.currentTask = "正在处理数据..."
            } else if (root.exportProgress < 0.7) {
                root.currentTask = "正在生成文件..."
            } else if (root.exportProgress < 0.9) {
                root.currentTask = "正在保存文件..."
            } else {
                root.currentTask = "即将完成..."
            }
            
            if (root.exportProgress >= 1.0) {
                root.exportProgress = 1.0
                root.currentTask = "导出完成！"
                stop()
                
                Qt.callLater(function() {
                    root.isExporting = false
                    root.close()
                })
            }
        }
    }

    // ==================== 导出历史方法 ====================

    function getFileIcon(format) {
        switch (format) {
            case "csv": return "📊"
            case "json": return "🔧"
            case "xlsx": return "📈"
            case "pdf": return "📄"
            default: return "📄"
        }
    }

    function clearExportHistory() {
        root.exportHistory = []
    }

    function openFileLocation(path) {
        // 打开文件所在位置
        console.log("打开文件位置:", path)
    }

    function reExport(historyItem) {
        // 使用历史记录的设置重新导出
        console.log("重新导出:", historyItem.filename)
        exportHistoryDialog.close()
    }

    function addToHistory(exportInfo) {
        var historyItem = {
            filename: exportInfo.filename,
            format: exportInfo.format,
            size: exportInfo.size || "未知",
            records: exportInfo.records || root.exportData.length,
            timestamp: Date.now(),
            path: exportInfo.path,
            options: exportInfo.options
        }

        root.exportHistory.unshift(historyItem)

        // 限制历史记录数量
        if (root.exportHistory.length > 20) {
            root.exportHistory.pop()
        }
    }
}
