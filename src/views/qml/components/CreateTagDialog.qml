/*
 * 创建标签对话框组件
 * 符合项目样式的标签创建界面
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import QtQuick.Dialogs

Dialog {
    id: root
    title: isEditMode ? "编辑标签" : "创建标签"
    modal: true
    anchors.centerIn: parent
    width: 750
    height: 650

    // 对外暴露的信号
    signal tagCreated(var tagData)
    signal tagUpdated(int tagId, var tagData)

    // 新增属性支持编辑模式
    property bool isEditMode: false
    property var editTagData: ({})

    // 内部属性
    property string selectedIconPath: ""
    property bool isCreating: false

    // 重置表单
    function resetForm() {
        nameField.text = ""
        descField.text = ""
        iconField.text = "🏷️"
        colorField.text = "#2196F3"
        selectedIconPath = ""
        iconPreview.source = ""
        isCreating = false
    }

    // 验证表单
    function validateForm() {
        var name = nameField.text.trim()
        
        if (name.length === 0) {
            console.error("标签名称不能为空")
            nameField.focus = true
            return false
        }

        if (name.length > 20) {
            console.error("标签名称不能超过20个字符")
            nameField.focus = true
            return false
        }

        var colorRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
        if (colorField.text && !colorRegex.test(colorField.text)) {
            console.error("颜色格式不正确")
            colorField.focus = true
            return false
        }

        return true
    }

    onOpened: resetForm()

    ColumnLayout {
        anchors.fill: parent
        spacing: 15  // 减少主要区域间距

        // 标签预览区域
        Rectangle {
            Layout.fillWidth: true
            height: 65  // 减少预览区域高度
            color: "#f8f9fa"
            radius: 8
            border.color: "#e0e0e0"

            RowLayout {
                anchors.centerIn: parent
                spacing: 15

                // 图标预览
                Rectangle {
                    width: 40  // 减少图标尺寸
                    height: 40
                    color: colorField.text || "#2196F3"
                    radius: 20

                    // 表情符号图标
                    Label {
                        id: emojiPreview
                        anchors.centerIn: parent
                        text: iconField.text || "🏷️"
                        font.pixelSize: 16  // 减少字体大小
                        visible: selectedIconPath.length === 0
                    }

                    // 自定义图片图标
                    Image {
                        id: iconPreview
                        anchors.centerIn: parent
                        width: 32  // 减少图片大小
                        height: 32
                        visible: selectedIconPath.length > 0
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                // 标签信息预览
                ColumnLayout {
                    spacing: 5

                    Label {
                        text: nameField.text || "标签名称"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: "#333"
                    }

                    Label {
                        text: descField.text || "标签描述"
                        font.pixelSize: 12
                        color: "#666"
                    }
                }
            }
        }

        // 滚动区域包含表单内容
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: Math.min(root.width - 60, 620)  // 缩小内容宽度，增加左右边距
                anchors.left: parent.left
                anchors.leftMargin: 30     // 增加左边距
                spacing: 15

                // 表单字段
                GridLayout {
                    columns: 2
                    columnSpacing: 12  // 减少列间距
                    rowSpacing: 12     // 减少行间距
                    Layout.fillWidth: true

                    Label {
                        text: "标签名称:"
                        font.pixelSize: 14
                        color: "#333"
                    }

                    TextField {
                        id: nameField
                        Layout.fillWidth: true
                        placeholderText: "输入标签名称..."
                        selectByMouse: true
                        maximumLength: 20
                    }

                    Label {
                        text: "标签描述:"
                        font.pixelSize: 14
                        color: "#333"
                    }

                    TextField {
                        id: descField
                        Layout.fillWidth: true
                        placeholderText: "输入标签描述..."
                        selectByMouse: true
                        maximumLength: 100
                    }

                    Label {
                        text: "标签图标:"
                        font.pixelSize: 14
                        color: "#333"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        TextField {
                            id: iconField
                            Layout.fillWidth: true
                            text: "🏷️"
                            placeholderText: "选择或输入图标..."
                            selectByMouse: true
                            maximumLength: 5
                        }

                        Button {
                            text: "📁"
                            ToolTip.text: "选择图片文件"
                            onClicked: fileDialog.open()
                        }

                        Button {
                            text: "📝"
                            ToolTip.text: "常用图标"
                            onClicked: iconPickerMenu.open()

                            // 图标选择弹窗
                            Popup {
                                id: iconPickerMenu
                                width: 320
                                height: 260
                                modal: true
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: "white"
                                    radius: 8
                                    border.color: "#e0e0e0"
                                    
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        spacing: 10
                                        
                                        Label {
                                            text: "选择图标"
                                            font.pixelSize: 16
                                            font.weight: Font.DemiBold
                                            color: "#333"
                                        }
                                        
                                        // 图标网格
                                        GridLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            columns: 8  // 增加列数以适配更大的窗口
                                            columnSpacing: 8
                                            rowSpacing: 8
                                            
                                            Repeater {
                                                model: ["🏷️", "📌", "⭐", "🔥", "💼", "🎯", "📊", "🔧", "💡", "🎨", "📝", "🌟", "🚀", "💎", "📚", "🎵", "🎮", "⚽", "🍎", "🌈", "🏠", "✈️", "📱", "💻", "🎪", "🎭"]
                                                Rectangle {
                                                    width: 30  // 减小图标框大小
                                                    height: 30
                                                    radius: 6
                                                    color: iconMouseArea.containsMouse ? "#f0f0f0" : "transparent"
                                                    border.color: iconField.text === modelData ? "#2196F3" : "transparent"
                                                    border.width: 2
                                                    
                                                    Label {
                                                        anchors.centerIn: parent
                                                        text: modelData
                                                        font.pixelSize: 16  // 减小图标字体
                                                    }
                                                    
                                                    MouseArea {
                                                        id: iconMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onClicked: {
                                                            iconField.text = modelData
                                                            selectedIconPath = ""
                                                            iconPreview.source = ""
                                                            iconPickerMenu.close()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        text: "标签颜色:"
                        font.pixelSize: 14
                        color: "#333"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // 颜色预览
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: colorField.text || "#2196F3"
                            border.color: "#e0e0e0"
                            border.width: 1
                        }

                        TextField {
                            id: colorField
                            Layout.fillWidth: true
                            text: "#2196F3"
                            placeholderText: "颜色代码 (#RRGGBB)"
                            selectByMouse: true
                            maximumLength: 7

                            // 颜色验证
                            validator: RegularExpressionValidator {
                                regularExpression: /^#[0-9A-Fa-f]{0,6}$/
                            }

                            onTextChanged: {
                                var colorRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
                                if (text && !colorRegex.test(text)) {
                                    color = "#ff5722"
                                } else {
                                    color = "#333"
                                }

                                if (text.length > 0 && !text.startsWith("#")) {
                                    text = "#" + text
                                }
                            }
                        }

                        Button {
                            text: "🎨"
                            ToolTip.text: "选择颜色"
                            onClicked: colorPickerPopup.open()

                            // 自定义颜色选择器弹窗
                            Popup {
                                id: colorPickerPopup
                                width: 320
                                height: 280
                                modal: true
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: "white"
                                    radius: 8
                                    border.color: "#e0e0e0"
                                    
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12  // 减少内边距
                                        spacing: 10  // 减少间距
                                        
                                        Label {
                                            text: "选择颜色"
                                            font.pixelSize: 16
                                            font.weight: Font.DemiBold
                                            color: "#333"
                                        }
                                        
                                        // 预设颜色
                                        Label {
                                            text: "预设颜色:"
                                            font.pixelSize: 14
                                            color: "#666"
                                        }
                                        
                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: 8  // 增加列数以适应更小窗口
                                            columnSpacing: 6  // 减少间距
                                            rowSpacing: 6
                                            
                                            Repeater {
                                                model: [
                                                    "#2196F3", "#4CAF50", "#FF9800", "#F44336",
                                                    "#9C27B0", "#00BCD4", "#795548", "#607D8B",
                                                    "#E91E63", "#FFEB3B", "#8BC34A", "#FF5722",
                                                    "#3F51B5", "#009688", "#FFC107", "#9E9E9E",
                                                    "#673AB7", "#CDDC39", "#FF6F00", "#37474F",
                                                    "#880E4F", "#1A237E", "#BF360C", "#263238"
                                                ]
                                                Rectangle {
                                                    width: 26  // 缩小颜色球
                                                    height: 26
                                                    radius: 6  // 相应缩小圆角
                                                    color: modelData
                                                    border.color: colorField.text === modelData ? "#333" : "transparent"
                                                    border.width: 2  // 缩小边框宽度
                                                    
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onClicked: {
                                                            colorField.text = modelData
                                                        }
                                                        
                                                        ToolTip.text: modelData
                                                        ToolTip.visible: containsMouse
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 自定义颜色输入
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 6  // 减少间距
                                            
                                            Label {
                                                text: "自定义颜色:"
                                                font.pixelSize: 14
                                                color: "#666"
                                            }
                                            
                                            RowLayout {
                                                spacing: 8  // 减少间距
                                                
                                                Rectangle {
                                                    width: 30  // 缩小预览框
                                                    height: 24  // 缩小高度
                                                    radius: 4
                                                    color: customColorField.text || "#FFFFFF"
                                                    border.color: "#ccc"
                                                    border.width: 1
                                                }
                                                
                                                TextField {
                                                    id: customColorField
                                                    Layout.fillWidth: true
                                                    placeholderText: "输入颜色代码 (#RRGGBB)"
                                                    text: colorField.text
                                                    selectByMouse: true
                                                    maximumLength: 7
                                                    
                                                    validator: RegularExpressionValidator {
                                                        regularExpression: /^#[0-9A-Fa-f]{0,6}$/
                                                    }
                                                    
                                                    onTextChanged: {
                                                        if (text.length > 0 && !text.startsWith("#")) {
                                                            text = "#" + text
                                                        }
                                                    }
                                                }
                                                
                                                Button {
                                                    text: "应用"
                                                    enabled: /^#[0-9A-Fa-f]{6}$/.test(customColorField.text)
                                                    onClicked: {
                                                        colorField.text = customColorField.text
                                                        colorPickerPopup.close()  // 应用后自动关闭
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 注释掉底部按钮区域，让窗口更紧凑
                                        // Item { Layout.fillHeight: true }
                                    }
                                }
                            }
                        }
                    }
                }

                // 常用颜色快速选择
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 55  // 进一步减少高度
                    color: "#f8f9fa"
                    radius: 8
                    border.color: "#e0e0e0"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8  // 减少内边距
                        spacing: 6  // 减少间距

                        Label {
                            text: "快速选择颜色:"
                            font.pixelSize: 12
                            color: "#666"
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 4  // 减少间距

                            Repeater {
                                model: [
                                    "#2196F3", "#4CAF50", "#FF9800", "#F44336",
                                    "#9C27B0", "#00BCD4", "#795548", "#607D8B",
                                    "#E91E63", "#FFEB3B", "#8BC34A", "#FF5722"
                                ]

                                Rectangle {
                                    width: 20  // 减少颜色球大小
                                    height: 20
                                    radius: 10
                                    color: modelData
                                    border.color: colorField.text === modelData ? "#333" : "#e0e0e0"
                                    border.width: colorField.text === modelData ? 2 : 1  // 减少边框宽度

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: colorField.text = modelData
                                        hoverEnabled: true
                                        onContainsMouseChanged: {
                                            parent.scale = containsMouse ? 1.1 : 1.0
                                        }
                                    }

                                    Behavior on scale { PropertyAnimation { duration: 100 } }
                                    Behavior on border.width { PropertyAnimation { duration: 150 } }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 按钮区域
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button {
                text: "取消"
                onClicked: root.close()
            }

            Button {
                text: isCreating ? "创建中..." : "创建标签"
                Material.background: Material.Blue
                enabled: nameField.text.trim().length > 0 && !isCreating
                onClicked: {
                    if (!validateForm()) return
                    
                    isCreating = true
                    
                    var tagData = {
                        name: nameField.text.trim(),
                        description: descField.text.trim(),
                        icon: selectedIconPath.length > 0 ? selectedIconPath : iconField.text.trim(),
                        color: colorField.text.trim() || "#2196F3",
                        icon_type: selectedIconPath.length > 0 ? "custom" : "emoji"
                    }

                    root.tagCreated(tagData)

                    Qt.callLater(function() {
                        isCreating = false
                        root.close()
                    })
                }
            }
        }
    }

    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: "选择图标文件"
        nameFilters: ["图片文件 (*.png *.jpg *.jpeg *.gif *.bmp *.svg)", "所有文件 (*)"]
        onAccepted: {
            selectedIconPath = selectedFile.toString()
            iconPreview.source = selectedFile
            console.log("选择了图标文件:", selectedIconPath)
        }
    }
}