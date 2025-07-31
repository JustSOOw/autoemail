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

    // ==================== 内部属性 ====================
    
    property bool isSearching: false
    property string searchResultText: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

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
                        text: "共 " + root.tagList.length + " 个标签"
                        font.pixelSize: 14
                        color: "#2196F3"
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
                            Layout.preferredWidth: 320
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
                                    placeholderText: activeFocus || text.length > 0 ? "" : "搜索标签名称、描述..."
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
                                text: "创建"
                                width: 80
                                height: 36
                                Material.background: Material.Blue
                                onClicked: createTagDialog.open()
                            }

                            Button {
                                text: "批量"
                                width: 80
                                height: 36
                                Material.background: Material.Purple
                                enabled: selectedTags.length > 0
                                onClicked: batchOperationMenu.open()

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
                                text: "导出"
                                width: 80
                                height: 36
                                Material.background: Material.Green
                                onClicked: exportTagsDialog.open()
                            }

                            Button {
                                text: "刷新"
                                width: 80
                                height: 36
                                Material.background: Material.Teal
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
                        text: root.selectedTags.length > 0 ?
                              "已选择 " + root.selectedTags.length + " 个标签" :
                              "共 " + root.tagList.length + " 个标签"
                        font.pixelSize: 14
                        color: root.selectedTags.length > 0 ? "#2196F3" : "#666"
                        font.weight: root.selectedTags.length > 0 ? Font.DemiBold : Font.Normal
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
                    visible: !root.isLoading && root.tagList.length > 0

                    model: root.tagList
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
                                    text: "✏️"
                                    font.pixelSize: 12
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    flat: true
                                    ToolTip.text: "编辑标签"
                                    onClicked: {
                                        editTagDialog.tagData = modelData
                                        editTagDialog.open()
                                    }

                                    background: Rectangle {
                                        color: parent.hovered ? "#E3F2FD" : "transparent"
                                        radius: 18
                                        border.color: parent.hovered ? "#2196F3" : "transparent"
                                        border.width: 1
                                    }
                                }

                                Button {
                                    text: "📊"
                                    font.pixelSize: 12
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    flat: true
                                    ToolTip.text: "查看统计"
                                    onClicked: {
                                        tagStatsDialog.tagData = modelData
                                        tagStatsDialog.open()
                                    }

                                    background: Rectangle {
                                        color: parent.hovered ? "#E8F5E8" : "transparent"
                                        radius: 18
                                        border.color: parent.hovered ? "#4CAF50" : "transparent"
                                        border.width: 1
                                    }
                                }

                                Button {
                                    text: "🗑️"
                                    font.pixelSize: 12
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    flat: true
                                    ToolTip.text: "删除标签"
                                    onClicked: {
                                        deleteConfirmDialog.tagId = modelData.id
                                        deleteConfirmDialog.tagName = modelData.name
                                        deleteConfirmDialog.open()
                                    }

                                    background: Rectangle {
                                        color: parent.hovered ? "#FFEBEE" : "transparent"
                                        radius: 18
                                        border.color: parent.hovered ? "#F44336" : "transparent"
                                        border.width: 1
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
                    visible: !root.isLoading && root.tagList.length === 0

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
                            onClicked: createTagDialog.open()

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
        root.isSearching = true
        root.lastSearchQuery = searchField.text
        var startTime = Date.now()

        // 模拟搜索延迟
        Qt.callLater(function() {
            var searchTime = (Date.now() - startTime) / 1000
            var resultCount = root.tagList.length // 实际应该是搜索结果数量

            updateSearchStats(searchField.text, resultCount, searchTime)
            root.isSearching = false

            // 调用实际搜索
            root.searchTags(searchField.text)
        })
    }

    function clearSearch() {
        searchField.text = ""
        root.lastSearchQuery = ""
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

    // ==================== 创建标签对话框 ====================

    Dialog {
        id: createTagDialog
        title: "创建标签"
        modal: true
        width: 480
        height: 500

        // 居中显示
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        background: Rectangle {
            color: "white"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 24
            anchors.fill: parent
            anchors.margins: 24

            // 标签预览区域
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: "#f8f9fa"
                radius: 12
                border.color: "#e0e0e0"
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 20

                    // 标签图标
                    Rectangle {
                        width: 60
                        height: 60
                        color: createColorField.text || "#2196F3"
                        radius: 30

                        Label {
                            anchors.centerIn: parent
                            text: createIconField.text || "🏷️"
                            font.pixelSize: 24
                        }

                        // 阴影效果
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            color: "#30000000"
                            radius: parent.radius + 2
                            z: -1
                            y: 1
                        }
                    }

                    // 标签信息
                    ColumnLayout {
                        spacing: 6

                        Label {
                            text: createNameField.text || "标签名称"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: "#333"
                        }

                        Label {
                            text: createDescField.text || "标签描述"
                            font.pixelSize: 14
                            color: "#666"
                        }
                    }
                }
            }

            // 表单字段
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 20

                // 标签名称
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "标签名称"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "#333"
                    }

                    TextField {
                        id: createNameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        placeholderText: "输入标签名称..."
                        selectByMouse: true
                        font.pixelSize: 14

                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: parent.activeFocus ? "#2196F3" : "#e0e0e0"
                            border.width: parent.activeFocus ? 2 : 1
                        }
                    }
                }

                // 标签描述
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "标签描述"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "#333"
                    }

                    TextField {
                        id: createDescField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        placeholderText: "输入标签描述..."
                        selectByMouse: true
                        font.pixelSize: 14

                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: parent.activeFocus ? "#2196F3" : "#e0e0e0"
                            border.width: parent.activeFocus ? 2 : 1
                        }
                    }
                }

                // 图标和颜色选择
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    // 标签图标
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "标签图标"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#333"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: createIconField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                placeholderText: "选择图标..."
                                text: "🏷️"
                                selectByMouse: true
                                font.pixelSize: 14

                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: parent.activeFocus ? "#2196F3" : "#e0e0e0"
                                    border.width: parent.activeFocus ? 2 : 1
                                }
                            }

                            Button {
                                text: "📝"
                                implicitWidth: 40
                                implicitHeight: 40
                                ToolTip.text: "常用图标"
                                onClicked: iconPickerMenu.open()

                                Menu {
                                    id: iconPickerMenu
                                    Repeater {
                                        model: ["🏷️", "📌", "⭐", "🔥", "💼", "🎯", "📊", "🔧", "💡", "🎨"]
                                        MenuItem {
                                            text: modelData
                                            onTriggered: createIconField.text = modelData
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 标签颜色
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "标签颜色"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#333"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: createColorField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                placeholderText: "#2196F3"
                                text: "#2196F3"
                                selectByMouse: true
                                font.pixelSize: 14

                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: parent.activeFocus ? "#2196F3" : "#e0e0e0"
                                    border.width: parent.activeFocus ? 2 : 1
                                }
                            }

                            Button {
                                text: "🎨"
                                implicitWidth: 40
                                implicitHeight: 40
                                ToolTip.text: "预设颜色"
                                onClicked: colorPickerMenu.open()

                                Menu {
                                    id: colorPickerMenu
                                    Repeater {
                                        model: ["#2196F3", "#4CAF50", "#FF9800", "#F44336", "#9C27B0", "#00BCD4", "#795548", "#607D8B"]
                                        MenuItem {
                                            Rectangle {
                                                width: 20
                                                height: 20
                                                color: modelData
                                                radius: 10
                                            }
                                            onTriggered: createColorField.text = modelData
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 分隔线
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#e0e0e0"
                Layout.topMargin: 10
            }

            // 按钮区域
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                spacing: 12

                Item { Layout.fillWidth: true }

                Button {
                    text: "取消"
                    implicitWidth: 100
                    implicitHeight: 40
                    font.pixelSize: 14
                    onClicked: {
                        resetCreateForm()
                        createTagDialog.close()
                    }

                    background: Rectangle {
                        color: parent.hovered ? "#f5f5f5" : "white"
                        radius: 8
                        border.color: "#e0e0e0"
                        border.width: 1
                    }
                }

                Button {
                    text: "创建"
                    Material.background: Material.Blue
                    implicitWidth: 100
                    implicitHeight: 40
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    enabled: createNameField.text.trim().length > 0
                    onClicked: {
                        var tagData = {
                            name: createNameField.text.trim(),
                            description: createDescField.text.trim(),
                            icon: createIconField.text.trim() || "🏷️",
                            color: createColorField.text.trim() || "#2196F3"
                        }
                        root.createTag(tagData)
                        resetCreateForm()
                        createTagDialog.close()
                    }
                }
            }
        }

        function resetCreateForm() {
            createNameField.text = ""
            createDescField.text = ""
            createIconField.text = "🏷️"
            createColorField.text = "#2196F3"
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
        width: 450

        ColumnLayout {
            spacing: 20
            width: parent.width

            Label {
                text: "选择要导入的标签文件:"
                font.pixelSize: 14
                color: "#333"
            }

            Rectangle {
                Layout.fillWidth: true
                height: 100
                color: "#f8f9fa"
                radius: 8
                border.color: "#e0e0e0"
                border.width: 2

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Label {
                        text: "📁"
                        font.pixelSize: 32
                        color: "#666"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: "点击选择文件或拖拽文件到此处"
                        font.pixelSize: 12
                        color: "#666"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // 这里应该打开文件选择对话框
                        console.log("选择导入文件")
                    }
                }
            }

            Label {
                text: "支持的文件格式: JSON, CSV"
                font.pixelSize: 12
                color: "#999"
            }

            CheckBox {
                id: mergeTagsCheckBox
                text: "合并标签（保留现有标签）"
                checked: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: importTagsDialog.close()
                }

                Button {
                    text: "导入"
                    Material.background: Material.Blue
                    enabled: false // 当选择了文件后启用
                    onClicked: {
                        // 这里应该处理文件导入
                        console.log("导入标签文件")
                        root.importTags("selected_file_path")
                        importTagsDialog.close()
                    }
                }
            }
        }
    }
}
