/*
 * 批量操作面板组件
 * 支持选择模式、操作确认、进度反馈、撤销功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: root

    // ==================== 自定义属性 ====================
    
    property var selectedItems: []
    property bool selectionMode: false
    property bool isProcessing: false
    property real operationProgress: 0.0
    property string currentOperation: ""
    property var operationHistory: []
    property int maxHistoryItems: 10
    
    // ==================== 信号 ====================
    
    signal batchDeleteRequested(var items)
    signal batchEditRequested(var items, var changes)
    signal batchTagRequested(var items, var tags)
    signal batchStatusRequested(var items, string status)
    signal selectionModeToggled(bool enabled)
    signal undoRequested(var operation)

    // ==================== 基础样式 ====================
    
    height: selectionMode ? 80 : 0
    color: ThemeManager.colors.surfaceVariant
    radius: DesignSystem.radius.lg
    border.width: 1
    border.color: DesignSystem.colors.primary
    
    visible: height > 0
    
    // 显示/隐藏动画
    Behavior on height {
        PropertyAnimation {
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }
    }
    
    // 阴影效果
    layer.enabled: selectionMode
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: -2
        radius: 8
        color: DesignSystem.colors.shadow
        spread: 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.md
        spacing: DesignSystem.spacing.md
        
        visible: !isProcessing

        // 选择信息
        RowLayout {
            spacing: DesignSystem.spacing.sm
            
            Label {
                text: "✓"
                font.pixelSize: DesignSystem.icons.size.medium
                color: DesignSystem.colors.primary
            }
            
            Label {
                text: "已选择 " + root.selectedItems.length + " 项"
                font.pixelSize: DesignSystem.typography.body.medium
                font.weight: DesignSystem.typography.weight.semiBold
                color: ThemeManager.colors.onSurface
            }
        }

        Item { Layout.fillWidth: true }

        // 批量操作按钮
        RowLayout {
            spacing: DesignSystem.spacing.sm

            // 全选/取消全选
            EnhancedButton {
                text: root.selectedItems.length === getTotalItemCount() ? "取消全选" : "全选"
                variant: EnhancedButton.ButtonVariant.Outlined
                implicitHeight: 36
                
                onClicked: {
                    if (root.selectedItems.length === getTotalItemCount()) {
                        clearSelection()
                    } else {
                        selectAll()
                    }
                }
            }

            // 批量删除
            EnhancedButton {
                text: "🗑️ 删除"
                variant: EnhancedButton.ButtonVariant.Outlined
                customColor: DesignSystem.colors.error
                implicitHeight: 36
                enabled: root.selectedItems.length > 0
                
                onClicked: batchDeleteDialog.open()
            }

            // 批量编辑
            EnhancedButton {
                text: "✏️ 编辑"
                variant: EnhancedButton.ButtonVariant.Outlined
                implicitHeight: 36
                enabled: root.selectedItems.length > 0
                
                onClicked: batchEditDialog.open()
            }

            // 批量标签
            EnhancedButton {
                text: "🏷️ 标签"
                variant: EnhancedButton.ButtonVariant.Outlined
                implicitHeight: 36
                enabled: root.selectedItems.length > 0
                
                onClicked: batchTagDialog.open()
            }

            // 更多操作
            EnhancedButton {
                text: "⋯"
                variant: EnhancedButton.ButtonVariant.Outlined
                implicitHeight: 36
                implicitWidth: 36
                enabled: root.selectedItems.length > 0
                
                onClicked: moreActionsMenu.open()
            }
        }

        // 关闭选择模式
        EnhancedButton {
            text: "✕"
            variant: EnhancedButton.ButtonVariant.Text
            implicitWidth: 36
            implicitHeight: 36
            
            onClicked: exitSelectionMode()
        }
    }

    // 进度显示区域
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.md
        spacing: DesignSystem.spacing.sm
        
        visible: isProcessing

        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: "正在处理..."
                font.pixelSize: DesignSystem.typography.body.medium
                font.weight: DesignSystem.typography.weight.medium
                color: ThemeManager.colors.onSurface
            }
            
            Item { Layout.fillWidth: true }
            
            Label {
                text: Math.round(root.operationProgress * 100) + "%"
                font.pixelSize: DesignSystem.typography.body.medium
                color: DesignSystem.colors.primary
            }
        }

        ProgressBar {
            Layout.fillWidth: true
            value: root.operationProgress
            
            background: Rectangle {
                color: ThemeManager.colors.outline
                radius: 2
                opacity: 0.3
            }
            
            contentItem: Rectangle {
                color: DesignSystem.colors.primary
                radius: 2
            }
        }

        Label {
            text: root.currentOperation
            font.pixelSize: DesignSystem.typography.label.small
            color: ThemeManager.colors.onSurfaceVariant
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    // ==================== 批量删除确认对话框 ====================
    
    Dialog {
        id: batchDeleteDialog
        title: "确认批量删除"
        modal: true
        anchors.centerIn: parent
        width: 400
        height: 200

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacing.md
            spacing: DesignSystem.spacing.md

            Label {
                text: "⚠️ 确定要删除选中的 " + root.selectedItems.length + " 项吗？"
                font.pixelSize: DesignSystem.typography.body.medium
                color: ThemeManager.colors.onSurface
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: "此操作不可撤销，请谨慎操作。"
                font.pixelSize: DesignSystem.typography.body.small
                color: DesignSystem.colors.error
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                
                Item { Layout.fillWidth: true }
                
                EnhancedButton {
                    text: "取消"
                    variant: EnhancedButton.ButtonVariant.Outlined
                    onClicked: batchDeleteDialog.close()
                }
                
                EnhancedButton {
                    text: "确认删除"
                    variant: EnhancedButton.ButtonVariant.Filled
                    customColor: DesignSystem.colors.error
                    
                    onClicked: {
                        performBatchDelete()
                        batchDeleteDialog.close()
                    }
                }
            }
        }
    }

    // ==================== 批量编辑对话框 ====================
    
    Dialog {
        id: batchEditDialog
        title: "批量编辑"
        modal: true
        anchors.centerIn: parent
        width: 500
        height: 400

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacing.md
            spacing: DesignSystem.spacing.md

            Label {
                text: "批量编辑 " + root.selectedItems.length + " 项"
                font.pixelSize: DesignSystem.typography.headline.small
                font.weight: DesignSystem.typography.weight.semiBold
                color: ThemeManager.colors.onSurface
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    width: parent.width
                    spacing: DesignSystem.spacing.md

                    // 状态修改
                    GroupBox {
                        Layout.fillWidth: true
                        title: "状态"
                        
                        RowLayout {
                            anchors.fill: parent
                            
                            CheckBox {
                                id: changeStatusCheck
                                text: "修改状态为:"
                            }
                            
                            ComboBox {
                                id: statusCombo
                                enabled: changeStatusCheck.checked
                                model: ["活跃", "非活跃", "归档"]
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // 备注修改
                    GroupBox {
                        Layout.fillWidth: true
                        title: "备注"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            
                            CheckBox {
                                id: changeNotesCheck
                                text: "修改备注"
                            }
                            
                            EnhancedTextField {
                                id: notesField
                                Layout.fillWidth: true
                                enabled: changeNotesCheck.checked
                                placeholderText: "输入新的备注内容..."
                                variant: EnhancedTextField.TextFieldVariant.Outlined
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                
                Item { Layout.fillWidth: true }
                
                EnhancedButton {
                    text: "取消"
                    variant: EnhancedButton.ButtonVariant.Outlined
                    onClicked: batchEditDialog.close()
                }
                
                EnhancedButton {
                    text: "应用更改"
                    variant: EnhancedButton.ButtonVariant.Filled
                    
                    onClicked: {
                        performBatchEdit()
                        batchEditDialog.close()
                    }
                }
            }
        }
    }

    // ==================== 批量标签对话框 ====================
    
    Dialog {
        id: batchTagDialog
        title: "批量标签管理"
        modal: true
        anchors.centerIn: parent
        width: 450
        height: 350

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacing.md
            spacing: DesignSystem.spacing.md

            Label {
                text: "为 " + root.selectedItems.length + " 项添加或移除标签"
                font.pixelSize: DesignSystem.typography.body.medium
                color: ThemeManager.colors.onSurface
            }

            // 标签操作选择
            RowLayout {
                Layout.fillWidth: true
                
                RadioButton {
                    id: addTagsRadio
                    text: "添加标签"
                    checked: true
                }
                
                RadioButton {
                    id: removeTagsRadio
                    text: "移除标签"
                }
            }

            // 标签选择区域
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flow {
                    width: parent.width
                    spacing: DesignSystem.spacing.sm

                    Repeater {
                        model: getAvailableTags()

                        CheckBox {
                            text: modelData.name
                            
                            background: Rectangle {
                                color: modelData.color || DesignSystem.colors.primary
                                opacity: 0.1
                                radius: DesignSystem.radius.sm
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                
                Item { Layout.fillWidth: true }
                
                EnhancedButton {
                    text: "取消"
                    variant: EnhancedButton.ButtonVariant.Outlined
                    onClicked: batchTagDialog.close()
                }
                
                EnhancedButton {
                    text: addTagsRadio.checked ? "添加标签" : "移除标签"
                    variant: EnhancedButton.ButtonVariant.Filled
                    
                    onClicked: {
                        performBatchTag()
                        batchTagDialog.close()
                    }
                }
            }
        }
    }

    // ==================== 更多操作菜单 ====================
    
    Menu {
        id: moreActionsMenu
        
        MenuItem {
            text: "批量导出"
            icon.source: "📤"
            onTriggered: performBatchExport()
        }
        
        MenuItem {
            text: "批量复制"
            icon.source: "📋"
            onTriggered: performBatchCopy()
        }
        
        MenuSeparator {}
        
        MenuItem {
            text: "撤销上次操作"
            icon.source: "↶"
            enabled: root.operationHistory.length > 0
            onTriggered: performUndo()
        }
    }

    // ==================== 方法 ====================
    
    function enterSelectionMode() {
        root.selectionMode = true
        root.selectionModeToggled(true)
    }
    
    function exitSelectionMode() {
        root.selectionMode = false
        root.selectedItems = []
        root.selectionModeToggled(false)
    }
    
    function toggleItemSelection(item) {
        var index = root.selectedItems.indexOf(item)
        if (index === -1) {
            root.selectedItems.push(item)
        } else {
            root.selectedItems.splice(index, 1)
        }
        root.selectedItemsChanged()
    }
    
    function selectAll() {
        // 这里应该从父组件获取所有项目
        console.log("全选所有项目")
    }
    
    function clearSelection() {
        root.selectedItems = []
    }
    
    function getTotalItemCount() {
        // 这里应该从父组件获取总数
        return 100 // 示例值
    }
    
    function getAvailableTags() {
        // 这里应该从父组件获取可用标签
        return [
            {name: "重要", color: "#F44336"},
            {name: "工作", color: "#2196F3"},
            {name: "个人", color: "#4CAF50"}
        ]
    }
    
    function performBatchDelete() {
        addToHistory({
            type: "delete",
            items: root.selectedItems.slice(),
            timestamp: Date.now()
        })
        
        startOperation("正在删除项目...")
        root.batchDeleteRequested(root.selectedItems)
    }
    
    function performBatchEdit() {
        var changes = {}
        
        if (changeStatusCheck.checked) {
            changes.status = statusCombo.currentText
        }
        
        if (changeNotesCheck.checked) {
            changes.notes = notesField.text
        }
        
        addToHistory({
            type: "edit",
            items: root.selectedItems.slice(),
            changes: changes,
            timestamp: Date.now()
        })
        
        startOperation("正在更新项目...")
        root.batchEditRequested(root.selectedItems, changes)
    }
    
    function performBatchTag() {
        var selectedTags = [] // 从UI获取选中的标签
        
        addToHistory({
            type: addTagsRadio.checked ? "addTags" : "removeTags",
            items: root.selectedItems.slice(),
            tags: selectedTags,
            timestamp: Date.now()
        })
        
        startOperation(addTagsRadio.checked ? "正在添加标签..." : "正在移除标签...")
        root.batchTagRequested(root.selectedItems, selectedTags)
    }
    
    function performBatchExport() {
        console.log("批量导出选中项目")
    }
    
    function performBatchCopy() {
        console.log("批量复制选中项目")
    }
    
    function performUndo() {
        if (root.operationHistory.length > 0) {
            var lastOperation = root.operationHistory.pop()
            root.undoRequested(lastOperation)
        }
    }
    
    function startOperation(description) {
        root.isProcessing = true
        root.operationProgress = 0.0
        root.currentOperation = description
        
        // 模拟操作进度
        operationTimer.start()
    }
    
    function completeOperation() {
        root.isProcessing = false
        root.operationProgress = 0.0
        root.currentOperation = ""
        
        // 操作完成后退出选择模式
        Qt.callLater(exitSelectionMode)
    }
    
    function addToHistory(operation) {
        root.operationHistory.push(operation)
        
        // 限制历史记录数量
        if (root.operationHistory.length > root.maxHistoryItems) {
            root.operationHistory.shift()
        }
    }

    // ==================== 操作进度模拟 ====================
    
    Timer {
        id: operationTimer
        interval: 100
        repeat: true
        
        onTriggered: {
            root.operationProgress += 0.05
            
            if (root.operationProgress >= 1.0) {
                root.operationProgress = 1.0
                stop()
                
                Qt.callLater(function() {
                    completeOperation()
                })
            }
        }
    }
}
