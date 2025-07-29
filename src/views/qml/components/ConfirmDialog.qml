/*
 * 确认对话框组件
 * 提供统一的确认对话框样式和交互
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Dialog {
    id: root
    modal: true
    anchors.centerIn: parent
    width: Math.min(400, parent.width * 0.8)
    
    // 对外暴露的属性
    property string titleText: "确认操作"
    property string messageText: "确定要执行此操作吗？"
    property string confirmButtonText: "确认"
    property string cancelButtonText: "取消"
    property string iconText: "❓"
    property color confirmButtonColor: Material.Blue
    property bool showIcon: true
    property bool destructive: false // 是否为危险操作
    
    // 对外暴露的信号
    signal confirmed()
    signal cancelled()
    
    // 设置标题
    title: root.titleText
    
    // 危险操作时的样式调整
    onDestructiveChanged: {
        if (destructive) {
            confirmButtonColor = Material.Red
            iconText = "⚠️"
        }
    }
    
    // 内容区域
    ColumnLayout {
        width: parent.width
        spacing: 20
        
        // 图标和消息区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 15
            
            // 图标
            Label {
                visible: root.showIcon
                text: root.iconText
                font.pixelSize: 24
                color: root.destructive ? Material.Red : Material.Blue
                Layout.alignment: Qt.AlignTop
            }
            
            // 消息文本
            Label {
                Layout.fillWidth: true
                text: root.messageText
                font.pixelSize: 14
                color: "#333"
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignTop
            }
        }
        
        // 按钮区域
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 10
            
            Button {
                id: cancelButton
                text: root.cancelButtonText
                font.pixelSize: 14
                Material.background: Material.Grey
                onClicked: {
                    root.cancelled()
                    root.close()
                }
                
                // 键盘快捷键
                Keys.onEscapePressed: clicked()
            }
            
            Button {
                id: confirmButton
                text: root.confirmButtonText
                font.pixelSize: 14
                Material.background: root.confirmButtonColor
                onClicked: {
                    root.confirmed()
                    root.close()
                }
                
                // 键盘快捷键
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
            }
        }
    }
    
    // 打开时聚焦到确认按钮
    onOpened: {
        if (root.destructive) {
            cancelButton.forceActiveFocus()
        } else {
            confirmButton.forceActiveFocus()
        }
    }
    
    // 关闭时发送取消信号
    onRejected: root.cancelled()
    
    // 公共方法
    function showConfirm(title, message, onConfirm, onCancel) {
        root.titleText = title || "确认操作"
        root.messageText = message || "确定要执行此操作吗？"
        
        // 连接信号
        if (onConfirm) {
            root.confirmed.connect(onConfirm)
        }
        if (onCancel) {
            root.cancelled.connect(onCancel)
        }
        
        root.open()
    }
    
    function showDestructiveConfirm(title, message, onConfirm, onCancel) {
        root.destructive = true
        showConfirm(title, message, onConfirm, onCancel)
    }
    
    function showDeleteConfirm(itemName, onConfirm, onCancel) {
        root.destructive = true
        root.titleText = "确认删除"
        root.messageText = "确定要删除 \"" + itemName + "\" 吗？\n此操作不可撤销。"
        root.confirmButtonText = "删除"
        root.iconText = "🗑️"
        
        if (onConfirm) {
            root.confirmed.connect(onConfirm)
        }
        if (onCancel) {
            root.cancelled.connect(onCancel)
        }
        
        root.open()
    }
    
    function showSaveConfirm(onConfirm, onCancel) {
        root.destructive = false
        root.titleText = "保存确认"
        root.messageText = "确定要保存当前更改吗？"
        root.confirmButtonText = "保存"
        root.iconText = "💾"
        root.confirmButtonColor = Material.Green
        
        if (onConfirm) {
            root.confirmed.connect(onConfirm)
        }
        if (onCancel) {
            root.cancelled.connect(onCancel)
        }
        
        root.open()
    }
    
    function showExitConfirm(onConfirm, onCancel) {
        root.destructive = false
        root.titleText = "退出确认"
        root.messageText = "确定要退出应用程序吗？"
        root.confirmButtonText = "退出"
        root.iconText = "🚪"
        root.confirmButtonColor = Material.Orange
        
        if (onConfirm) {
            root.confirmed.connect(onConfirm)
        }
        if (onCancel) {
            root.cancelled.connect(onCancel)
        }
        
        root.open()
    }
    
    // 重置对话框状态
    function reset() {
        root.destructive = false
        root.titleText = "确认操作"
        root.messageText = "确定要执行此操作吗？"
        root.confirmButtonText = "确认"
        root.cancelButtonText = "取消"
        root.iconText = "❓"
        root.confirmButtonColor = Material.Blue
        
        // 断开所有信号连接
        root.confirmed.disconnect()
        root.cancelled.disconnect()
    }
    
    // 关闭时重置状态
    onClosed: {
        // 延迟重置，确保信号处理完成
        Qt.callLater(reset)
    }
}
