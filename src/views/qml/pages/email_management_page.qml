/*
 * 邮箱管理页面
 * 提供邮箱列表显示、搜索筛选、分页、编辑删除等功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import "../components"

Rectangle {
    id: root
    color: "#f5f5f5"

    // 对外暴露的属性
    property var emailList: []
    property var tagList: []
    property int currentPage: 1
    property int totalPages: 1
    property int totalEmails: 0
    property bool isLoading: false
    property var selectedEmails: []
    property bool selectAllMode: false

    // 对外暴露的信号
    signal searchEmails(string keyword, string status, var tags, int page)
    signal deleteEmail(int emailId)
    signal editEmail(int emailId, var emailData)
    signal exportEmails(string format)
    signal refreshRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 页面标题
        Label {
            text: "📋 邮箱管理"
            font.bold: true
            font.pixelSize: 24
            color: "#333"
            Layout.alignment: Qt.AlignHCenter
        }

        // 搜索和筛选区域
        Rectangle {
            Layout.fillWidth: true
            height: 120
            color: "white"
            radius: 8
            border.color: "#e0e0e0"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                // 搜索栏
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "搜索邮箱地址、域名或备注..."
                        font.pixelSize: 14

                        onTextChanged: {
                            searchTimer.restart()
                        }

                        Timer {
                            id: searchTimer
                            interval: 500
                            onTriggered: performSearch()
                        }
                    }

                    Button {
                        text: "🔍 搜索"
                        Material.background: Material.Blue
                        onClicked: performSearch()
                    }

                    Button {
                        text: "🔄 刷新"
                        Material.background: Material.Green
                        onClicked: root.refreshRequested()
                    }
                }

                // 筛选选项
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    Label {
                        text: "状态:"
                        font.pixelSize: 14
                        color: "#666"
                    }

                    ComboBox {
                        id: statusFilter
                        model: ["全部", "活跃", "非活跃", "归档"]
                        currentIndex: 0
                        onCurrentTextChanged: performSearch()
                    }

                    Label {
                        text: "标签:"
                        font.pixelSize: 14
                        color: "#666"
                    }

                    ComboBox {
                        id: tagFilter
                        model: ["全部标签"].concat(root.tagList.map(tag => tag.name || ""))
                        currentIndex: 0
                        onCurrentTextChanged: performSearch()
                    }

                    Item { Layout.fillWidth: true }

                    // 批量操作按钮
                    Button {
                        text: "🔧 批量操作"
                        Material.background: Material.Purple
                        enabled: selectedEmails.length > 0
                        onClicked: batchOperationMenu.open()

                        Menu {
                            id: batchOperationMenu
                            MenuItem {
                                text: "批量删除"
                                onTriggered: batchDeleteDialog.open()
                            }
                            MenuItem {
                                text: "批量添加标签"
                                onTriggered: batchTagDialog.open()
                            }
                            MenuItem {
                                text: "批量修改状态"
                                onTriggered: batchStatusDialog.open()
                            }
                        }
                    }

                    // 导出按钮
                    Button {
                        text: "📤 导出"
                        Material.background: Material.Orange
                        onClicked: exportMenu.open()

                        Menu {
                            id: exportMenu
                            MenuItem {
                                text: "导出为 JSON"
                                onTriggered: root.exportEmails("json")
                            }
                            MenuItem {
                                text: "导出为 CSV"
                                onTriggered: root.exportEmails("csv")
                            }
                            MenuItem {
                                text: "导出为 Excel"
                                onTriggered: root.exportEmails("xlsx")
                            }
                        }
                    }
                }
            }
        }

        // 邮箱列表区域
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

                    CheckBox {
                        id: selectAllCheckBox
                        text: "全选"
                        font.pixelSize: 14
                        checked: root.selectAllMode
                        onCheckedChanged: {
                            root.selectAllMode = checked
                            if (checked) {
                                root.selectedEmails = root.emailList.map(function(email) {
                                    return email.id
                                })
                            } else {
                                root.selectedEmails = []
                            }
                        }
                    }

                    Label {
                        text: "邮箱列表"
                        font.bold: true
                        font.pixelSize: 16
                        color: "#333"
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: root.selectedEmails.length > 0 ?
                              "已选择 " + root.selectedEmails.length + " 个，共 " + root.totalEmails + " 个邮箱" :
                              "共 " + root.totalEmails + " 个邮箱"
                        font.pixelSize: 14
                        color: "#666"
                    }
                }

                // 加载指示器
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    visible: root.isLoading

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 20

                        BusyIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            running: root.isLoading
                        }

                        Label {
                            text: "正在加载邮箱列表..."
                            font.pixelSize: 14
                            color: "#666"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // 邮箱列表
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.isLoading

                    ListView {
                        id: emailListView
                        model: root.emailList
                        spacing: 8

                        delegate: Rectangle {
                            width: emailListView.width
                            height: 80
                            color: isSelected ? "#e3f2fd" : "#f8f9fa"
                            radius: 6
                            border.color: isSelected ? "#2196F3" : "#e9ecef"
                            border.width: isSelected ? 2 : 1

                            property bool isSelected: root.selectedEmails.indexOf(modelData.id) >= 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 15

                                // 选择框
                                CheckBox {
                                    checked: parent.parent.isSelected
                                    onCheckedChanged: {
                                        var emailId = modelData.id
                                        var index = root.selectedEmails.indexOf(emailId)

                                        if (checked && index < 0) {
                                            root.selectedEmails.push(emailId)
                                        } else if (!checked && index >= 0) {
                                            root.selectedEmails.splice(index, 1)
                                        }

                                        // 触发属性更新
                                        root.selectedEmails = root.selectedEmails.slice()

                                        // 更新全选状态
                                        selectAllCheckBox.checked = root.selectedEmails.length === root.emailList.length
                                    }
                                }

                                // 邮箱信息
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    Label {
                                        text: modelData.email_address || ""
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#2196F3"
                                    }

                                    RowLayout {
                                        spacing: 10

                                        Label {
                                            text: "域名: " + (modelData.domain || "")
                                            font.pixelSize: 12
                                            color: "#666"
                                        }

                                        Label {
                                            text: "状态: " + (modelData.status || "")
                                            font.pixelSize: 12
                                            color: modelData.status === "active" ? "#4CAF50" : "#F44336"
                                        }

                                        Label {
                                            text: "创建: " + (modelData.created_at ? new Date(modelData.created_at).toLocaleDateString() : "")
                                            font.pixelSize: 12
                                            color: "#666"
                                        }
                                    }
                                }

                                // 标签显示
                                Flow {
                                    Layout.preferredWidth: 150
                                    spacing: 5

                                    Repeater {
                                        model: modelData.tags || []
                                        Rectangle {
                                            width: tagLabel.width + 10
                                            height: 20
                                            color: "#E3F2FD"
                                            radius: 10
                                            border.color: "#2196F3"

                                            Label {
                                                id: tagLabel
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.pixelSize: 10
                                                color: "#2196F3"
                                            }
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
                                            // 打开编辑对话框
                                            editEmailDialog.emailData = modelData
                                            editEmailDialog.open()
                                        }
                                    }

                                    Button {
                                        text: "🗑️"
                                        font.pixelSize: 12
                                        implicitWidth: 30
                                        implicitHeight: 30
                                        Material.background: Material.Red
                                        ToolTip.text: "删除"
                                        onClicked: {
                                            deleteConfirmDialog.emailId = modelData.id
                                            deleteConfirmDialog.emailAddress = modelData.email_address
                                            deleteConfirmDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 分页控制
                Pagination {
                    Layout.fillWidth: true
                    currentPage: root.currentPage
                    totalPages: root.totalPages
                    totalItems: root.totalEmails
                    visible: !root.isLoading

                    onPageChanged: function(page) {
                        root.currentPage = page
                        performSearch()
                    }

                    onPageSizeChanged: function(size) {
                        // 处理页面大小变化
                        console.log("页面大小变化:", size)
                        root.currentPage = 1
                        performSearch()
                    }
                }
            }
        }
    }

    // 删除确认对话框
    Dialog {
        id: deleteConfirmDialog
        title: "确认删除"
        modal: true
        anchors.centerIn: parent

        property int emailId: 0
        property string emailAddress: ""

        ColumnLayout {
            spacing: 20

            Label {
                text: "确定要删除邮箱 \"" + deleteConfirmDialog.emailAddress + "\" 吗？"
                wrapMode: Text.WordWrap
                Layout.preferredWidth: 300
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: deleteConfirmDialog.close()
                }

                Button {
                    text: "删除"
                    Material.background: Material.Red
                    onClicked: {
                        root.deleteEmail(deleteConfirmDialog.emailId)
                        deleteConfirmDialog.close()
                    }
                }
            }
        }
    }

    // 编辑邮箱对话框
    Dialog {
        id: editEmailDialog
        title: "编辑邮箱"
        modal: true
        anchors.centerIn: parent
        width: 400

        property var emailData: ({})

        ColumnLayout {
            spacing: 15
            width: parent.width

            TextField {
                id: editNotesField
                Layout.fillWidth: true
                placeholderText: "备注信息..."
                text: editEmailDialog.emailData.notes || ""
            }

            TextField {
                id: editTagsField
                Layout.fillWidth: true
                placeholderText: "标签 (用逗号分隔)..."
                text: editEmailDialog.emailData.tags ? editEmailDialog.emailData.tags.join(", ") : ""
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: editEmailDialog.close()
                }

                Button {
                    text: "保存"
                    Material.background: Material.Blue
                    onClicked: {
                        var updatedData = {
                            id: editEmailDialog.emailData.id,
                            notes: editNotesField.text,
                            tags: editTagsField.text.split(",").map(tag => tag.trim()).filter(tag => tag.length > 0)
                        }
                        root.editEmail(editEmailDialog.emailData.id, updatedData)
                        editEmailDialog.close()
                    }
                }
            }
        }
    }

    // 内部方法
    function performSearch() {
        var keyword = searchField.text.trim()
        var status = statusFilter.currentText === "全部" ? "" : statusFilter.currentText
        var selectedTag = tagFilter.currentText === "全部标签" ? "" : tagFilter.currentText
        var tags = selectedTag ? [selectedTag] : []

        root.searchEmails(keyword, status, tags, root.currentPage)
    }

    function resetToFirstPage() {
        root.currentPage = 1
    }

    function clearSelection() {
        root.selectedEmails = []
        root.selectAllMode = false
    }
}

// 批量删除确认对话框
ConfirmDialog {
    id: batchDeleteDialog
    titleText: "批量删除确认"
    messageText: "确定要删除选中的 " + root.selectedEmails.length + " 个邮箱吗？\n此操作不可撤销。"
    destructive: true

    onConfirmed: {
        // 执行批量删除
        console.log("批量删除邮箱:", root.selectedEmails)
        root.clearSelection()
    }
}

// 批量添加标签对话框
Dialog {
    id: batchTagDialog
    title: "批量添加标签"
    modal: true
    anchors.centerIn: parent
    width: 400

    ColumnLayout {
        spacing: 15
        width: parent.width

        Label {
            text: "为选中的 " + root.selectedEmails.length + " 个邮箱添加标签:"
            wrapMode: Text.WordWrap
        }

        TextField {
            id: batchTagField
            Layout.fillWidth: true
            placeholderText: "输入标签名称，用逗号分隔..."
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button {
                text: "取消"
                onClicked: batchTagDialog.close()
            }

            Button {
                text: "添加"
                Material.background: Material.Blue
                enabled: batchTagField.text.trim().length > 0
                onClicked: {
                    console.log("批量添加标签:", root.selectedEmails, batchTagField.text)
                    batchTagField.text = ""
                    batchTagDialog.close()
                    root.clearSelection()
                }
            }
        }
    }
}

// 批量修改状态对话框
Dialog {
    id: batchStatusDialog
    title: "批量修改状态"
    modal: true
    anchors.centerIn: parent
    width: 300

    ColumnLayout {
        spacing: 15
        width: parent.width

        Label {
            text: "修改选中的 " + root.selectedEmails.length + " 个邮箱状态为:"
            wrapMode: Text.WordWrap
        }

        ComboBox {
            id: batchStatusCombo
            Layout.fillWidth: true
            model: ["活跃", "非活跃", "归档"]
            currentIndex: 0
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button {
                text: "取消"
                onClicked: batchStatusDialog.close()
            }

            Button {
                text: "修改"
                Material.background: Material.Blue
                onClicked: {
                    console.log("批量修改状态:", root.selectedEmails, batchStatusCombo.currentText)
                    batchStatusDialog.close()
                    root.clearSelection()
                }
            }
        }
    }
}
