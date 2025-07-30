/*
 * 标签管理页面
 * 提供标签的创建、编辑、删除和管理功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import QtGraphicalEffects 1.15
import "../components"

Rectangle {
    id: root
    color: "#f5f5f5"

    // 对外暴露的属性
    property var tagList: []
    property bool isLoading: false

    // 对外暴露的信号
    signal createTag(string name, string description, string color, string icon)
    signal updateTag(int tagId, var tagData)
    signal deleteTag(int tagId)
    signal refreshTags()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 页面标题
        Label {
            text: "🏷️ 标签管理"
            font.bold: true
            font.pixelSize: 24
            color: "#333"
            Layout.alignment: Qt.AlignHCenter
        }

        // 统计图表区域
        TagStatisticsChart {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            tagList: root.tagList
            visible: root.tagList.length > 0
        }

        // 创建标签区域
        Rectangle {
            Layout.fillWidth: true
            height: 150
            color: "white"
            radius: 8
            border.color: "#e0e0e0"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Label {
                    text: "➕ 创建新标签"
                    font.bold: true
                    font.pixelSize: 16
                    color: "#333"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    TextField {
                        id: tagNameField
                        Layout.preferredWidth: 150
                        placeholderText: "标签名称"
                        font.pixelSize: 14
                    }

                    TextField {
                        id: tagDescriptionField
                        Layout.fillWidth: true
                        placeholderText: "标签描述"
                        font.pixelSize: 14
                    }

                    ComboBox {
                        id: tagColorCombo
                        Layout.preferredWidth: 100
                        model: ["蓝色", "绿色", "红色", "橙色", "紫色", "青色"]
                        currentIndex: 0
                    }

                    TextField {
                        id: tagIconField
                        Layout.preferredWidth: 80
                        placeholderText: "图标"
                        font.pixelSize: 14
                        text: "🏷️"
                    }

                    Button {
                        text: "创建"
                        Material.background: Material.Blue
                        enabled: tagNameField.text.trim().length > 0
                        onClicked: {
                            var colorMap = {
                                "蓝色": "#2196F3",
                                "绿色": "#4CAF50", 
                                "红色": "#F44336",
                                "橙色": "#FF9800",
                                "紫色": "#9C27B0",
                                "青色": "#00BCD4"
                            }
                            
                            root.createTag(
                                tagNameField.text.trim(),
                                tagDescriptionField.text.trim(),
                                colorMap[tagColorCombo.currentText] || "#2196F3",
                                tagIconField.text.trim() || "🏷️"
                            )
                            
                            // 清空输入字段
                            tagNameField.text = ""
                            tagDescriptionField.text = ""
                            tagIconField.text = "🏷️"
                            tagColorCombo.currentIndex = 0
                        }
                    }
                }
            }
        }

        // 标签列表区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 8
            border.color: "#e0e0e0"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                // 列表标题栏
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        text: "标签列表"
                        font.bold: true
                        font.pixelSize: 16
                        color: "#333"
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "🔄 刷新"
                        Material.background: Material.Green
                        onClicked: root.refreshTags()
                    }

                    Label {
                        text: "共 " + root.tagList.length + " 个标签"
                        font.pixelSize: 14
                        color: "#666"
                    }
                }

                // 加载指示器
                LoadingIndicator {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    running: root.isLoading
                    message: "正在加载标签列表..."
                    visible: root.isLoading
                }

                // 标签列表
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.isLoading

                    ListView {
                        id: tagListView
                        model: root.tagList
                        spacing: 8

                        // 启用拖拽重排序
                        property int dragItemIndex: -1
                        property bool dragActive: false

                        delegate: DraggableTagItem {
                            width: tagListView.width
                            height: 80
                            tagData: modelData
                            listView: tagListView

                            onEditRequested: function(tagData) {
                                editTagDialog.tagData = tagData
                                editTagDialog.open()
                            }

                            onDeleteRequested: function(tagId, tagName) {
                                deleteTagDialog.tagId = tagId
                                deleteTagDialog.tagName = tagName
                                deleteTagDialog.open()
                            }

                            onQuickEditRequested: function(tagData) {
                                quickEditPopup.tagData = tagData
                                quickEditPopup.open()
                            }
                        }

                                // 标签图标和颜色
                                Rectangle {
                                    width: 40
                                    height: 40
                                    color: modelData.color || "#2196F3"
                                    radius: 20

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.icon || "🏷️"
                                        font.pixelSize: 16
                                    }
                                }

                                // 标签信息
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    Label {
                                        text: modelData.name || ""
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#333"
                                    }

                                    RowLayout {
                                        spacing: 10

                                        Label {
                                            text: modelData.description || "无描述"
                                            font.pixelSize: 12
                                            color: "#666"
                                        }

                                        Label {
                                            text: "使用次数: " + (modelData.usage_count || 0)
                                            font.pixelSize: 12
                                            color: "#666"
                                        }

                                        Label {
                                            text: "创建: " + (modelData.created_at ? new Date(modelData.created_at).toLocaleDateString() : "")
                                            font.pixelSize: 12
                                            color: "#666"
                                        }
                                    }
                                }

                                // 操作按钮
                                RowLayout {
                                    spacing: 5

                                    Button {
                                        text: "✏️"
                                        font.pixelSize: 12
                                        implicitWidth: 30
                                        implicitHeight: 30
                                        ToolTip.text: "编辑"
                                        onClicked: {
                                            editTagDialog.tagData = modelData
                                            editTagDialog.open()
                                        }
                                    }

                                    Button {
                                        text: "🗑️"
                                        font.pixelSize: 12
                                        implicitWidth: 30
                                        implicitHeight: 30
                                        Material.background: Material.Red
                                        ToolTip.text: "删除"
                                        enabled: (modelData.usage_count || 0) === 0
                                        onClicked: {
                                            deleteTagDialog.tagId = modelData.id
                                            deleteTagDialog.tagName = modelData.name
                                            deleteTagDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 空状态提示
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.isLoading && root.tagList.length === 0
                    spacing: 20

                    Label {
                        text: "🏷️"
                        font.pixelSize: 48
                        color: "#ccc"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: "暂无标签"
                        font.pixelSize: 16
                        color: "#666"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: "创建第一个标签来开始管理您的邮箱"
                        font.pixelSize: 14
                        color: "#999"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // 编辑标签对话框
    Dialog {
        id: editTagDialog
        title: "编辑标签"
        modal: true
        anchors.centerIn: parent
        width: 400

        property var tagData: ({})

        ColumnLayout {
            spacing: 15
            width: parent.width

            TextField {
                id: editNameField
                Layout.fillWidth: true
                placeholderText: "标签名称"
                text: editTagDialog.tagData.name || ""
            }

            TextField {
                id: editDescriptionField
                Layout.fillWidth: true
                placeholderText: "标签描述"
                text: editTagDialog.tagData.description || ""
            }

            TextField {
                id: editIconField
                Layout.fillWidth: true
                placeholderText: "图标"
                text: editTagDialog.tagData.icon || "🏷️"
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: editTagDialog.close()
                }

                Button {
                    text: "保存"
                    Material.background: Material.Blue
                    enabled: editNameField.text.trim().length > 0
                    onClicked: {
                        var updatedData = {
                            id: editTagDialog.tagData.id,
                            name: editNameField.text.trim(),
                            description: editDescriptionField.text.trim(),
                            icon: editIconField.text.trim() || "🏷️"
                        }
                        root.updateTag(editTagDialog.tagData.id, updatedData)
                        editTagDialog.close()
                    }
                }
            }
        }
    }

    // 快速编辑弹出框
    Popup {
        id: quickEditPopup
        width: 320
        height: 200
        modal: true
        anchors.centerIn: parent

        property var tagData: ({})

        Rectangle {
            anchors.fill: parent
            color: ThemeManager.colors.surface
            radius: DesignSystem.radius.lg
            border.width: 1
            border.color: ThemeManager.colors.outline

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: DesignSystem.spacing.md
                spacing: DesignSystem.spacing.md

                Label {
                    text: "快速编辑标签"
                    font.pixelSize: DesignSystem.typography.headline.small
                    font.weight: DesignSystem.typography.weight.semiBold
                    color: ThemeManager.colors.onSurface
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: DesignSystem.spacing.md

                    // 颜色选择
                    Rectangle {
                        width: 40
                        height: 40
                        color: quickEditPopup.tagData.color || DesignSystem.colors.primary
                        radius: 20
                        border.width: 2
                        border.color: ThemeManager.colors.outline

                        MouseArea {
                            anchors.fill: parent
                            onClicked: quickColorPicker.open()
                        }
                    }

                    // 图标选择
                    EnhancedTextField {
                        id: quickIconField
                        Layout.preferredWidth: 80
                        text: quickEditPopup.tagData.icon || "🏷️"
                        labelText: "图标"
                        variant: EnhancedTextField.TextFieldVariant.Outlined
                    }

                    // 名称编辑
                    EnhancedTextField {
                        id: quickNameField
                        Layout.fillWidth: true
                        text: quickEditPopup.tagData.name || ""
                        labelText: "标签名称"
                        variant: EnhancedTextField.TextFieldVariant.Outlined
                    }
                }

                // 描述编辑
                EnhancedTextField {
                    id: quickDescField
                    Layout.fillWidth: true
                    text: quickEditPopup.tagData.description || ""
                    labelText: "描述"
                    variant: EnhancedTextField.TextFieldVariant.Outlined
                }

                // 操作按钮
                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    EnhancedButton {
                        text: "取消"
                        variant: EnhancedButton.ButtonVariant.Text
                        onClicked: quickEditPopup.close()
                    }

                    EnhancedButton {
                        text: "保存"
                        variant: EnhancedButton.ButtonVariant.Filled
                        onClicked: {
                            saveQuickEdit()
                            quickEditPopup.close()
                        }
                    }
                }
            }
        }

        // 快速颜色选择器
        Popup {
            id: quickColorPicker
            width: 240
            height: 80

            Flow {
                anchors.fill: parent
                spacing: 8

                property var colors: [
                    "#2196F3", "#4CAF50", "#F44336", "#FF9800",
                    "#9C27B0", "#00BCD4", "#795548", "#607D8B",
                    "#E91E63", "#3F51B5", "#009688", "#8BC34A"
                ]

                Repeater {
                    model: parent.colors

                    Rectangle {
                        width: 32
                        height: 32
                        color: modelData
                        radius: 16
                        border.width: 2
                        border.color: "white"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                quickEditPopup.tagData.color = modelData
                                quickColorPicker.close()
                            }
                        }

                        // 悬停效果
                        scale: parent.hovered ? 1.1 : 1.0
                        Behavior on scale {
                            PropertyAnimation {
                                duration: DesignSystem.animation.duration.fast
                            }
                        }
                    }
                }
            }
        }

        function saveQuickEdit() {
            var updatedData = {
                id: quickEditPopup.tagData.id,
                name: quickNameField.text.trim(),
                description: quickDescField.text.trim(),
                icon: quickIconField.text.trim() || "🏷️",
                color: quickEditPopup.tagData.color
            }
            root.updateTag(quickEditPopup.tagData.id, updatedData)
        }
    }

    // 删除确认对话框
    ConfirmDialog {
        id: deleteTagDialog

        property int tagId: 0
        property string tagName: ""

        titleText: "确认删除标签"
        messageText: "确定要删除标签 \"" + tagName + "\" 吗？\n此操作不可撤销。"
        destructive: true

        onConfirmed: {
            root.deleteTag(tagId)
        }
    }
}
