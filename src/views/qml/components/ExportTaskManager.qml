/*
 * 导出任务管理组件
 * 管理多个并发导出任务，显示进度和状态
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    // ==================== 自定义属性 ====================
    
    property var exportTasks: []
    property int maxConcurrentTasks: 3
    property bool autoRemoveCompleted: true
    property int completedTaskRetentionTime: 5000 // 5秒后自动移除完成的任务
    
    // ==================== 信号 ====================
    
    signal taskClicked(var task)
    signal taskCancelled(var task)
    signal allTasksCompleted()

    // ==================== 基础样式 ====================
    
    color: ThemeManager.colors.surface
    radius: DesignSystem.radius.lg
    border.width: 1
    border.color: ThemeManager.colors.outline
    
    implicitHeight: Math.max(60, taskList.contentHeight + 40)
    
    // 显示/隐藏动画
    visible: exportTasks.length > 0
    
    Behavior on implicitHeight {
        PropertyAnimation {
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.md
        spacing: DesignSystem.spacing.sm

        // 标题栏
        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: "📤 导出任务 (" + getActiveTaskCount() + "/" + root.maxConcurrentTasks + ")"
                font.pixelSize: DesignSystem.typography.body.medium
                font.weight: DesignSystem.typography.weight.semiBold
                color: ThemeManager.colors.onSurface
            }
            
            Item { Layout.fillWidth: true }
            
            // 全部取消按钮
            EnhancedButton {
                text: "全部取消"
                variant: EnhancedButton.ButtonVariant.Text
                customColor: DesignSystem.colors.error
                implicitHeight: 24
                visible: getActiveTaskCount() > 0
                
                onClicked: cancelAllTasks()
            }
            
            // 清空完成任务按钮
            EnhancedButton {
                text: "清空"
                variant: EnhancedButton.ButtonVariant.Text
                implicitHeight: 24
                visible: getCompletedTaskCount() > 0
                
                onClicked: clearCompletedTasks()
            }
        }

        // 任务列表
        ListView {
            id: taskList
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            model: root.exportTasks
            spacing: DesignSystem.spacing.xs
            interactive: false
            
            delegate: ExportTaskItem {
                width: taskList.width
                taskData: modelData
                
                onClicked: root.taskClicked(modelData)
                onCancelRequested: root.taskCancelled(modelData)
            }
        }
    }

    // ==================== 方法 ====================
    
    function addTask(taskData) {
        var task = {
            id: generateTaskId(),
            name: taskData.name || "导出任务",
            type: taskData.type || "emails",
            format: taskData.format || "csv",
            status: "waiting", // waiting, running, completed, failed, cancelled
            progress: 0.0,
            currentStep: "等待开始...",
            startTime: Date.now(),
            endTime: null,
            error: null,
            options: taskData.options || {},
            data: taskData.data || []
        }
        
        root.exportTasks.push(task)
        root.exportTasksChanged()
        
        // 如果有空闲槽位，立即开始任务
        if (getActiveTaskCount() < root.maxConcurrentTasks) {
            startTask(task.id)
        }
        
        return task.id
    }
    
    function removeTask(taskId) {
        for (var i = 0; i < root.exportTasks.length; i++) {
            if (root.exportTasks[i].id === taskId) {
                root.exportTasks.splice(i, 1)
                root.exportTasksChanged()
                break
            }
        }
        
        // 检查是否有等待的任务可以开始
        startNextWaitingTask()
    }
    
    function updateTask(taskId, updates) {
        for (var i = 0; i < root.exportTasks.length; i++) {
            if (root.exportTasks[i].id === taskId) {
                var task = root.exportTasks[i]
                for (var key in updates) {
                    task[key] = updates[key]
                }
                root.exportTasksChanged()
                
                // 如果任务完成，检查是否需要自动移除
                if (task.status === "completed" && root.autoRemoveCompleted) {
                    Qt.callLater(function() {
                        removeTaskTimer.taskId = taskId
                        removeTaskTimer.start()
                    })
                }
                
                // 如果任务结束，开始下一个等待的任务
                if (task.status === "completed" || task.status === "failed" || task.status === "cancelled") {
                    task.endTime = Date.now()
                    startNextWaitingTask()
                    
                    // 检查是否所有任务都完成了
                    if (getActiveTaskCount() === 0 && getWaitingTaskCount() === 0) {
                        root.allTasksCompleted()
                    }
                }
                
                break
            }
        }
    }
    
    function startTask(taskId) {
        updateTask(taskId, {
            status: "running",
            currentStep: "正在准备..."
        })
        
        // 模拟任务执行
        simulateTaskExecution(taskId)
    }
    
    function cancelTask(taskId) {
        updateTask(taskId, {
            status: "cancelled",
            currentStep: "已取消"
        })
        
        root.taskCancelled(getTask(taskId))
    }
    
    function cancelAllTasks() {
        for (var i = 0; i < root.exportTasks.length; i++) {
            var task = root.exportTasks[i]
            if (task.status === "running" || task.status === "waiting") {
                cancelTask(task.id)
            }
        }
    }
    
    function clearCompletedTasks() {
        var activeTasks = []
        for (var i = 0; i < root.exportTasks.length; i++) {
            var task = root.exportTasks[i]
            if (task.status !== "completed" && task.status !== "failed" && task.status !== "cancelled") {
                activeTasks.push(task)
            }
        }
        root.exportTasks = activeTasks
        root.exportTasksChanged()
    }
    
    function startNextWaitingTask() {
        if (getActiveTaskCount() >= root.maxConcurrentTasks) {
            return
        }
        
        for (var i = 0; i < root.exportTasks.length; i++) {
            var task = root.exportTasks[i]
            if (task.status === "waiting") {
                startTask(task.id)
                break
            }
        }
    }
    
    function getTask(taskId) {
        for (var i = 0; i < root.exportTasks.length; i++) {
            if (root.exportTasks[i].id === taskId) {
                return root.exportTasks[i]
            }
        }
        return null
    }
    
    function getActiveTaskCount() {
        var count = 0
        for (var i = 0; i < root.exportTasks.length; i++) {
            if (root.exportTasks[i].status === "running") {
                count++
            }
        }
        return count
    }
    
    function getWaitingTaskCount() {
        var count = 0
        for (var i = 0; i < root.exportTasks.length; i++) {
            if (root.exportTasks[i].status === "waiting") {
                count++
            }
        }
        return count
    }
    
    function getCompletedTaskCount() {
        var count = 0
        for (var i = 0; i < root.exportTasks.length; i++) {
            var status = root.exportTasks[i].status
            if (status === "completed" || status === "failed" || status === "cancelled") {
                count++
            }
        }
        return count
    }
    
    function generateTaskId() {
        return "task_" + Date.now() + "_" + Math.random().toString(36).substr(2, 9)
    }
    
    function simulateTaskExecution(taskId) {
        var task = getTask(taskId)
        if (!task || task.status !== "running") return
        
        var steps = [
            "正在处理数据...",
            "正在生成文件...",
            "正在保存文件...",
            "正在完成..."
        ]
        
        var currentStepIndex = 0
        var progress = 0
        
        var timer = Qt.createQmlObject(`
            import QtQuick 2.15
            Timer {
                interval: 200
                repeat: true
                running: true
                
                property int stepIndex: 0
                property real taskProgress: 0
                
                onTriggered: {
                    taskProgress += 0.05
                    
                    if (taskProgress >= 1.0) {
                        updateTask("${taskId}", {
                            status: "completed",
                            progress: 1.0,
                            currentStep: "导出完成"
                        })
                        stop()
                        destroy()
                        return
                    }
                    
                    var newStepIndex = Math.floor(taskProgress * ${steps.length})
                    if (newStepIndex !== stepIndex && newStepIndex < ${steps.length}) {
                        stepIndex = newStepIndex
                    }
                    
                    updateTask("${taskId}", {
                        progress: taskProgress,
                        currentStep: "${steps}[stepIndex]"
                    })
                }
            }
        `, root)
    }

    // ==================== 自动移除完成任务的定时器 ====================
    
    Timer {
        id: removeTaskTimer
        interval: root.completedTaskRetentionTime
        
        property string taskId: ""
        
        onTriggered: {
            if (taskId) {
                removeTask(taskId)
                taskId = ""
            }
        }
    }
}
