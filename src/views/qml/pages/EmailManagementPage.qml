/*
 * 邮箱管理页面 - 简化版本
 * 移除复杂依赖，专注于核心功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: root
    color: "#f5f5f5"
    focus: true

    // 键盘快捷键
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_F5) {
            // F5 刷新
            refreshButton.clicked()
            event.accepted = true
        } else if (event.key === Qt.Key_Delete && selectedEmails.length > 0) {
            // Delete键删除选中项
            batchDeleteDialog.open()
            event.accepted = true
        } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_A) {
            // Ctrl+A 全选
            selectAllCheckBox.checked = !selectAllCheckBox.checked
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            // Esc键清除选择
            clearSelection()
            event.accepted = true
        }
    }

    // 对外暴露的属性
    property var emailList: []
    property var tagList: []
    property int currentPage: 1
    property int totalPages: 1
    property int totalEmails: 0
    property bool isLoading: false
    property var selectedEmails: []
    property bool selectAllMode: false

    // 搜索相关属性
    property bool isSearching: false
    property string searchResultText: ""
    property var currentFilters: ({})
    property string lastSearchQuery: ""

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



        // 操作按钮栏
        Rectangle {
            Layout.fillWidth: true
            height: 70
            color: "white"
            radius: 8
            border.color: "#e0e0e0"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    text: "操作:"
                    font.pixelSize: 14
                    color: "#666"
                }

                Button {
                    id: refreshButton
                    text: isRefreshing ? "⏳ 刷新中..." : "🔄 刷新"
                    enabled: !isRefreshing

                    property bool isRefreshing: false

                    onClicked: {
                        isRefreshing = true
                        root.refreshRequested()

                        // 模拟刷新完成
                        Qt.callLater(function() {
                            refreshTimer.start()
                        })
                    }

                    Timer {
                        id: refreshTimer
                        interval: 1000
                        onTriggered: refreshButton.isRefreshing = false
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

                Button {
                    text: "📤 导出"
                    onClicked: exportDialog.open()
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

                // 添加背景点击区域来取消搜索框焦点
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: {
                        searchField.focus = false
                    }
                }

                // 搜索和操作栏
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 16

                        // 搜索框
                        Rectangle {
                            Layout.preferredWidth: 360
                            height: 44
                            color: "#ffffff"
                            radius: 22
                            border.color: searchField.activeFocus ? "#2196F3" : "#ddd"
                            border.width: 2

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 10

                                Text {
                                    text: isSearching ? "⏳" : "🔍"
                                    font.pixelSize: 16
                                    color: "#666"
                                }

                                TextField {
                                    id: searchField
                                    Layout.fillWidth: true
                                    placeholderText: activeFocus || text.length > 0 ? "" : "搜索邮箱地址、域名..."
                                    font.pixelSize: 14
                                    color: "#333"
                                    background: Item {}
                                    selectByMouse: true
                                    onTextChanged: {
                                        if (text.length > 0) {
                                            searchTimer.restart()
                                        } else {
                                            clearSearch()
                                        }
                                    }
                                }

                                Button {
                                    visible: searchField.text.length > 0
                                    text: "✕"
                                    width: 20
                                    height: 20
                                    background: Rectangle {
                                        color: parent.hovered ? "#f0f0f0" : "transparent"
                                        radius: 10
                                    }
                                    onClicked: clearSearch()
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // 操作按钮
                        RowLayout {
                            spacing: 12

                            Button {
                                text: "筛选"
                                width: 80
                                height: 36
                                Material.background: Material.Orange
                                onClicked: advancedFilterPopup.open()
                            }

                            Button {
                                text: "导出"
                                width: 80
                                height: 36
                                Material.background: Material.Green
                                onClicked: exportEmailsDialog.open()
                            }

                            Button {
                                text: "刷新"
                                width: 80
                                height: 36
                                Material.background: Material.Blue
                                onClicked: root.refreshRequested()
                            }
                        }
                    }
                }

                // 搜索结果统计
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: "transparent"
                    visible: searchStats.visible

                    Label {
                        id: searchStats
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: searchResultText
                        font.pixelSize: 12
                        color: "#666"
                        visible: false
                    }
                }

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
                        color: root.selectedEmails.length > 0 ? "#2196F3" : "#666"
                        font.weight: root.selectedEmails.length > 0 ? Font.DemiBold : Font.Normal

                        Behavior on color { PropertyAnimation { duration: 200 } }
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
                ListView {
                    id: emailListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.isLoading

                    model: root.emailList
                    spacing: 8

                    delegate: Rectangle {
                        width: emailListView.width
                        height: 90
                        color: {
                            if (isSelected) {
                                return "#E3F2FD"
                            } else if (mouseArea.containsMouse) {
                                return "#F5F5F5"
                            }
                            return "white"
                        }
                        radius: 6
                        border.color: isSelected ? "#2196F3" : "#e0e0e0"
                        border.width: isSelected ? 2 : 1

                        // 简化的阴影效果
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -4
                            visible: mouseArea.containsMouse || isSelected
                            color: "#40000000"
                            radius: parent.radius
                            opacity: 0.1
                            z: -1
                            y: 1
                        }

                        // 动画效果
                        Behavior on color { PropertyAnimation { duration: 150 } }
                        Behavior on border.color { PropertyAnimation { duration: 150 } }
                        Behavior on border.width { PropertyAnimation { duration: 150 } }

                        property bool isSelected: root.selectedEmails.indexOf(modelData.id) >= 0

                        // 点击选择
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true

                            onClicked: function(mouse) {
                                if (mouse.modifiers & Qt.ControlModifier) {
                                    toggleItemSelection(modelData)
                                } else if (mouse.button === Qt.RightButton) {
                                    // 右键菜单
                                    console.log("右键菜单")
                                }
                            }

                            onPressAndHold: {
                                toggleItemSelection(modelData)
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15
                            anchors.verticalCenter: parent.verticalCenter

                            // 选择框
                            CheckBox {
                                visible: root.selectedEmails.length > 0 || parent.parent.isSelected
                                checked: parent.parent.isSelected
                                onCheckedChanged: {
                                    toggleItemSelection(modelData)
                                }
                            }

                            // 邮箱信息
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Text {
                                    text: highlightSearchText(modelData.email_address || "", root.lastSearchQuery)
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    color: "#2196F3"
                                    textFormat: Text.RichText
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
                                spacing: 8
                                Layout.alignment: Qt.AlignVCenter

                                Button {
                                    text: "✏️"
                                    font.pixelSize: 14
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    ToolTip.text: "编辑"
                                    onClicked: {
                                        editEmailDialog.emailData = modelData
                                        editEmailDialog.open()
                                    }
                                }

                                Button {
                                    text: "🗑️"
                                    font.pixelSize: 14
                                    implicitWidth: 36
                                    implicitHeight: 36
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

                // 分页控制
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: "transparent"
                    visible: !root.isLoading && root.totalPages > 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Button {
                            text: "◀"
                            enabled: root.currentPage > 1
                            onClicked: {
                                root.currentPage = root.currentPage - 1
                                performSearch()
                            }
                        }

                        Label {
                            text: "第 " + root.currentPage + " 页，共 " + root.totalPages + " 页"
                            font.pixelSize: 14
                            color: "#666"
                        }

                        Button {
                            text: "▶"
                            enabled: root.currentPage < root.totalPages
                            onClicked: {
                                root.currentPage = root.currentPage + 1
                                performSearch()
                            }
                        }

                        Item { width: 20 }

                        Label {
                            text: "共 " + root.totalEmails + " 个邮箱"
                            font.pixelSize: 12
                            color: "#999"
                        }
                    }
                }
            }
        }
    }

    // ==================== 内部方法 ====================

    function performSearch() {
        root.searchEmails(searchField.text, "", [], root.currentPage)
    }

    function resetToFirstPage() {
        root.currentPage = 1
    }

    function clearSelection() {
        root.selectedEmails = []
        root.selectAllMode = false
    }

    function toggleItemSelection(item) {
        var emailId = item.id
        var index = root.selectedEmails.indexOf(emailId)

        if (index < 0) {
            root.selectedEmails.push(emailId)
        } else {
            root.selectedEmails.splice(index, 1)
        }

        // 触发属性更新
        root.selectedEmails = root.selectedEmails.slice()

        // 更新全选状态
        root.selectAllMode = root.selectedEmails.length === root.emailList.length
    }

    function highlightSearchText(originalText, searchQuery) {
        if (!searchQuery || searchQuery.length === 0) {
            return originalText
        }

        var regex = new RegExp("(" + searchQuery.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ")", "gi")
        return originalText.replace(regex, '<span style="background-color: #FFEB3B; color: #000;">$1</span>')
    }

    function performAdvancedSearch() {
        root.isSearching = true
        root.lastSearchQuery = searchField.text
        var startTime = Date.now()

        // 模拟搜索延迟
        Qt.callLater(function() {
            var searchTime = (Date.now() - startTime) / 1000
            var resultCount = root.totalEmails // 实际应该是搜索结果数量

            updateSearchStats(searchField.text, resultCount, searchTime)
            root.isSearching = false

            // 调用实际搜索
            root.searchEmails(searchField.text, currentFilters.status || "", currentFilters.tags || [], 1)
        })
    }

    function clearSearch() {
        searchField.text = ""
        root.lastSearchQuery = ""
        root.currentFilters = {}
        searchStats.visible = false
        root.searchEmails("", "", [], 1)
    }

    function updateSearchStats(query, resultCount, searchTime) {
        if (query.length > 0) {
            root.searchResultText = "搜索 \"" + query + "\" 找到 " + resultCount + " 个结果 (" + searchTime.toFixed(2) + "s)"
            searchStats.visible = true
        } else {
            searchStats.visible = false
        }
    }

    // 高级筛选弹窗
    Popup {
        id: advancedFilterPopup
        y: 140
        width: 320
        height: 280

        background: Rectangle {
            color: "white"
            radius: 8
            border.width: 1
            border.color: "#e0e0e0"

            // 简化的阴影效果
            Rectangle {
                anchors.fill: parent
                anchors.margins: -12
                color: "#40000000"
                radius: parent.radius
                opacity: 0.3
                z: -1
                y: 4
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Label {
                text: "高级筛选"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: "#333"
            }

            // 状态筛选
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Label {
                    text: "状态:"
                    font.pixelSize: 14
                    color: "#666"
                }

                ComboBox {
                    id: statusFilter
                    Layout.fillWidth: true
                    model: ["全部", "活跃", "非活跃", "归档"]
                    currentIndex: 0
                }
            }

            // 域名筛选
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Label {
                    text: "域名:"
                    font.pixelSize: 14
                    color: "#666"
                }

                TextField {
                    id: domainFilter
                    Layout.fillWidth: true
                    placeholderText: "输入域名..."
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true

                Button {
                    text: "重置"
                    onClicked: {
                        statusFilter.currentIndex = 0
                        domainFilter.text = ""
                        root.currentFilters = {}
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "应用"
                    Material.background: Material.Blue
                    onClicked: {
                        root.currentFilters = {
                            status: statusFilter.currentIndex > 0 ? statusFilter.currentText : "",
                            domain: domainFilter.text
                        }
                        performAdvancedSearch()
                        advancedFilterPopup.close()
                    }
                }
            }
        }
    }

    // 搜索定时器
    Timer {
        id: searchTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (searchField.text.length > 2) {
                performAdvancedSearch()
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
                            notes: editNotesField.text
                        }
                        root.editEmail(editEmailDialog.emailData.id, updatedData)
                        editEmailDialog.close()
                    }
                }
            }
        }
    }

    // 导出对话框
    Dialog {
        id: exportDialog
        title: "导出邮箱数据"
        modal: true
        anchors.centerIn: parent
        width: 300

        ColumnLayout {
            spacing: 15
            width: parent.width

            Label {
                text: "选择导出格式:"
                font.pixelSize: 14
            }

            ComboBox {
                id: formatCombo
                Layout.fillWidth: true
                model: ["JSON", "CSV", "Excel"]
                currentIndex: 0
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: exportDialog.close()
                }

                Button {
                    text: "导出"
                    Material.background: Material.Blue
                    onClicked: {
                        root.exportEmails(formatCombo.currentText.toLowerCase())
                        exportDialog.close()
                    }
                }
            }
        }
    }

    // 批量删除确认对话框
    Dialog {
        id: batchDeleteDialog
        title: "批量删除确认"
        modal: true
        anchors.centerIn: parent
        width: 400

        ColumnLayout {
            spacing: 20

            Label {
                text: "确定要删除选中的 " + root.selectedEmails.length + " 个邮箱吗？\n此操作不可撤销。"
                wrapMode: Text.WordWrap
                Layout.preferredWidth: 350
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: batchDeleteDialog.close()
                }

                Button {
                    text: "确认删除"
                    Material.background: Material.Red
                    onClicked: {
                        console.log("批量删除邮箱:", root.selectedEmails)
                        // 这里应该调用实际的批量删除API
                        root.clearSelection()
                        batchDeleteDialog.close()
                    }
                }
            }
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
                        // 这里应该调用实际的批量添加标签API
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
                        // 这里应该调用实际的批量修改状态API
                        batchStatusDialog.close()
                        root.clearSelection()
                    }
                }
            }
        }
    }
}
