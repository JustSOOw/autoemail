/*
 * 性能监控组件
 * 监控QML应用的性能指标，包括FPS、内存使用、渲染时间等
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    // ==================== 自定义属性 ====================
    
    property bool enabled: false
    property bool showOverlay: false
    property int updateInterval: 1000
    property int maxDataPoints: 60
    
    // 性能数据
    property var fpsHistory: []
    property var memoryHistory: []
    property var renderTimeHistory: []
    property real currentFPS: 0
    property real currentMemory: 0
    property real currentRenderTime: 0
    
    // 警告阈值
    property real lowFPSThreshold: 30
    property real highMemoryThreshold: 100 // MB
    property real highRenderTimeThreshold: 16.67 // ms (60fps)

    // ==================== 基础样式 ====================
    
    visible: enabled && showOverlay
    width: 300
    height: 200
    color: Qt.rgba(0, 0, 0, 0.8)
    radius: 8
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.2)
    z: 10000
    
    // 可拖拽
    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: parent
        drag.axis: Drag.XAndYAxis
        
        onDoubleClicked: {
            root.showOverlay = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 5

        // 标题栏
        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: "性能监控"
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: "×"
                implicitWidth: 20
                implicitHeight: 20
                background: Rectangle {
                    color: parent.hovered ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    radius: 10
                }
                contentItem: Label {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.showOverlay = false
            }
        }

        // 性能指标
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 5

            // FPS
            Label {
                text: "FPS:"
                color: "white"
                font.pixelSize: 12
            }
            
            Label {
                text: root.currentFPS.toFixed(1)
                color: root.currentFPS < root.lowFPSThreshold ? "#FF5722" : "#4CAF50"
                font.pixelSize: 12
                font.bold: true
            }

            // 内存使用
            Label {
                text: "内存:"
                color: "white"
                font.pixelSize: 12
            }
            
            Label {
                text: root.currentMemory.toFixed(1) + " MB"
                color: root.currentMemory > root.highMemoryThreshold ? "#FF5722" : "#4CAF50"
                font.pixelSize: 12
                font.bold: true
            }

            // 渲染时间
            Label {
                text: "渲染:"
                color: "white"
                font.pixelSize: 12
            }
            
            Label {
                text: root.currentRenderTime.toFixed(2) + " ms"
                color: root.currentRenderTime > root.highRenderTimeThreshold ? "#FF5722" : "#4CAF50"
                font.pixelSize: 12
                font.bold: true
            }
        }

        // 性能图表
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(1, 1, 1, 0.1)
            radius: 4

            Canvas {
                id: performanceChart
                anchors.fill: parent
                anchors.margins: 5

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    
                    if (root.fpsHistory.length < 2) return
                    
                    // 绘制FPS曲线
                    drawPerformanceCurve(ctx, root.fpsHistory, "#4CAF50", 0, 60)
                    
                    // 绘制内存使用曲线
                    if (root.memoryHistory.length >= 2) {
                        drawPerformanceCurve(ctx, root.memoryHistory, "#2196F3", 0, 200)
                    }
                }
                
                function drawPerformanceCurve(ctx, data, color, minValue, maxValue) {
                    if (data.length < 2) return
                    
                    ctx.strokeStyle = color
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    
                    var stepX = width / (data.length - 1)
                    
                    ctx.beginPath()
                    for (var i = 0; i < data.length; i++) {
                        var x = i * stepX
                        var normalizedValue = (data[i] - minValue) / (maxValue - minValue)
                        var y = height - (normalizedValue * height)
                        
                        if (i === 0) {
                            ctx.moveTo(x, y)
                        } else {
                            ctx.lineTo(x, y)
                        }
                    }
                    ctx.stroke()
                }
            }
        }

        // 控制按钮
        RowLayout {
            Layout.fillWidth: true
            
            Button {
                text: root.enabled ? "暂停" : "开始"
                implicitHeight: 24
                background: Rectangle {
                    color: parent.pressed ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.2)
                    radius: 4
                }
                contentItem: Label {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.enabled = !root.enabled
            }
            
            Button {
                text: "清除"
                implicitHeight: 24
                background: Rectangle {
                    color: parent.pressed ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.2)
                    radius: 4
                }
                contentItem: Label {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: clearHistory()
            }
            
            Item { Layout.fillWidth: true }
        }
    }

    // ==================== 性能监控定时器 ====================
    
    Timer {
        id: monitorTimer
        interval: root.updateInterval
        running: root.enabled
        repeat: true
        
        property real lastFrameTime: 0
        property int frameCount: 0
        
        onTriggered: {
            updatePerformanceMetrics()
        }
    }
    
    // FPS计算定时器
    Timer {
        id: fpsTimer
        interval: 1000
        running: root.enabled
        repeat: true
        
        property int frameCount: 0
        
        onTriggered: {
            root.currentFPS = frameCount
            frameCount = 0
            
            // 添加到历史记录
            addToHistory(root.fpsHistory, root.currentFPS)
            performanceChart.requestPaint()
        }
    }

    // ==================== 方法 ====================
    
    function updatePerformanceMetrics() {
        // 更新内存使用（模拟）
        root.currentMemory = Math.random() * 50 + 30
        addToHistory(root.memoryHistory, root.currentMemory)
        
        // 更新渲染时间（模拟）
        root.currentRenderTime = Math.random() * 10 + 5
        addToHistory(root.renderTimeHistory, root.currentRenderTime)
        
        // 检查性能警告
        checkPerformanceWarnings()
    }
    
    function addToHistory(history, value) {
        history.push(value)
        if (history.length > root.maxDataPoints) {
            history.shift()
        }
    }
    
    function clearHistory() {
        root.fpsHistory = []
        root.memoryHistory = []
        root.renderTimeHistory = []
        performanceChart.requestPaint()
    }
    
    function checkPerformanceWarnings() {
        // FPS警告
        if (root.currentFPS < root.lowFPSThreshold) {
            console.warn("性能警告: FPS过低", root.currentFPS)
        }
        
        // 内存警告
        if (root.currentMemory > root.highMemoryThreshold) {
            console.warn("性能警告: 内存使用过高", root.currentMemory, "MB")
        }
        
        // 渲染时间警告
        if (root.currentRenderTime > root.highRenderTimeThreshold) {
            console.warn("性能警告: 渲染时间过长", root.currentRenderTime, "ms")
        }
    }
    
    function getPerformanceReport() {
        var avgFPS = root.fpsHistory.reduce((a, b) => a + b, 0) / root.fpsHistory.length
        var avgMemory = root.memoryHistory.reduce((a, b) => a + b, 0) / root.memoryHistory.length
        var avgRenderTime = root.renderTimeHistory.reduce((a, b) => a + b, 0) / root.renderTimeHistory.length
        
        return {
            averageFPS: avgFPS || 0,
            averageMemory: avgMemory || 0,
            averageRenderTime: avgRenderTime || 0,
            minFPS: Math.min(...root.fpsHistory) || 0,
            maxMemory: Math.max(...root.memoryHistory) || 0,
            maxRenderTime: Math.max(...root.renderTimeHistory) || 0
        }
    }

    // ==================== 帧计数器 ====================
    
    // 监听帧更新
    Connections {
        target: root.parent
        
        function onFrameSwapped() {
            if (root.enabled) {
                fpsTimer.frameCount++
            }
        }
    }

    // ==================== 快捷键支持 ====================
    
    Keys.onPressed: function(event) {
        if (event.modifiers & Qt.ControlModifier) {
            switch (event.key) {
                case Qt.Key_P:
                    root.showOverlay = !root.showOverlay
                    event.accepted = true
                    break
                case Qt.Key_M:
                    root.enabled = !root.enabled
                    event.accepted = true
                    break
            }
        }
    }

    // ==================== 初始化 ====================
    
    Component.onCompleted: {
        // 设置初始位置
        x = parent.width - width - 20
        y = 20
        
        console.log("性能监控器已初始化")
        console.log("快捷键: Ctrl+P 显示/隐藏, Ctrl+M 开始/暂停")
    }
}
