/*
 * 状态消息组件
 * 提供统一的状态提示和消息显示
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: root
    height: visible ? implicitHeight : 0
    color: "transparent"
    
    // 对外暴露的属性
    property string message: ""
    property string type: "info" // info, success, warning, error
    property int duration: 3000 // 自动隐藏时间，0表示不自动隐藏
    property bool showIcon: true
    property bool showCloseButton: true
    
    // 内部属性
    property color backgroundColor: {
        switch (type) {
            case "success": return "#E8F5E8"
            case "warning": return "#FFF3CD"
            case "error": return "#F8D7DA"
            default: return "#D1ECF1"
        }
    }
    
    property color borderColor: {
        switch (type) {
            case "success": return "#4CAF50"
            case "warning": return "#FF9800"
            case "error": return "#F44336"
            default: return "#2196F3"
        }
    }
    
    property color textColor: {
        switch (type) {
            case "success": return "#2E7D32"
            case "warning": return "#F57C00"
            case "error": return "#C62828"
            default: return "#1976D2"
        }
    }
    
    property string iconText: {
        switch (type) {
            case "success": return "✅"
            case "warning": return "⚠️"
            case "error": return "❌"
            default: return "ℹ️"
        }
    }
    
    // 显示状态
    visible: message.length > 0
    implicitHeight: visible ? messageRect.height : 0
    
    // 显示/隐藏动画
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }
    
    // 消息容器
    Rectangle {
        id: messageRect
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: messageLayout.height + 20
        color: root.backgroundColor
        border.color: root.borderColor
        border.width: 1
        radius: 6
        
        // 淡入动画
        opacity: root.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }
        
        RowLayout {
            id: messageLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 15
            spacing: 10
            
            // 图标
            Label {
                visible: root.showIcon
                text: root.iconText
                font.pixelSize: 16
                color: root.textColor
            }
            
            // 消息文本
            Label {
                Layout.fillWidth: true
                text: root.message
                font.pixelSize: 14
                color: root.textColor
                wrapMode: Text.WordWrap
            }
            
            // 关闭按钮
            Button {
                visible: root.showCloseButton
                text: "✕"
                font.pixelSize: 14
                font.weight: Font.Bold
                implicitWidth: 28
                implicitHeight: 28
                flat: true

                // 确保按钮在最上层
                z: 10

                // 简化的样式，确保按钮内容居中
                background: Rectangle {
                    color: parent.hovered ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
                    radius: 14
                    border.color: root.textColor
                    border.width: 1

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                // 确保文字居中显示
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: root.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.centerIn: parent
                }

                onClicked: {
                    console.log("关闭按钮被点击")
                    root.hide()
                }

                // 添加工具提示
                ToolTip.text: "关闭"
                ToolTip.visible: hovered

                // 确保鼠标事件能正确处理
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("MouseArea点击事件")
                        root.hide()
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
    
    // 自动隐藏定时器
    Timer {
        id: autoHideTimer
        interval: root.duration
        running: false
        onTriggered: root.hide()
    }
    
    // 公共方法
    function show(messageText, messageType, autohideDuration) {
        root.message = messageText || ""
        root.type = messageType || "info"
        
        if (autohideDuration !== undefined) {
            root.duration = autohideDuration
        }
        
        if (root.duration > 0) {
            autoHideTimer.restart()
        }
    }
    
    function hide() {
        autoHideTimer.stop()
        root.message = ""
    }
    
    function showSuccess(messageText, autohideDuration) {
        show(messageText, "success", autohideDuration)
    }
    
    function showWarning(messageText, autohideDuration) {
        show(messageText, "warning", autohideDuration)
    }
    
    function showError(messageText, autohideDuration) {
        show(messageText, "error", autohideDuration || 5000) // 错误消息默认显示更长时间
    }
    
    function showInfo(messageText, autohideDuration) {
        show(messageText, "info", autohideDuration)
    }
    
    // 鼠标悬停时暂停自动隐藏
    MouseArea {
        anchors.fill: messageRect
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // 不接受点击事件，避免干扰关闭按钮
        onEntered: autoHideTimer.stop()
        onExited: {
            if (root.duration > 0 && root.visible) {
                autoHideTimer.restart()
            }
        }
    }
}
