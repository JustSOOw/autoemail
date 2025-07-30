/*
 * 撤销操作管理组件
 * 管理操作历史和撤销功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    // ==================== 自定义属性 ====================
    
    property var undoStack: []
    property var redoStack: []
    property int maxStackSize: 50
    property bool canUndo: undoStack.length > 0
    property bool canRedo: redoStack.length > 0
    
    // ==================== 信号 ====================
    
    signal undoRequested(var operation)
    signal redoRequested(var operation)
    signal operationAdded(var operation)

    // ==================== 撤销提示条 ====================
    
    Rectangle {
        id: undoToast
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        
        width: Math.min(400, parent.width - 40)
        height: 60
        radius: DesignSystem.radius.lg
        color: ThemeManager.colors.inverseSurface
        
        visible: false
        z: 1000
        
        // 阴影效果
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 12
            color: DesignSystem.colors.shadow
            spread: 0
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacing.md
            spacing: DesignSystem.spacing.md

            Label {
                id: undoMessage
                Layout.fillWidth: true
                text: ""
                font.pixelSize: DesignSystem.typography.body.medium
                color: ThemeManager.colors.inverseOnSurface
                elide: Text.ElideRight
            }

            EnhancedButton {
                text: "撤销"
                variant: EnhancedButton.ButtonVariant.Text
                customColor: ThemeManager.colors.inverseOnSurface
                implicitHeight: 32
                
                onClicked: {
                    performUndo()
                    hideUndoToast()
                }
            }

            EnhancedButton {
                text: "✕"
                variant: EnhancedButton.ButtonVariant.Text
                customColor: ThemeManager.colors.inverseOnSurface
                implicitWidth: 32
                implicitHeight: 32
                
                onClicked: hideUndoToast()
            }
        }

        // 自动隐藏定时器
        Timer {
            id: undoToastTimer
            interval: 5000
            onTriggered: hideUndoToast()
        }

        // 显示/隐藏动画
        PropertyAnimation {
            id: showUndoAnimation
            target: undoToast
            property: "anchors.bottomMargin"
            to: 20
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }

        PropertyAnimation {
            id: hideUndoAnimation
            target: undoToast
            property: "anchors.bottomMargin"
            to: -undoToast.height - 20
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
            
            onFinished: undoToast.visible = false
        }
    }

    // ==================== 操作历史面板 ====================
    
    Popup {
        id: historyPanel
        width: 350
        height: 400
        anchors.centerIn: parent
        modal: true

        background: Rectangle {
            color: ThemeManager.colors.surface
            radius: DesignSystem.radius.lg
            border.width: 1
            border.color: ThemeManager.colors.outline
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 8
                radius: 24
                color: DesignSystem.colors.shadow
                spread: 0
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacing.md
            spacing: DesignSystem.spacing.md

            // 标题栏
            RowLayout {
                Layout.fillWidth: true
                
                Label {
                    text: "📋 操作历史"
                    font.pixelSize: DesignSystem.typography.headline.small
                    font.weight: DesignSystem.typography.weight.semiBold
                    color: ThemeManager.colors.onSurface
                }
                
                Item { Layout.fillWidth: true }
                
                EnhancedButton {
                    text: "清空历史"
                    variant: EnhancedButton.ButtonVariant.Text
                    customColor: DesignSystem.colors.error
                    implicitHeight: 24
                    
                    onClicked: clearHistory()
                }
            }

            // 操作列表
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    model: root.undoStack
                    spacing: DesignSystem.spacing.xs
                    
                    delegate: Rectangle {
                        width: parent.width
                        height: 60
                        radius: DesignSystem.radius.sm
                        color: index % 2 === 0 ? ThemeManager.colors.surface : ThemeManager.colors.surfaceVariant
                        border.width: 1
                        border.color: ThemeManager.colors.outline
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: DesignSystem.spacing.sm
                            spacing: DesignSystem.spacing.md
                            
                            // 操作图标
                            Label {
                                text: getOperationIcon(modelData.type)
                                font.pixelSize: DesignSystem.icons.size.medium
                                color: getOperationColor(modelData.type)
                            }
                            
                            // 操作信息
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Label {
                                    text: getOperationDescription(modelData)
                                    font.pixelSize: DesignSystem.typography.body.medium
                                    color: ThemeManager.colors.onSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                Label {
                                    text: new Date(modelData.timestamp).toLocaleString()
                                    font.pixelSize: DesignSystem.typography.label.small
                                    color: ThemeManager.colors.onSurfaceVariant
                                }
                            }
                            
                            // 撤销按钮
                            EnhancedButton {
                                text: "撤销"
                                variant: EnhancedButton.ButtonVariant.Text
                                implicitHeight: 32
                                
                                onClicked: {
                                    undoOperation(index)
                                    historyPanel.close()
                                }
                            }
                        }
                    }
                    
                    // 空状态
                    Label {
                        visible: parent.count === 0
                        anchors.centerIn: parent
                        text: "暂无操作历史"
                        font.pixelSize: DesignSystem.typography.body.medium
                        color: ThemeManager.colors.onSurfaceVariant
                    }
                }
            }

            // 操作按钮
            RowLayout {
                Layout.fillWidth: true
                
                EnhancedButton {
                    text: "撤销"
                    variant: EnhancedButton.ButtonVariant.Outlined
                    enabled: root.canUndo
                    Layout.fillWidth: true
                    
                    onClicked: {
                        performUndo()
                        historyPanel.close()
                    }
                }
                
                EnhancedButton {
                    text: "重做"
                    variant: EnhancedButton.ButtonVariant.Outlined
                    enabled: root.canRedo
                    Layout.fillWidth: true
                    
                    onClicked: {
                        performRedo()
                        historyPanel.close()
                    }
                }
                
                EnhancedButton {
                    text: "关闭"
                    variant: EnhancedButton.ButtonVariant.Text
                    
                    onClicked: historyPanel.close()
                }
            }
        }
    }

    // ==================== 公共方法 ====================
    
    function addOperation(operation) {
        // 添加操作到撤销栈
        root.undoStack.push({
            type: operation.type,
            description: operation.description,
            data: operation.data,
            timestamp: Date.now(),
            undoAction: operation.undoAction
        })
        
        // 限制栈大小
        if (root.undoStack.length > root.maxStackSize) {
            root.undoStack.shift()
        }
        
        // 清空重做栈
        root.redoStack = []
        
        // 显示撤销提示
        showUndoToast(operation.description || "操作已完成")
        
        root.operationAdded(operation)
    }
    
    function performUndo() {
        if (!root.canUndo) return
        
        var operation = root.undoStack.pop()
        root.redoStack.push(operation)
        
        root.undoRequested(operation)
    }
    
    function performRedo() {
        if (!root.canRedo) return
        
        var operation = root.redoStack.pop()
        root.undoStack.push(operation)
        
        root.redoRequested(operation)
    }
    
    function clearHistory() {
        root.undoStack = []
        root.redoStack = []
    }
    
    function showHistoryPanel() {
        historyPanel.open()
    }
    
    function showUndoToast(message) {
        undoMessage.text = message
        undoToast.anchors.bottomMargin = -undoToast.height - 20
        undoToast.visible = true
        showUndoAnimation.start()
        undoToastTimer.restart()
    }
    
    function hideUndoToast() {
        undoToastTimer.stop()
        hideUndoAnimation.start()
    }
    
    function undoOperation(index) {
        // 撤销指定索引的操作
        if (index >= 0 && index < root.undoStack.length) {
            var operations = root.undoStack.splice(index)
            for (var i = operations.length - 1; i >= 0; i--) {
                root.redoStack.push(operations[i])
                if (i === operations.length - 1) {
                    root.undoRequested(operations[i])
                }
            }
        }
    }

    // ==================== 辅助方法 ====================
    
    function getOperationIcon(type) {
        switch (type) {
            case "delete": return "🗑️"
            case "edit": return "✏️"
            case "create": return "➕"
            case "move": return "📦"
            case "copy": return "📋"
            case "addTags": return "🏷️"
            case "removeTags": return "🏷️"
            default: return "⚙️"
        }
    }
    
    function getOperationColor(type) {
        switch (type) {
            case "delete": return DesignSystem.colors.error
            case "edit": return DesignSystem.colors.warning
            case "create": return DesignSystem.colors.success
            case "move": return DesignSystem.colors.info
            case "copy": return DesignSystem.colors.primary
            default: return ThemeManager.colors.onSurfaceVariant
        }
    }
    
    function getOperationDescription(operation) {
        var itemCount = operation.data && operation.data.items ? operation.data.items.length : 1
        var itemText = itemCount === 1 ? "项" : "项"
        
        switch (operation.type) {
            case "delete":
                return "删除了 " + itemCount + " " + itemText
            case "edit":
                return "编辑了 " + itemCount + " " + itemText
            case "create":
                return "创建了 " + itemCount + " " + itemText
            case "move":
                return "移动了 " + itemCount + " " + itemText
            case "copy":
                return "复制了 " + itemCount + " " + itemText
            case "addTags":
                return "为 " + itemCount + " " + itemText + " 添加了标签"
            case "removeTags":
                return "为 " + itemCount + " " + itemText + " 移除了标签"
            default:
                return operation.description || "执行了操作"
        }
    }

    // ==================== 键盘快捷键 ====================
    
    Keys.onPressed: function(event) {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_Z) {
                if (event.modifiers & Qt.ShiftModifier) {
                    // Ctrl+Shift+Z: 重做
                    performRedo()
                } else {
                    // Ctrl+Z: 撤销
                    performUndo()
                }
                event.accepted = true
            }
        }
    }
}
