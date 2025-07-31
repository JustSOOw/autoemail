/*
 * 标签管理页面
 * 提供标签的创建、编辑、删除和管理功能
 * 兼容PyQt6，移除QtGraphicalEffects依赖
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import "../components"

Rectangle {
    id: root
    color: "#f5f5f5"

    // 响应式设计属性
    property bool isMobile: width < 768
    property bool isTablet: width >= 768 && width < 1024
    property bool isDesktop: width >= 1024

    // ==================== 对外暴露的属性 ====================

    property var tagList: []
    property bool isLoading: false
    property var selectedTags: []
    property bool selectAllMode: false
    property var searchResults: []
    property string lastSearchQuery: ""
    property var tagStatistics: ({})

    // ==================== 对外暴露的信号 ====================

    signal createTag(var tagData)
    signal updateTag(int tagId, var tagData)
    signal deleteTag(int tagId)
    signal batchDeleteTags(var tagIds)
    signal searchTags(string keyword)
    signal refreshRequested()
    signal exportTags(string format)
    signal importTags(string filePath)
    signal requestFileSelection()  // 新增：请求文件选择信号

    // ==================== 内部属性 ====================

    property bool isSearching: false
    property string searchResultText: ""
    property var filteredTagList: []  // 筛选后的标签列表
    property bool isFiltered: false   // 是否处于筛选状态
    

    // ==================== 页面初始化 ====================

    Component.onCompleted: {
        console.log("标签管理页面初始化")
        // 设置初始加载状态
        root.isLoading = true

        // 延迟加载数据，确保页面已完全渲染
        Qt.callLater(function() {
            console.log("标签管理页面请求刷新标签列表")

            // 调用父窗口的refreshTagList函数
            if (typeof window !== 'undefined' && window.refreshTagList) {
                window.refreshTagList()
            } else {
                console.log("window.refreshTagList不可用，使用本地数据")
                // 如果无法调用父窗口函数，使用本地模拟数据
                root.tagList = [
                    {id: 1, name: "工作", description: "工作相关邮箱", color: "#2196F3", icon: "💼", usage_count: 5},
                    {id: 2, name: "个人", description: "个人使用邮箱", color: "#4CAF50", icon: "👤", usage_count: 3},
                    {id: 3, name: "测试", description: "测试用途邮箱", color: "#FF9800", icon: "🧪", usage_count: 2}
                ]
                root.isLoading = false
            }

            // 发送刷新请求信号
            root.refreshRequested()

            // 5秒后如果仍在加载，自动重置加载状态（防止永久加载状态）
            tagLoadingResetTimer.start()
        })
    }

    // 安全定时器 - 防止永久加载状态
    Timer {
        id: tagLoadingResetTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (root.isLoading) {
                console.log("安全定时器触发：重置标签页面加载状态")
                root.isLoading = false
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.isMobile ? 12 : 20
        spacing: root.isMobile ? 15 : 20

        // ==================== 页面标题 ====================
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            Label {
                text: "🏷️ 标签管理"
                font.bold: true
                font.pixelSize: 24
                color: "#333"
            }

            Item { Layout.fillWidth: true }

            // 统计信息
            Rectangle {
                width: 200
                height: 40
                color: "#E3F2FD"
                radius: 8
                border.color: "#2196F3"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Label {
                        text: "📊"
                        font.pixelSize: 16
                    }

                    Label {
                        text: root.isFiltered ?
                              "筛选结果: " + root.filteredTagList.length + " / " + root.tagList.length + " 个标签" :
                              "共 " + root.tagList.length + " 个标签"
                        font.pixelSize: 14
                        color: root.isFiltered ? "#FF9800" : "#2196F3"
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        // ==================== 标签列表区域 ====================

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 8
            border.color: "#e0e0e0"

            // 背景点击区域来取消搜索框焦点 - 移到Layout外部避免冲突
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    searchField.focus = false
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                // 搜索和操作栏
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 16

                        // 搜索框 - 响应式宽度
                        Rectangle {
                            Layout.preferredWidth: root.isMobile ? Math.min(parent.width * 0.8, 280) : 320
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
                                    text: "🔍"
                                    font.pixelSize: 16
                                    color: "#666"
                                }

                                TextField {
                                    id: searchField
                                    Layout.fillWidth: true
                                    placeholderText: text.length === 0 ? "搜索标签名称、描述、颜色、图标..." : ""
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

                        // 操作按钮 - 响应式布局
                        RowLayout {
                            spacing: root.isMobile ? 8 : 12

                            Button {
                                text: root.isMobile ? "+" : "创建"
                                width: root.isMobile ? 40 : 80
                                height: 36
                                Material.background: Material.Blue
                                onClicked: newCreateTagDialog.open()
                                ToolTip.text: root.isMobile ? "创建标签" : ""
                                ToolTip.visible: root.isMobile && hovered
                            }

                            Button {
                                text: root.isMobile ? "⚡" : "批量"
                                width: root.isMobile ? 40 : 80
                                height: 36
                                Material.background: Material.Purple
                                enabled: selectedTags.length > 0
                                onClicked: batchOperationMenu.open()
                                ToolTip.text: root.isMobile ? "批量操作" : ""
                                ToolTip.visible: root.isMobile && hovered

                                Menu {
                                    id: batchOperationMenu
                                    MenuItem {
                                        text: "批量删除"
                                        onTriggered: batchDeleteDialog.open()
                                    }
                                    MenuItem {
                                        text: "批量导出"
                                        onTriggered: exportTagsDialog.open()
                                    }
                                }
                            }

                            Button {
                                text: root.isMobile ? "📤" : "导出"
                                width: root.isMobile ? 40 : 80
                                height: 36
                                Material.background: Material.Green
                                onClicked: exportTagsDialog.open()
                                ToolTip.text: root.isMobile ? "导出标签" : ""
                                ToolTip.visible: root.isMobile && hovered
                            }

                            Button {
                                text: root.isMobile ? "📥" : "导入"
                                width: root.isMobile ? 40 : 80
                                height: 36
                                Material.background: Material.Orange
                                onClicked: importTagsDialog.open()
                                ToolTip.text: root.isMobile ? "导入标签" : ""
                                ToolTip.visible: root.isMobile && hovered
                            }

                            Button {
                                text: root.isMobile ? "🔄" : "刷新"
                                width: root.isMobile ? 40 : 80
                                height: 36
                                Material.background: Material.Teal
                                onClicked: root.refreshRequested()
                                ToolTip.text: root.isMobile ? "刷新列表" : ""
                                ToolTip.visible: root.isMobile && hovered
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
                                root.selectedTags = root.tagList.map(function(tag) {
                                    return tag.id
                                })
                            } else {
                                root.selectedTags = []
                            }
                        }
                    }

                    Label {
                        text: "标签列表"
                        font.bold: true
                        font.pixelSize: 16
                        color: "#333"
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: {
                            if (root.selectedTags.length > 0) {
                                return "已选择 " + root.selectedTags.length + " 个标签"
                            } else if (root.isFiltered) {
                                return "筛选结果: " + root.filteredTagList.length + " / " + root.tagList.length + " 个标签"
                            } else {
                                return "共 " + root.tagList.length + " 个标签"
                            }
                        }
                        font.pixelSize: 14
                        color: {
                            if (root.selectedTags.length > 0) return "#2196F3"
                            if (root.isFiltered) return "#FF9800"
                            return "#666"
                        }
                        font.weight: (root.selectedTags.length > 0 || root.isFiltered) ? Font.DemiBold : Font.Normal
                    }
                }

                // 加载指示器
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.isLoading
                    spacing: 20

                    Item { Layout.fillHeight: true }

                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        running: root.isLoading
                    }

                    Label {
                        text: "正在加载标签列表..."
                        font.pixelSize: 14
                        color: "#666"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillHeight: true }
                }

                // 标签列表
                ListView {
                    id: tagListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.isLoading && (root.isFiltered ? root.filteredTagList.length > 0 : root.tagList.length > 0)

                    model: root.isFiltered ? root.filteredTagList : root.tagList
                    spacing: 8

                    delegate: Rectangle {
                        width: tagListView.width
                        height: 100
                        color: {
                            if (isSelected) {
                                return "#E3F2FD"
                            } else if (mouseArea.containsMouse) {
                                return "#F8F9FA"
                            }
                            return "white"
                        }
                        radius: 12
                        border.color: isSelected ? "#2196F3" : "#e0e0e0"
                        border.width: isSelected ? 2 : 1

                        property bool isSelected: root.selectedTags.indexOf(modelData.id) >= 0

                        // 优化的阴影效果
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            visible: mouseArea.containsMouse || isSelected
                            color: "#20000000"
                            radius: parent.radius + 2
                            opacity: 0.8
                            z: -1
                            y: 1
                        }

                        // 动画效果
                        Behavior on color { PropertyAnimation { duration: 200 } }
                        Behavior on border.color { PropertyAnimation { duration: 200 } }
                        Behavior on scale { PropertyAnimation { duration: 150 } }

                        scale: mouseArea.pressed ? 0.98 : 1.0

                        // 点击选择
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true

                            onClicked: function(mouse) {
                                if (mouse.modifiers & Qt.ControlModifier) {
                                    toggleTagSelection(modelData)
                                } else if (mouse.button === Qt.RightButton) {
                                    // 右键菜单
                                    tagContextMenu.tagData = modelData
                                    tagContextMenu.popup()
                                }
                            }

                            onPressAndHold: {
                                toggleTagSelection(modelData)
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            // 选择框
                            CheckBox {
                                visible: root.selectedTags.length > 0 || parent.parent.isSelected
                                checked: parent.parent.isSelected
                                Layout.alignment: Qt.AlignVCenter
                                onCheckedChanged: {
                                    toggleTagSelection(modelData)
                                }
                            }

                            // 标签图标和颜色
                            Rectangle {
                                width: 48
                                height: 48
                                color: modelData.color || "#2196F3"
                                radius: 24
                                Layout.alignment: Qt.AlignVCenter

                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.icon || "🏷️"
                                    font.pixelSize: 18
                                }

                                // 优化的阴影效果
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -2
                                    color: "#30000000"
                                    radius: parent.radius + 2
                                    opacity: 0.6
                                    z: -1
                                    y: 1
                                }
                            }

                            // 标签信息
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 6

                                // 标签名称（支持搜索高亮）
                                Text {
                                    text: highlightSearchText(modelData.name || "", root.lastSearchQuery)
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                    color: "#333"
                                    textFormat: Text.RichText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // 标签描述
                                Text {
                                    text: highlightSearchText(modelData.description || "无描述", root.lastSearchQuery)
                                    font.pixelSize: 13
                                    color: "#666"
                                    textFormat: Text.RichText
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    Layout.fillWidth: true
                                }

                                // 使用统计和创建时间
                                RowLayout {
                                    spacing: 12
                                    Layout.fillWidth: true

                                    Label {
                                        text: "📊 " + (modelData.usage_count || 0) + " 次使用"
                                        font.pixelSize: 11
                                        color: "#999"
                                    }

                                    Label {
                                        text: "📅 " + (modelData.created_at ? new Date(modelData.created_at).toLocaleDateString() : "")
                                        font.pixelSize: 11
                                        color: "#999"
                                    }

                                    Item { Layout.fillWidth: true }
                                }
                            }

                            // 操作按钮
                            RowLayout {
                                spacing: 8
                                Layout.alignment: Qt.AlignVCenter

                                Button {
                                    text: "✏️ 编辑"
                                    font.pixelSize: 11
                                    implicitWidth: 70
                                    implicitHeight: 32
                                    flat: false
                                    ToolTip.text: "编辑标签信息"
                                    onClicked: {
                                        // 使用统一的对话框，设置为编辑模式
                                        unifiedTagDialog.setEditMode(modelData)
                                        unifiedTagDialog.open()
                                    }

                                    background: Rectangle {
                                        color: parent.hovered ? "#1976D2" : "#2196F3"
                                        radius: 6
                                        border.color: "#1976D2"
                                        border.width: 1

                                        // 添加动画效果
                                        Behavior on color { PropertyAnimation { duration: 150 } }
                                    }

                                    // 白色文字
                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Button {
                                    text: "📊 统计"
                                    font.pixelSize: 11
                                    implicitWidth: 70
                                    implicitHeight: 32
                                    flat: false
                                    ToolTip.text: "查看使用统计"
                                    onClicked: {
                                        tagStatsDialog.tagData = modelData
                                        tagStatsDialog.open()
                                    }

                                    background: Rectangle {
                                        color: parent.hovered ? "#388E3C" : "#4CAF50"
                                        radius: 6
                                        border.color: "#388E3C"
                                        border.width: 1

                                        // 添加动画效果
                                        Behavior on color { PropertyAnimation { duration: 150 } }
                                    }

                                    // 白色文字
                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Button {
                                    text: "🗑️ 删除"
                                    font.pixelSize: 11
                                    implicitWidth: 70
                                    implicitHeight: 32
                                    flat: false
                                    ToolTip.text: "删除此标签"
                                    onClicked: {
                                        deleteConfirmDialog.tagId = modelData.id
                                        deleteConfirmDialog.tagName = modelData.name
                                        deleteConfirmDialog.open()
                                    }

                                    background: Rectangle {
                                        color: parent.hovered ? "#D32F2F" : "#F44336"
                                        radius: 6
                                        border.color: "#D32F2F"
                                        border.width: 1

                                        // 添加动画效果
                                        Behavior on color { PropertyAnimation { duration: 150 } }
                                    }

                                    // 白色文字
                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // 空状态显示 - 完全居中
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.isLoading && (root.isFiltered ? root.filteredTagList.length === 0 : root.tagList.length === 0)

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 30
                        width: Math.min(parent.width * 0.8, 500)

                        // 图标
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 120
                            height: 120
                            color: "#f0f0f0"
                            radius: 60

                            Label {
                                text: "🏷️"
                                font.pixelSize: 48
                                color: "#bbb"
                                anchors.centerIn: parent
                            }
                        }

                        // 标题
                        Label {
                            text: "暂无标签"
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            color: "#333"
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // 描述
                        Label {
                            text: "创建第一个标签来开始管理您的邮箱分类\n标签可以帮助您更好地组织和筛选邮箱"
                            font.pixelSize: 14
                            color: "#666"
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            lineHeight: 1.4
                        }

                        // 创建按钮
                        Button {
                            text: "➕ 创建第一个标签"
                            Material.background: Material.Blue
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 180
                            implicitHeight: 50
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            onClicked: newCreateTagDialog.open()

                            // 添加阴影效果
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -4
                                color: "#4000BCD4"
                                radius: 8
                                z: -1
                                y: 2
                                opacity: 0.3
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== 内部方法 ====================

    function toggleTagSelection(tag) {
        var tagId = tag.id
        var index = root.selectedTags.indexOf(tagId)

        if (index < 0) {
            root.selectedTags.push(tagId)
        } else {
            root.selectedTags.splice(index, 1)
        }

        // 触发属性更新
        root.selectedTags = root.selectedTags.slice()

        // 更新全选状态
        root.selectAllMode = root.selectedTags.length === root.tagList.length
    }

    function clearSelection() {
        root.selectedTags = []
        root.selectAllMode = false
    }

    function performSearch() {
        if (!searchField.text || searchField.text.trim().length === 0) {
            clearSearch()
            return
        }

        root.isSearching = true
        root.lastSearchQuery = searchField.text.trim()

        // 执行本地筛选
        Qt.callLater(function() {
            var startTime = Date.now()
            var query = root.lastSearchQuery.toLowerCase()
            var filteredResults = []

            // 本地筛选逻辑 - 支持多维度搜索
            for (var i = 0; i < root.tagList.length; i++) {
                var tag = root.tagList[i]
                var matchesName = tag.name && tag.name.toLowerCase().includes(query)
                var matchesDescription = tag.description && tag.description.toLowerCase().includes(query)
                var matchesColor = tag.color && tag.color.toLowerCase().includes(query)
                var matchesIcon = tag.icon && tag.icon.includes(query)

                if (matchesName || matchesDescription || matchesColor || matchesIcon) {
                    filteredResults.push(tag)
                }
            }

            var searchTime = (Date.now() - startTime) / 1000

            // 更新筛选结果
            root.filteredTagList = filteredResults
            root.isFiltered = true

            updateSearchStats(searchField.text, filteredResults.length, searchTime)
            root.isSearching = false

            // 同时调用后端搜索（如果需要）
            root.searchTags(searchField.text)
        })
    }

    function clearSearch() {
        searchField.text = ""
        root.lastSearchQuery = ""
        root.filteredTagList = []
        root.isFiltered = false
        searchStats.visible = false
        root.searchTags("")
    }

    function updateSearchStats(query, resultCount, searchTime) {
        if (query.length > 0) {
            root.searchResultText = "搜索 \"" + query + "\" 找到 " + resultCount + " 个结果 (" + searchTime.toFixed(2) + "s)"
            searchStats.visible = true
        } else {
            searchStats.visible = false
        }
    }

    function highlightSearchText(originalText, searchQuery) {
        if (!searchQuery || searchQuery.length === 0) {
            return originalText
        }

        var regex = new RegExp("(" + searchQuery.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ")", "gi")
        return originalText.replace(regex, '<span style="background-color: #FFEB3B; color: #000;">$1</span>')
    }

    // ==================== 搜索定时器 ====================

    Timer {
        id: searchTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (searchField.text.length > 1) {
                performSearch()
            }
        }
    }

    // ==================== 右键菜单 ====================

    Menu {
        id: tagContextMenu
        property var tagData: ({})

        MenuItem {
            text: "编辑标签"
            onTriggered: {
                editTagDialog.tagData = tagContextMenu.tagData
                editTagDialog.open()
            }
        }
        MenuItem {
            text: "查看统计"
            onTriggered: {
                tagStatsDialog.tagData = tagContextMenu.tagData
                tagStatsDialog.open()
            }
        }
        MenuSeparator {}
        MenuItem {
            text: "删除标签"
            onTriggered: {
                deleteConfirmDialog.tagId = tagContextMenu.tagData.id
                deleteConfirmDialog.tagName = tagContextMenu.tagData.name
                deleteConfirmDialog.open()
            }
        }
    }


    // ==================== 编辑标签对话框 ====================

    Dialog {
        id: editTagDialog
        title: "编辑标签"
        modal: true
        anchors.centerIn: parent
        width: 450
        height: 400

        property var tagData: ({})

        ColumnLayout {
            spacing: 20
            width: parent.width

            // 标签预览
            Rectangle {
                Layout.fillWidth: true
                height: 80
                color: "#f8f9fa"
                radius: 8
                border.color: "#e0e0e0"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 15

                    Rectangle {
                        width: 50
                        height: 50
                        color: editColorField.text || "#2196F3"
                        radius: 25

                        Label {
                            anchors.centerIn: parent
                            text: editIconField.text || "🏷️"
                            font.pixelSize: 20
                        }
                    }

                    ColumnLayout {
                        spacing: 5

                        Label {
                            text: editNameField.text || "标签名称"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            color: "#333"
                        }

                        Label {
                            text: editDescField.text || "标签描述"
                            font.pixelSize: 12
                            color: "#666"
                        }
                    }
                }
            }

            // 表单字段
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                Label {
                    text: "标签名称:"
                    font.pixelSize: 14
                    color: "#333"
                }

                TextField {
                    id: editNameField
                    Layout.fillWidth: true
                    placeholderText: "输入标签名称..."
                    text: editTagDialog.tagData.name || ""
                    selectByMouse: true
                }

                Label {
                    text: "标签描述:"
                    font.pixelSize: 14
                    color: "#333"
                }

                TextField {
                    id: editDescField
                    Layout.fillWidth: true
                    placeholderText: "输入标签描述..."
                    text: editTagDialog.tagData.description || ""
                    selectByMouse: true
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
                        id: editIconField
                        Layout.fillWidth: true
                        placeholderText: "选择图标..."
                        text: editTagDialog.tagData.icon || "🏷️"
                        selectByMouse: true
                    }

                    Button {
                        text: "📝"
                        ToolTip.text: "常用图标"
                        onClicked: editIconPickerMenu.open()

                        Menu {
                            id: editIconPickerMenu
                            Repeater {
                                model: ["🏷️", "📌", "⭐", "🔥", "💼", "🎯", "📊", "🔧", "💡", "🎨"]
                                MenuItem {
                                    text: modelData
                                    onTriggered: editIconField.text = modelData
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

                    TextField {
                        id: editColorField
                        Layout.fillWidth: true
                        placeholderText: "#2196F3"
                        text: editTagDialog.tagData.color || "#2196F3"
                        selectByMouse: true
                    }

                    Button {
                        text: "🎨"
                        ToolTip.text: "预设颜色"
                        onClicked: editColorPickerMenu.open()

                        Menu {
                            id: editColorPickerMenu
                            Repeater {
                                model: ["#2196F3", "#4CAF50", "#FF9800", "#F44336", "#9C27B0", "#00BCD4", "#795548", "#607D8B"]
                                MenuItem {
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        color: modelData
                                        radius: 10
                                    }
                                    onTriggered: editColorField.text = modelData
                                }
                            }
                        }
                    }
                }
            }

            // 按钮
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
                            description: editDescField.text.trim(),
                            icon: editIconField.text.trim() || "🏷️",
                            color: editColorField.text.trim() || "#2196F3"
                        }
                        root.updateTag(editTagDialog.tagData.id, updatedData)
                        editTagDialog.close()
                    }
                }
            }
        }
    }

    // ==================== 删除确认对话框 ====================

    Dialog {
        id: deleteConfirmDialog
        title: "确认删除"
        modal: true
        anchors.centerIn: parent
        width: 400

        property int tagId: 0
        property string tagName: ""

        ColumnLayout {
            spacing: 20

            Label {
                text: "确定要删除标签 \"" + deleteConfirmDialog.tagName + "\" 吗？\n\n删除后，使用此标签的邮箱将失去此标签分类。\n此操作不可撤销。"
                wrapMode: Text.WordWrap
                Layout.preferredWidth: 350
                font.pixelSize: 14
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
                        root.deleteTag(deleteConfirmDialog.tagId)
                        deleteConfirmDialog.close()
                    }
                }
            }
        }
    }

    // ==================== 批量删除对话框 ====================

    Dialog {
        id: batchDeleteDialog
        title: "批量删除确认"
        modal: true
        anchors.centerIn: parent
        width: 450

        ColumnLayout {
            spacing: 20

            Label {
                text: "确定要删除选中的 " + root.selectedTags.length + " 个标签吗？\n\n删除后，使用这些标签的邮箱将失去相应的标签分类。\n此操作不可撤销。"
                wrapMode: Text.WordWrap
                Layout.preferredWidth: 400
                font.pixelSize: 14
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
                        root.batchDeleteTags(root.selectedTags)
                        root.clearSelection()
                        batchDeleteDialog.close()
                    }
                }
            }
        }
    }

    // ==================== 标签统计对话框 ====================

    Dialog {
        id: tagStatsDialog
        title: "标签统计"
        modal: true
        anchors.centerIn: parent
        width: 500
        height: 400

        property var tagData: ({})

        ColumnLayout {
            spacing: 20
            width: parent.width

            // 标签信息
            Rectangle {
                Layout.fillWidth: true
                height: 80
                color: "#f8f9fa"
                radius: 8
                border.color: "#e0e0e0"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 15

                    Rectangle {
                        width: 50
                        height: 50
                        color: tagStatsDialog.tagData.color || "#2196F3"
                        radius: 25

                        Label {
                            anchors.centerIn: parent
                            text: tagStatsDialog.tagData.icon || "🏷️"
                            font.pixelSize: 20
                        }
                    }

                    ColumnLayout {
                        spacing: 5

                        Label {
                            text: tagStatsDialog.tagData.name || ""
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            color: "#333"
                        }

                        Label {
                            text: tagStatsDialog.tagData.description || ""
                            font.pixelSize: 12
                            color: "#666"
                        }
                    }
                }
            }

            // 统计信息
            GridLayout {
                columns: 2
                columnSpacing: 20
                rowSpacing: 15
                Layout.fillWidth: true

                Label {
                    text: "使用次数:"
                    font.pixelSize: 14
                    color: "#333"
                }

                Label {
                    text: (tagStatsDialog.tagData.usage_count || 0) + " 次"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: "#2196F3"
                }

                Label {
                    text: "创建时间:"
                    font.pixelSize: 14
                    color: "#333"
                }

                Label {
                    text: tagStatsDialog.tagData.created_at ? new Date(tagStatsDialog.tagData.created_at).toLocaleString() : "未知"
                    font.pixelSize: 14
                    color: "#666"
                }

                Label {
                    text: "最后使用:"
                    font.pixelSize: 14
                    color: "#333"
                }

                Label {
                    text: tagStatsDialog.tagData.last_used ? new Date(tagStatsDialog.tagData.last_used).toLocaleString() : "从未使用"
                    font.pixelSize: 14
                    color: "#666"
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "关闭"
                    onClicked: tagStatsDialog.close()
                }
            }
        }
    }

    // ==================== 导出标签对话框 ====================

    Dialog {
        id: exportTagsDialog
        title: "导出标签"
        modal: true
        anchors.centerIn: parent
        width: 400

        ColumnLayout {
            spacing: 20
            width: parent.width

            Label {
                text: "选择导出格式:"
                font.pixelSize: 14
                color: "#333"
            }

            ComboBox {
                id: exportFormatCombo
                Layout.fillWidth: true
                model: ["JSON", "CSV", "Excel"]
                currentIndex: 0
            }

            CheckBox {
                id: exportSelectedOnlyCheckBox
                text: "仅导出选中的标签 (" + root.selectedTags.length + " 个)"
                enabled: root.selectedTags.length > 0
                checked: root.selectedTags.length > 0
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: exportTagsDialog.close()
                }

                Button {
                    text: "导出"
                    Material.background: Material.Blue
                    onClicked: {
                        var format = exportFormatCombo.currentText.toLowerCase()
                        root.exportTags(format)
                        exportTagsDialog.close()
                    }
                }
            }
        }
    }

    // ==================== 导入标签对话框 ====================

    Dialog {
        id: importTagsDialog
        title: "导入标签"
        modal: true
        anchors.centerIn: parent
        width: 500
        height: 400
        
        property string selectedFilePath: ""
        property string selectedFileName: ""

        ColumnLayout {
            spacing: 20
            width: parent.width

            Label {
                text: "选择要导入的标签文件:"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: "#333"
            }

            // 文件选择区域
            Rectangle {
                Layout.fillWidth: true
                height: 120
                color: selectedFilePath.length > 0 ? "#e8f5e8" : "#f8f9fa"
                radius: 8
                border.color: selectedFilePath.length > 0 ? "#4CAF50" : "#e0e0e0"
                border.width: 2

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Label {
                        text: selectedFilePath.length > 0 ? "✅" : "📁"
                        font.pixelSize: 36
                        color: selectedFilePath.length > 0 ? "#4CAF50" : "#666"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: selectedFilePath.length > 0 ? selectedFileName : "点击选择文件"
                        font.pixelSize: selectedFilePath.length > 0 ? 14 : 12
                        font.weight: selectedFilePath.length > 0 ? Font.Medium : Font.Normal
                        color: selectedFilePath.length > 0 ? "#2E7D32" : "#666"
                        Layout.alignment: Qt.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.preferredWidth: parent.width - 40
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: selectedFilePath.length > 0 ? "点击可重新选择文件" : "支持 JSON、CSV 格式"
                        font.pixelSize: 11
                        color: "#999"
                        Layout.alignment: Qt.AlignHCenter
                        visible: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("请求选择导入文件")
                        // 发送文件选择请求信号
                        root.requestFileSelection()
                    }
                    
                    hoverEnabled: true
                    onContainsMouseChanged: {
                        parent.opacity = containsMouse ? 0.8 : 1.0
                    }
                }
                
                Behavior on opacity { PropertyAnimation { duration: 150 } }
                Behavior on color { PropertyAnimation { duration: 200 } }
                Behavior on border.color { PropertyAnimation { duration: 200 } }
            }

            // 导入选项
            GroupBox {
                Layout.fillWidth: true
                title: "导入选项"
                font.pixelSize: 13
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    CheckBox {
                        id: mergeTagsCheckBox
                        text: "合并标签（保留现有标签，重名时跳过）"
                        checked: true
                        font.pixelSize: 13
                    }

                    CheckBox {
                        id: overwriteTagsCheckBox
                        text: "覆盖重名标签"
                        checked: false
                        enabled: !mergeTagsCheckBox.checked
                        font.pixelSize: 13
                    }

                    CheckBox {
                        id: importWithStatsCheckBox
                        text: "导入使用统计信息（如果可用）"
                        checked: true
                        font.pixelSize: 13
                    }
                }
            }

            // 导入预览区域（当文件选择后显示）
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                visible: selectedFilePath.length > 0
                color: "#fff3e0"
                radius: 6
                border.color: "#FF9800"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Label {
                        text: "📊"
                        font.pixelSize: 24
                        color: "#FF9800"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "准备导入：" + selectedFileName
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: "#333"
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }

                        Label {
                            text: "点击导入按钮开始导入标签数据"
                            font.pixelSize: 11
                            color: "#666"
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 10
                spacing: 12

                Button {
                    text: "取消"
                    implicitWidth: 80
                    onClicked: {
                        // 重置状态
                        selectedFilePath = ""
                        selectedFileName = ""
                        importTagsDialog.close()
                    }
                }

                Button {
                    text: "导入"
                    Material.background: Material.Blue
                    implicitWidth: 100
                    enabled: selectedFilePath.length > 0
                    onClicked: {
                        console.log("开始导入标签文件:", selectedFilePath)
                        
                        // 构建导入选项
                        var importOptions = {
                            filePath: selectedFilePath,
                            merge: mergeTagsCheckBox.checked,
                            overwrite: overwriteTagsCheckBox.checked,
                            importStats: importWithStatsCheckBox.checked
                        }
                        
                        // 发送导入信号
                        root.importTags(selectedFilePath)
                        
                        // 重置状态并关闭对话框
                        selectedFilePath = ""
                        selectedFileName = ""
                        importTagsDialog.close()
                    }
                }
            }
        }
        
        // 对话框打开时重置状态
        onOpened: {
            selectedFilePath = ""
            selectedFileName = ""
            mergeTagsCheckBox.checked = true
            overwriteTagsCheckBox.checked = false
            importWithStatsCheckBox.checked = true
        }
        
        // 提供外部调用的文件选择结果处理函数
        function onFileSelected(filePath, fileName) {
            selectedFilePath = filePath
            selectedFileName = fileName
            console.log("文件已选择:", fileName, "路径:", filePath)
        }
    }

    // ==================== 新的创建标签对话框 ====================

    CreateTagDialog {
        id: newCreateTagDialog
        
        onTagCreated: function(tagData) {
            console.log("创建标签:", JSON.stringify(tagData))
            root.createTag(tagData)
        }
    }
}
