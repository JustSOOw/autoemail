/*
 * 导出任务项组件
 * 显示单个导出任务的状态和进度
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    // ==================== 自定义属性 ====================
    
    property var taskData: ({})
    property bool hovered: false
    
    // ==================== 信号 ====================
    
    signal clicked()
    signal cancelRequested()

    // ==================== 基础样式 ====================
    
    height: 60
    color: {
        if (hovered) {
            return ThemeManager.colors.hover
        }
        
        switch (taskData.status) {
            case "running":
                return Qt.rgba(DesignSystem.colors.primary.r, 
                              DesignSystem.colors.primary.g, 
                              DesignSystem.colors.primary.b, 0.05)
            case "completed":
                return Qt.rgba(DesignSystem.colors.success.r, 
                              DesignSystem.colors.success.g, 
                              DesignSystem.colors.success.b, 0.05)
            case "failed":
                return Qt.rgba(DesignSystem.colors.error.r, 
                              DesignSystem.colors.error.g, 
                              DesignSystem.colors.error.b, 0.05)
            case "cancelled":
                return Qt.rgba(ThemeManager.colors.onSurfaceVariant.r, 
                              ThemeManager.colors.onSurfaceVariant.g, 
                              ThemeManager.colors.onSurfaceVariant.b, 0.05)
            default:
                return ThemeManager.colors.surface
        }
    }
    
    radius: DesignSystem.radius.md
    border.width: 1
    border.color: {
        switch (taskData.status) {
            case "running":
                return DesignSystem.colors.primary
            case "completed":
                return DesignSystem.colors.success
            case "failed":
                return DesignSystem.colors.error
            case "cancelled":
                return ThemeManager.colors.onSurfaceVariant
            default:
                return ThemeManager.colors.outline
        }
    }
    
    // 悬停动画
    Behavior on color {
        ColorAnimation {
            duration: DesignSystem.animation.duration.fast
            easing.type: DesignSystem.animation.easing.standard
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.sm
        spacing: DesignSystem.spacing.md

        // 状态图标
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 20
            color: getStatusColor()
            
            Label {
                anchors.centerIn: parent
                text: getStatusIcon()
                font.pixelSize: DesignSystem.icons.size.medium
                color: "white"
            }
            
            // 运行中的旋转动画
            RotationAnimation {
                target: parent
                running: taskData.status === "running"
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 2000
            }
        }

        // 任务信息
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            // 任务名称和格式
            RowLayout {
                Layout.fillWidth: true
                spacing: DesignSystem.spacing.sm
                
                Label {
                    Layout.fillWidth: true
                    text: taskData.name || "导出任务"
                    font.pixelSize: DesignSystem.typography.body.medium
                    font.weight: DesignSystem.typography.weight.medium
                    color: ThemeManager.colors.onSurface
                    elide: Text.ElideRight
                }
                
                Rectangle {
                    width: formatLabel.width + 8
                    height: 20
                    radius: 10
                    color: DesignSystem.colors.primary
                    opacity: 0.1
                    
                    Label {
                        id: formatLabel
                        anchors.centerIn: parent
                        text: (taskData.format || "").toUpperCase()
                        font.pixelSize: DesignSystem.typography.label.small
                        font.weight: DesignSystem.typography.weight.medium
                        color: DesignSystem.colors.primary
                    }
                }
            }

            // 进度条（仅运行中显示）
            ProgressBar {
                Layout.fillWidth: true
                visible: taskData.status === "running"
                value: taskData.progress || 0
                
                background: Rectangle {
                    color: ThemeManager.colors.outline
                    radius: 2
                    opacity: 0.3
                }
                
                contentItem: Rectangle {
                    color: DesignSystem.colors.primary
                    radius: 2
                    
                    // 进度动画
                    Behavior on width {
                        PropertyAnimation {
                            duration: DesignSystem.animation.duration.normal
                            easing.type: DesignSystem.animation.easing.standard
                        }
                    }
                }
            }

            // 状态文本
            Label {
                Layout.fillWidth: true
                text: getStatusText()
                font.pixelSize: DesignSystem.typography.label.small
                color: getStatusTextColor()
                elide: Text.ElideRight
            }
        }

        // 时间信息
        ColumnLayout {
            Layout.preferredWidth: 80
            spacing: 2
            
            Label {
                text: getElapsedTime()
                font.pixelSize: DesignSystem.typography.label.small
                color: ThemeManager.colors.onSurfaceVariant
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
            }
            
            Label {
                visible: taskData.status === "running" && taskData.progress > 0
                text: getEstimatedTime()
                font.pixelSize: DesignSystem.typography.label.small
                color: ThemeManager.colors.onSurfaceVariant
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
            }
        }

        // 操作按钮
        RowLayout {
            spacing: DesignSystem.spacing.xs
            
            // 取消/重试按钮
            EnhancedButton {
                visible: taskData.status === "running" || taskData.status === "waiting"
                variant: EnhancedButton.ButtonVariant.Text
                iconText: "✕"
                customColor: DesignSystem.colors.error
                implicitWidth: 32
                implicitHeight: 32
                ToolTip.text: "取消任务"
                
                onClicked: root.cancelRequested()
            }
            
            // 重试按钮
            EnhancedButton {
                visible: taskData.status === "failed"
                variant: EnhancedButton.ButtonVariant.Text
                iconText: "🔄"
                customColor: DesignSystem.colors.primary
                implicitWidth: 32
                implicitHeight: 32
                ToolTip.text: "重试"
                
                onClicked: root.clicked()
            }
            
            // 查看结果按钮
            EnhancedButton {
                visible: taskData.status === "completed"
                variant: EnhancedButton.ButtonVariant.Text
                iconText: "📂"
                customColor: DesignSystem.colors.success
                implicitWidth: 32
                implicitHeight: 32
                ToolTip.text: "查看文件"
                
                onClicked: root.clicked()
            }
        }
    }

    // ==================== 交互区域 ====================
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }

    // ==================== 方法 ====================
    
    function getStatusIcon() {
        switch (taskData.status) {
            case "waiting": return "⏳"
            case "running": return "⚙️"
            case "completed": return "✅"
            case "failed": return "❌"
            case "cancelled": return "⏹️"
            default: return "❓"
        }
    }
    
    function getStatusColor() {
        switch (taskData.status) {
            case "waiting": return DesignSystem.colors.warning
            case "running": return DesignSystem.colors.primary
            case "completed": return DesignSystem.colors.success
            case "failed": return DesignSystem.colors.error
            case "cancelled": return ThemeManager.colors.onSurfaceVariant
            default: return ThemeManager.colors.outline
        }
    }
    
    function getStatusText() {
        switch (taskData.status) {
            case "waiting": 
                return "等待开始..."
            case "running": 
                var progressText = ""
                if (taskData.progress > 0) {
                    progressText = " (" + Math.round(taskData.progress * 100) + "%)"
                }
                return (taskData.currentStep || "正在处理...") + progressText
            case "completed": 
                return "导出完成 • " + getFileSize()
            case "failed": 
                return "导出失败: " + (taskData.error || "未知错误")
            case "cancelled": 
                return "已取消"
            default: 
                return "未知状态"
        }
    }
    
    function getStatusTextColor() {
        switch (taskData.status) {
            case "failed": return DesignSystem.colors.error
            case "completed": return DesignSystem.colors.success
            case "cancelled": return ThemeManager.colors.onSurfaceVariant
            default: return ThemeManager.colors.onSurfaceVariant
        }
    }
    
    function getElapsedTime() {
        if (!taskData.startTime) return ""
        
        var endTime = taskData.endTime || Date.now()
        var elapsed = Math.floor((endTime - taskData.startTime) / 1000)
        
        if (elapsed < 60) {
            return elapsed + "秒"
        } else if (elapsed < 3600) {
            return Math.floor(elapsed / 60) + "分钟"
        } else {
            return Math.floor(elapsed / 3600) + "小时"
        }
    }
    
    function getEstimatedTime() {
        if (!taskData.progress || taskData.progress <= 0) return ""
        
        var elapsed = Date.now() - taskData.startTime
        var estimated = elapsed / taskData.progress
        var remaining = Math.floor((estimated - elapsed) / 1000)
        
        if (remaining < 60) {
            return "剩余 " + remaining + "秒"
        } else {
            return "剩余 " + Math.floor(remaining / 60) + "分钟"
        }
    }
    
    function getFileSize() {
        if (taskData.fileSize) {
            return taskData.fileSize
        }
        
        // 估算文件大小
        var recordCount = taskData.data ? taskData.data.length : 0
        var estimatedSize = recordCount * 50 // 每条记录约50字节
        
        if (estimatedSize < 1024) {
            return estimatedSize + " B"
        } else if (estimatedSize < 1024 * 1024) {
            return Math.round(estimatedSize / 1024) + " KB"
        } else {
            return Math.round(estimatedSize / (1024 * 1024)) + " MB"
        }
    }
}
