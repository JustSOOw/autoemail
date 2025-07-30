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

        // 高级搜索区域
        ColumnLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacing.sm

            // 搜索栏
            AdvancedSearchBar {
                id: advancedSearchBar
                Layout.fillWidth: true

                onSearchRequested: function(query, filters) {
                    performAdvancedSearch(query, filters)
                }

                onSearchCleared: {
                    clearSearch()
                }
            }

            // 搜索结果统计
            SearchResultStats {
                id: searchStats
                Layout.fillWidth: true
                currentPage: root.currentPage
                pageSize: 20

                onSearchCleared: {
                    advancedSearchBar.clearSearch()
                    clearSearch()
                }
            }

            // 操作按钮栏
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: "white"
                radius: 8
                border.color: "#e0e0e0"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Label {
                        text: "操作:"
                        font.pixelSize: 14
                        color: "#666"
                    }

                    AnimatedButton {
                        text: "🔄 刷新"
                        animationType: "pulse"
                        onClicked: {
                            startLoading()
                            root.refreshRequested()

                            // 模拟加载完成
                            Qt.callLater(function() {
                                showSuccess()
                            })
                        }
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

                    // 高级导出按钮
                    EnhancedButton {
                        text: "📤 高级导出"
                        variant: EnhancedButton.ButtonVariant.Filled
                        customColor: DesignSystem.colors.warning
                        onClicked: advancedExportDialog.open()
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
                AnimatedListView {
                    id: emailListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.isLoading

                    model: root.emailList
                    spacing: 8

                    // 动画配置
                    enableItemAnimations: true
                    enableAddAnimation: true
                    enableRemoveAnimation: true
                    enableMoveAnimation: true
                    animationType: "slideIn"
                    staggerDelay: 50

                    onItemAnimationCompleted: function(index) {
                        console.log("项目动画完成:", index)
                    }

                    onAllAnimationsCompleted: {
                        console.log("所有动画完成")
                    }

                        delegate: Rectangle {
                            width: emailListView.width
                            height: 80
                            color: {
                                if (isSelected) {
                                    return Qt.rgba(DesignSystem.colors.primary.r,
                                                  DesignSystem.colors.primary.g,
                                                  DesignSystem.colors.primary.b, 0.1)
                                }
                                return ThemeManager.colors.surface
                            }
                            radius: DesignSystem.radius.md
                            border.color: isSelected ? DesignSystem.colors.primary : ThemeManager.colors.outline
                            border.width: isSelected ? 2 : 1

                            property bool isSelected: root.selectedEmails.indexOf(modelData.id) >= 0

                            // 长按进入选择模式
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onPressAndHold: {
                                    if (!batchOperationPanel.selectionMode) {
                                        batchOperationPanel.enterSelectionMode()
                                    }
                                    toggleItemSelection(modelData)
                                }

                                onClicked: function(mouse) {
                                    if (batchOperationPanel.selectionMode) {
                                        toggleItemSelection(modelData)
                                    } else if (mouse.button === Qt.RightButton) {
                                        // 右键菜单
                                        console.log("右键菜单")
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 15

                                // 选择框（选择模式时显示）
                                CheckBox {
                                    visible: batchOperationPanel.selectionMode
                                    checked: parent.parent.isSelected
                                    onCheckedChanged: {
                                        toggleItemSelection(modelData)
                                    }
                                }

                                // 邮箱信息
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    // 邮箱地址（支持搜索高亮）
                                    HighlightedText {
                                        originalText: modelData.email_address || ""
                                        searchQuery: advancedSearchBar.searchText
                                        font.pixelSize: 14
                                        font.weight: DesignSystem.typography.weight.semiBold
                                        color: DesignSystem.colors.primary
                                    }

                                    RowLayout {
                                        spacing: 10

                                        Label {
                                            text: "域名: " + (modelData.domain || "")
                                            font.pixelSize: DesignSystem.typography.label.small
                                            color: ThemeManager.colors.onSurfaceVariant
                                        }

                                        Label {
                                            text: "状态: " + (modelData.status || "")
                                            font.pixelSize: DesignSystem.typography.label.small
                                            color: modelData.status === "active" ? DesignSystem.colors.success : DesignSystem.colors.error
                                        }

                                        Label {
                                            text: "创建: " + (modelData.created_at ? new Date(modelData.created_at).toLocaleDateString() : "")
                                            font.pixelSize: DesignSystem.typography.label.small
                                            color: ThemeManager.colors.onSurfaceVariant
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

        // 批量操作面板
        BatchOperationPanel {
            id: batchOperationPanel
            Layout.fillWidth: true

            onBatchDeleteRequested: function(items) {
                console.log("批量删除:", items.length, "项")
                // 这里调用实际的删除API
                undoManager.addOperation({
                    type: "delete",
                    description: "删除了 " + items.length + " 个邮箱",
                    data: {items: items},
                    undoAction: function() {
                        // 恢复删除的项目
                        console.log("撤销删除操作")
                    }
                })
            }

            onBatchEditRequested: function(items, changes) {
                console.log("批量编辑:", items.length, "项", changes)
                undoManager.addOperation({
                    type: "edit",
                    description: "编辑了 " + items.length + " 个邮箱",
                    data: {items: items, changes: changes}
                })
            }

            onBatchTagRequested: function(items, tags) {
                console.log("批量标签:", items.length, "项", tags)
                undoManager.addOperation({
                    type: "addTags",
                    description: "为 " + items.length + " 个邮箱添加了标签",
                    data: {items: items, tags: tags}
                })
            }

            onSelectionModeToggled: function(enabled) {
                console.log("选择模式:", enabled)
            }
        }

        // 导出任务管理器
        ExportTaskManager {
            id: exportTaskManager
            Layout.fillWidth: true

            onTaskClicked: function(task) {
                console.log("任务点击:", task.name)
            }

            onTaskCancelled: function(task) {
                console.log("任务取消:", task.name)
            }

            onAllTasksCompleted: {
                console.log("所有导出任务完成")
            }
        }
    }

    // ==================== 撤销管理器 ====================

    UndoManager {
        id: undoManager
        anchors.fill: parent

        onUndoRequested: function(operation) {
            console.log("执行撤销:", operation.type)
            if (operation.undoAction) {
                operation.undoAction()
            }
        }

        onRedoRequested: function(operation) {
            console.log("执行重做:", operation.type)
        }
    }

    // ==================== 高级导出对话框 ====================

    AdvancedExportDialog {
        id: advancedExportDialog
        exportData: root.emailList
        exportType: "emails"

        onExportRequested: function(options) {
            console.log("开始导出:", options)

            // 添加导出任务
            var taskId = exportTaskManager.addTask({
                name: "邮箱数据导出 - " + options.format.toUpperCase(),
                type: "emails",
                format: options.format,
                data: root.emailList,
                options: options
            })

            // 模拟导出过程
            Qt.callLater(function() {
                // 这里应该调用实际的导出API
                root.exportEmails(options.format)
            })
        }

        onExportCancelled: {
            console.log("导出取消")
        }
    }

    // 内部方法
    function performSearch() {
        // 保持向后兼容的简单搜索
        root.searchEmails("", "", [], root.currentPage)
    }

    function performAdvancedSearch(query, filters) {
        // 高级搜索方法
        searchStats.setSearching(true)
        var startTime = Date.now()

        // 模拟搜索延迟
        Qt.callLater(function() {
            var searchTime = (Date.now() - startTime) / 1000
            var resultCount = Math.floor(Math.random() * 100) + 1 // 模拟结果数量

            searchStats.updateStats(query, resultCount, searchTime, filters)
            searchStats.setSearching(false)

            // 调用实际搜索
            root.searchEmails(query, filters.status || "", filters.tags || [], root.currentPage)
        })
    }

    function clearSearch() {
        // 清除搜索状态
        searchStats.clearSearch()
        root.searchEmails("", "", [], 1)
    }

    function toggleItemSelection(item) {
        var emailId = item.id
        var index = root.selectedEmails.indexOf(emailId)

        if (index < 0) {
            root.selectedEmails.push(emailId)
            batchOperationPanel.toggleItemSelection(item)
        } else {
            root.selectedEmails.splice(index, 1)
            batchOperationPanel.toggleItemSelection(item)
        }

        // 触发属性更新
        root.selectedEmails = root.selectedEmails.slice()
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
