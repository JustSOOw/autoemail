/*
 * 加载指示器组件
 * 提供统一的加载动画和状态显示
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: root
    color: "transparent"
    
    // 对外暴露的属性
    property bool running: false
    property string message: "正在加载..."
    property int size: 48
    property color indicatorColor: Material.primary
    property color textColor: "#666"
    property int textSize: 14
    
    // 显示/隐藏动画
    visible: running
    opacity: running ? 1.0 : 0.0
    
    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }
    
    // 主布局
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        
        // 旋转指示器
        Rectangle {
            id: indicator
            Layout.alignment: Qt.AlignHCenter
            width: root.size
            height: root.size
            color: "transparent"
            
            // 外圆环
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 3
                border.color: "#E0E0E0"
                radius: width / 2
            }
            
            // 旋转的弧形
            Canvas {
                id: canvas
                anchors.fill: parent
                
                property real rotation: 0
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    
                    // 设置样式
                    ctx.strokeStyle = root.indicatorColor
                    ctx.lineWidth = 3
                    ctx.lineCap = "round"
                    
                    // 绘制弧形
                    var centerX = width / 2
                    var centerY = height / 2
                    var radius = (width - 6) / 2
                    var startAngle = rotation * Math.PI / 180
                    var endAngle = startAngle + Math.PI * 1.5
                    
                    ctx.beginPath()
                    ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                    ctx.stroke()
                }
                
                // 旋转动画
                RotationAnimation {
                    target: canvas
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: root.running
                    
                    onRunningChanged: {
                        if (running) {
                            canvas.requestPaint()
                        }
                    }
                }
                
                Timer {
                    interval: 16 // ~60fps
                    running: root.running
                    repeat: true
                    onTriggered: canvas.requestPaint()
                }
            }
        }
        
        // 加载文本
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.message
            font.pixelSize: root.textSize
            color: root.textColor
            horizontalAlignment: Text.AlignHCenter
        }
    }
    
    // 脉冲动画效果
    SequentialAnimation {
        running: root.running
        loops: Animation.Infinite
        
        NumberAnimation {
            target: root
            property: "scale"
            from: 1.0
            to: 1.05
            duration: 800
            easing.type: Easing.InOutSine
        }
        
        NumberAnimation {
            target: root
            property: "scale"
            from: 1.05
            to: 1.0
            duration: 800
            easing.type: Easing.InOutSine
        }
    }
    
    // 公共方法
    function show(loadingMessage) {
        if (loadingMessage) {
            root.message = loadingMessage
        }
        root.running = true
    }
    
    function hide() {
        root.running = false
    }
    
    function updateMessage(newMessage) {
        root.message = newMessage
    }
}
