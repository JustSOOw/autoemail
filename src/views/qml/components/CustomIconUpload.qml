/*
 * 自定义图标上传组件
 * 支持拖拽上传、文件选择、预览等功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

Rectangle {
    id: root
    color: "#f8f9fa"
    radius: 8
    border.color: "#e0e0e0"
    border.width: 1

    // 对外暴露的属性
    property string currentIconPath: ""  // 当前选中的图标路径
    property string currentIconUrl: ""   // 当前图标的URL（用于显示）
    property bool isUploading: false     // 是否正在上传

    // 对外暴露的信号
    signal iconSelected(string iconPath, string iconUrl)  // 图标选择信号
    signal uploadStarted()                               // 上传开始信号
    signal uploadCompleted(string iconPath, string iconUrl)  // 上传完成信号
    signal uploadFailed(string error)                    // 上传失败信号
    signal iconRemoved()                                 // 图标移除信号

    // 内部属性
    property bool isDragActive: false
    property bool hasIcon: currentIconPath.length > 0

    // 拖拽区域
    DropArea {
        id: dropArea
        anchors.fill: parent
        
        onEntered: function(drag) {
            if (drag.hasUrls) {
                root.isDragActive = true
                drag.acceptProposedAction()
            }
        }
        
        onExited: {
            root.isDragActive = false
        }
        
        onDropped: function(drop) {
            root.isDragActive = false
            if (drop.hasUrls && drop.urls.length > 0) {
                var filePath = drop.urls[0].toString()
                // 移除 file:// 前缀
                if (filePath.startsWith("file://")) {
                    filePath = filePath.substring(7)
                }
                uploadImage(filePath)
            }
        }
    }

    // 主要内容区域
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // 图标预览区域
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: root.isDragActive ? "#e3f2fd" : (root.hasIcon ? "white" : "#f5f5f5")
            radius: 8
            border.color: root.isDragActive ? "#2196F3" : "#e0e0e0"
            border.width: root.isDragActive ? 2 : 1

            // 上传动画
            Behavior on color { PropertyAnimation { duration: 200 } }
            Behavior on border.color { PropertyAnimation { duration: 200 } }

            // 图标显示或占位符
            Item {
                anchors.centerIn: parent
                width: 80
                height: 80

                // 图标预览
                Image {
                    id: iconPreview
                    anchors.centerIn: parent
                    width: 64
                    height: 64
                    source: root.currentIconUrl
                    visible: root.hasIcon && !root.isUploading
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    
                    // 图标加载动画
                    PropertyAnimation {
                        id: iconAppearAnimation
                        target: iconPreview
                        property: "scale"
                        from: 0.0
                        to: 1.0
                        duration: 300
                        easing.type: Easing.OutBack
                    }
                    
                    onStatusChanged: {
                        if (status === Image.Ready) {
                            iconAppearAnimation.start()
                        }
                    }
                }

                // 上传中的加载指示器
                BusyIndicator {
                    anchors.centerIn: parent
                    running: root.isUploading
                    visible: root.isUploading
                }

                // 占位符内容
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !root.hasIcon && !root.isUploading
                    spacing: 8

                    Text {
                        text: root.isDragActive ? "📤" : "🖼️"
                        font.pixelSize: 32
                        Layout.alignment: Qt.AlignHCenter
                        color: root.isDragActive ? "#2196F3" : "#999"
                    }

                    Text {
                        text: root.isDragActive ? "释放文件上传" : "自定义图标"
                        font.pixelSize: 14
                        color: root.isDragActive ? "#2196F3" : "#666"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // 点击上传区域
            MouseArea {
                anchors.fill: parent
                enabled: !root.isUploading
                onClicked: {
                    fileDialog.open()
                }
                
                // 悬停效果
                hoverEnabled: true
                onEntered: {
                    if (!root.hasIcon) {
                        parent.color = "#f0f0f0"
                    }
                }
                onExited: {
                    if (!root.hasIcon) {
                        parent.color = "#f5f5f5"
                    }
                }
            }
        }

        // 操作按钮区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                text: "选择文件"
                Layout.fillWidth: true
                enabled: !root.isUploading
                onClicked: fileDialog.open()
                
                background: Rectangle {
                    color: parent.enabled ? (parent.hovered ? "#1976D2" : "#2196F3") : "#e0e0e0"
                    radius: 6
                    Behavior on color { PropertyAnimation { duration: 150 } }
                }
                
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: parent.enabled ? "white" : "#999"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "清除"
                Layout.preferredWidth: 60
                enabled: root.hasIcon && !root.isUploading
                onClicked: removeIcon()
                
                background: Rectangle {
                    color: parent.enabled ? (parent.hovered ? "#D32F2F" : "#F44336") : "#e0e0e0"
                    radius: 6
                    Behavior on color { PropertyAnimation { duration: 150 } }
                }
                
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: parent.enabled ? "white" : "#999"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // 图片信息显示
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: imageInfoText.implicitHeight + 16
            color: "#f0f7ff"
            radius: 6
            visible: root.hasIcon || root.isUploading

            Text {
                id: imageInfoText
                anchors.centerIn: parent
                anchors.margins: 8
                text: root.isUploading ? "正在处理图片..." : "图标已就绪"
                font.pixelSize: 12
                color: "#2196F3"
            }
        }

        // 使用说明
        Text {
            Layout.fillWidth: true
            text: "支持 PNG、JPG、GIF 等格式，最大 5MB\n图片将自动调整为 64x64 像素"
            font.pixelSize: 11
            color: "#999"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.2
            Layout.topMargin: 8
        }
    }

    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: "选择图标文件"
        nameFilters: ["图片文件 (*.png *.jpg *.jpeg *.gif *.bmp *.webp)"]
        
        onAccepted: {
            var filePath = selectedFile.toString()
            // 移除 file:// 前缀
            if (filePath.startsWith("file://")) {
                filePath = filePath.substring(7)
            }
            uploadImage(filePath)
        }
    }

    // ==================== 内部方法 ====================

    function uploadImage(filePath) {
        console.log("开始上传图片:", filePath)
        
        // 设置上传状态
        root.isUploading = true
        root.uploadStarted()

        // 这里需要调用后端的上传方法
        // 假设有一个全局的 tagController 对象
        if (typeof tagController !== 'undefined') {
            // 首先验证图片
            var validationResult = JSON.parse(tagController.validateImage(filePath))
            
            if (!validationResult.valid) {
                root.isUploading = false
                root.uploadFailed(validationResult.error)
                showError("图片验证失败: " + validationResult.error)
                return
            }

            // 获取标签名称（从父组件或全局变量）
            var tagName = root.parent.tagName || "custom_icon"
            
            // 上传图片
            var uploadResult = JSON.parse(tagController.uploadTagIcon(filePath, tagName))
            
            root.isUploading = false
            
            if (uploadResult.success) {
                root.currentIconPath = uploadResult.icon_path
                root.currentIconUrl = uploadResult.icon_url
                root.iconSelected(root.currentIconPath, root.currentIconUrl)
                root.uploadCompleted(root.currentIconPath, root.currentIconUrl)
                
                console.log("图片上传成功:", uploadResult.icon_path)
            } else {
                root.uploadFailed(uploadResult.message)
                showError("上传失败: " + uploadResult.message)
            }
        } else {
            // 模拟上传（用于测试）
            Qt.callLater(function() {
                root.isUploading = false
                // 模拟成功
                var mockUrl = "file://" + filePath
                root.currentIconPath = "data/images/icons/mock_icon.png"
                root.currentIconUrl = mockUrl
                root.iconSelected(root.currentIconPath, root.currentIconUrl)
                root.uploadCompleted(root.currentIconPath, root.currentIconUrl)
            })
        }
    }

    function removeIcon() {
        // 清除当前图标
        root.currentIconPath = ""
        root.currentIconUrl = ""
        root.iconRemoved()
        
        console.log("图标已清除")
    }

    function setIcon(iconPath, iconUrl) {
        // 外部设置图标
        root.currentIconPath = iconPath
        root.currentIconUrl = iconUrl
    }

    function showError(message) {
        // 显示错误消息（如果有全局错误显示组件）
        if (typeof globalStatusMessage !== 'undefined') {
            globalStatusMessage.showError(message)
        }
        console.error("图标上传错误:", message)
    }
}