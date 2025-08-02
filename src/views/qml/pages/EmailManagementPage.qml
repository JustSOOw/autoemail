/*
 * 邮箱管理页面 - 简化版本
 * 移除复杂依赖，专注于核心功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import "../components"

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
    property bool batchMode: false  // 批量模式状态
    
    // 新增：选择状态管理 - 修复UI更新问题
    property var selectedEmailsMap: ({})  // 使用对象映射而不是Set，确保QML绑定正常
    property int selectedCount: 0  // 选中数量缓存
    property int uiUpdateTrigger: 0  // UI更新触发器

    // 搜索相关属性
    property bool isSearching: false
    property string searchResultText: ""
    property var currentFilters: ({})

    // 页面初始化
    Component.onCompleted: {
        console.log("邮箱管理页面初始化")
        // 设置初始加载状态
        root.isLoading = true

        // 延迟加载数据，确保页面已完全渲染
        Qt.callLater(function() {
            // 首先加载标签数据（和标签管理页面一样的方式）
            refreshTagList()
            
            if (emailController) {
                console.log("邮箱管理页面请求刷新邮箱列表")
                emailController.refreshEmailList()
            }

            // 5秒后如果仍在加载，自动重置加载状态（防止永久加载状态）
            loadingResetTimer.start()
        })
    }

    // 安全定时器 - 防止永久加载状态
    Timer {
        id: loadingResetTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (root.isLoading) {
                console.log("安全定时器触发：重置加载状态")
                root.isLoading = false
            }
        }
    }
    property string lastSearchQuery: ""

    // 对外暴露的信号
    signal searchEmails(string keyword, string status, var tags, int page)
    signal deleteEmail(int emailId)
    signal batchDeleteEmails(var emailIds)  // 新增：批量删除邮箱信号
    signal editEmail(int emailId, var emailData)
    signal importEmails(string filePath, string format, string conflictStrategy)  // 新增：导入邮箱信号
    signal requestFileSelection()  // 新增：请求文件选择信号
    signal refreshRequested()
    signal selectAllEmailsRequested()  // 新增：请求选择所有邮箱的信号
    signal requestTagRefresh()  // 新增：请求刷新标签列表
    signal createTag(var tagData)  // 新增：创建标签信号

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
                    enabled: root.selectedCount > 0
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
                    text: "📥 导入"
                    Material.background: Material.Green
                    onClicked: emailImportDialog.open()
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

                        // 搜索框 - 浮动标签效果
                        Item {
                            Layout.preferredWidth: 360
                            height: 58  // 增加高度以容纳浮动标签

                            Rectangle {
                                id: mainSearchContainer
                                anchors.fill: parent
                                anchors.topMargin: 8  // 为浮动标签留出空间
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

                            // 浮动标签
                            Rectangle {
                                id: mainFloatingLabel
                                x: 48  // 右移以避免覆盖搜索图标
                                y: searchField.activeFocus || searchField.text.length > 0 ? 0 : 22
                                width: mainFloatingLabelText.implicitWidth + 8
                                height: 16
                                color: "white"
                                visible: true

                                Text {
                                    id: mainFloatingLabelText
                                    anchors.centerIn: parent
                                    text: "搜索邮箱地址、域名"
                                    font.pixelSize: searchField.activeFocus || searchField.text.length > 0 ? 11 : 14
                                    color: searchField.activeFocus ? "#2196F3" : "#666"
                                }

                                Behavior on y { PropertyAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { PropertyAnimation { duration: 200 } }
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

                    Button {
                        id: batchModeButton
                        text: root.batchMode ? "✓ 批量模式 (" + root.selectedCount + ")" : "☐ 批量模式"
                        font.pixelSize: 14
                        flat: true
                        enabled: root.emailList && root.emailList.length > 0
                        
                        background: Rectangle {
                            color: root.batchMode || parent.hovered ? "#E3F2FD" : "transparent"
                            radius: 6
                            border.color: root.batchMode ? "#2196F3" : (parent.hovered ? "#2196F3" : "#e0e0e0")
                            border.width: 1
                            
                            Behavior on color { PropertyAnimation { duration: 150 } }
                            Behavior on border.color { PropertyAnimation { duration: 150 } }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: root.batchMode ? "#2196F3" : "#666"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            
                            Behavior on color { PropertyAnimation { duration: 150 } }
                        }
                        
                        onClicked: {
                            if (root.batchMode) {
                                exitBatchMode()
                            } else {
                                enterBatchMode()
                            }
                            console.log("批量模式:", root.batchMode ? "激活" : "关闭")
                        }
                    }

                    CheckBox {
                        id: selectAllCheckBox
                        text: "全选"
                        font.pixelSize: 14
                        visible: root.batchMode
                        checked: root.selectAllMode
                        onClicked: {
                            if (checked) {
                                selectAllEmails()
                            } else {
                                clearAllSelection()
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
                        text: root.selectedCount > 0 ?
                              "已选择 " + root.selectedCount + " 个，共 " + root.totalEmails + " 个邮箱" :
                              "共 " + root.totalEmails + " 个邮箱"
                        font.pixelSize: 14
                        color: root.selectedCount > 0 ? "#2196F3" : "#666"
                        font.weight: root.selectedCount > 0 ? Font.DemiBold : Font.Normal

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
                    clip: true  // 启用剪裁以正确显示滚动条

                    model: root.emailList
                    spacing: 8
                    
                    // 添加滚动条
                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                        width: 12
                        
                        contentItem: Rectangle {
                            implicitWidth: 8
                            radius: 4
                            color: parent.pressed ? "#666" : "#bbb"
                            
                            // 滚动条颜色动画
                            Behavior on color {
                                PropertyAnimation { duration: 200 }
                            }
                        }
                        
                        background: Rectangle {
                            color: "#f0f0f0"
                            radius: 6
                            opacity: 0.3
                        }
                    }

                    delegate: Rectangle {
                        id: emailItem
                        width: emailListView.width
                        height: 110  // 增加高度以容纳备注信息
                        
                        // 修复UI更新问题：使用对象映射和触发器
                        property bool isSelected: {
                            root.uiUpdateTrigger; // 强制触发重新计算
                            return root.selectedEmailsMap[modelData.id] === true
                        }
                        
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
                            visible: mouseArea.containsMouse || parent.isSelected
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

                        // 点击选择
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true

                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    // 右键菜单
                                    console.log("右键菜单")
                                    return
                                }
                                
                                if (root.batchMode) {
                                    // 批量模式激活时，直接点击即可选择/取消选择
                                    toggleItemSelection(modelData.id)
                                } else if (mouse.modifiers & Qt.ControlModifier) {
                                    // 非批量模式时，Ctrl+点击激活批量模式并选择该项
                                    enterBatchMode()
                                    toggleItemSelection(modelData.id)
                                }
                            }

                            onDoubleClicked: {
                                // 双击激活批量模式并选择该邮箱
                                if (!root.batchMode) {
                                    enterBatchMode()
                                }
                                toggleItemSelection(modelData.id)
                                console.log("双击激活批量模式")
                            }

                            onPressAndHold: {
                                // 长按激活批量模式并选择该邮箱
                                if (!root.batchMode) {
                                    enterBatchMode()
                                }
                                toggleItemSelection(modelData.id)
                                console.log("长按激活批量模式")
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15
                            anchors.verticalCenter: parent.verticalCenter

                            // 选择框
                            CheckBox {
                                visible: root.batchMode
                                checked: emailItem.isSelected
                                onClicked: {
                                    // 避免与MouseArea的点击事件冲突
                                    toggleItemSelection(modelData.id)
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

                                // 备注信息显示
                                Text {
                                    text: "💭 " + (modelData.notes || "无备注")
                                    font.pixelSize: 11
                                    color: modelData.notes ? "#495057" : "#adb5bd"
                                    visible: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    font.italic: !modelData.notes
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
                                    text: "📋 复制"
                                    font.pixelSize: 11
                                    implicitWidth: 70
                                    implicitHeight: 32
                                    flat: false
                                    ToolTip.text: "复制邮箱地址"
                                    onClicked: {
                                        // 复制邮箱地址到剪贴板
                                        console.log("复制邮箱地址:", modelData.email_address)
                                        // 使用Qt内置的剪贴板功能
                                        if (typeof Qt !== 'undefined' && Qt.application && Qt.application.clipboard) {
                                            Qt.application.clipboard.text = modelData.email_address
                                            console.log("邮箱地址已复制到剪贴板")
                                        } else if (typeof clipboardHelper !== 'undefined' && clipboardHelper) {
                                            clipboardHelper.copyToClipboard(modelData.email_address)
                                        } else {
                                            console.log("剪贴板功能不可用")
                                        }
                                    }

                                    background: Rectangle {
                                        color: parent.hovered ? "#4CAF50" : "#66BB6A"
                                        radius: 6
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Button {
                                    text: "✏️ 编辑"
                                    font.pixelSize: 11
                                    implicitWidth: 70
                                    implicitHeight: 32
                                    flat: false
                                    ToolTip.text: "编辑邮箱信息（备注和标签）"
                                    onClicked: {
                                        console.log("编辑邮箱:", JSON.stringify(modelData))
                                        console.log("邮箱标签数据:", JSON.stringify(modelData.tags))
                                        console.log("可用标签列表:", JSON.stringify(root.tagList))
                                        emailEditDialog.openDialog(
                                            modelData.id,
                                            modelData.email_address,
                                            modelData.notes || "",
                                            modelData.tags || [],
                                            root.tagList || []
                                        )
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
                                    text: "🗑️ 删除"
                                    font.pixelSize: 11
                                    implicitWidth: 70
                                    implicitHeight: 32
                                    flat: false
                                    ToolTip.text: "删除此邮箱"
                                    onClicked: {
                                        console.log("删除按钮点击 - 邮箱数据:", JSON.stringify(modelData))
                                        console.log("邮箱ID:", modelData.id, "邮箱地址:", modelData.email_address)
                                        
                                        // 确保ID存在
                                        if (modelData.id) {
                                            deleteConfirmDialog.emailId = modelData.id
                                            deleteConfirmDialog.emailAddress = modelData.email_address || "未知邮箱"
                                            deleteConfirmDialog.open()
                                        } else {
                                            console.error("无法删除邮箱：邮箱ID不存在")
                                        }
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

    // 优化的选择管理函数
    function enterBatchMode() {
        root.batchMode = true
        console.log("进入批量模式")
    }
    
    function exitBatchMode() {
        root.batchMode = false
        clearAllSelection()
        console.log("退出批量模式")
    }
    
    function clearAllSelection() {
        root.selectedEmailsMap = {}
        root.selectedEmails = []
        root.selectedCount = 0
        root.selectAllMode = false
        root.uiUpdateTrigger++  // 触发UI更新
        console.log("清除所有选择")
    }
    
    function clearSelection() {
        clearAllSelection()
        root.batchMode = false
    }

    function selectAllEmails() {
        console.log("全选所有邮箱")
        
        // 清空之前的选择
        var newSelectedEmailsMap = {}
        
        // 选择当前页面的所有邮箱
        if (root.emailList && root.emailList.length > 0) {
            var newSelectedEmails = []
            for (var i = 0; i < root.emailList.length; i++) {
                var emailId = root.emailList[i].id
                newSelectedEmailsMap[emailId] = true
                newSelectedEmails.push(emailId)
            }
            
            root.selectedEmailsMap = newSelectedEmailsMap
            root.selectedEmails = newSelectedEmails
            root.selectedCount = newSelectedEmails.length
            root.selectAllMode = true
            root.uiUpdateTrigger++  // 触发UI更新
            
            console.log("当前页面选择邮箱数量:", root.selectedCount)
        }
    }

    // 供外部调用，设置全选结果
    function setAllEmailsSelected(allEmailIds) {
        var newSelectedEmailsMap = {}
        
        if (allEmailIds && allEmailIds.length > 0) {
            for (var i = 0; i < allEmailIds.length; i++) {
                newSelectedEmailsMap[allEmailIds[i]] = true
            }
        }
        
        root.selectedEmailsMap = newSelectedEmailsMap
        root.selectedEmails = allEmailIds || []
        root.selectedCount = allEmailIds ? allEmailIds.length : 0
        root.selectAllMode = true
        root.uiUpdateTrigger++  // 触发UI更新
        
        console.log("全选完成，总邮箱数量:", root.selectedCount)
    }

    function toggleItemSelection(emailId) {
        console.log("切换选择状态 - 邮箱ID:", emailId)
        
        var newSelectedEmailsMap = Object.assign({}, root.selectedEmailsMap) // 创建副本
        var newSelectedEmails = root.selectedEmails.slice()
        var wasSelected = newSelectedEmailsMap[emailId] === true
        
        if (wasSelected) {
            // 从选择列表移除
            delete newSelectedEmailsMap[emailId]
            var index = newSelectedEmails.indexOf(emailId)
            if (index >= 0) {
                newSelectedEmails.splice(index, 1)
            }
            console.log("从选择列表移除邮箱, 新总数:", newSelectedEmails.length)
        } else {
            // 添加到选择列表  
            newSelectedEmailsMap[emailId] = true
            newSelectedEmails.push(emailId)
            console.log("添加邮箱到选择列表, 新总数:", newSelectedEmails.length)
        }

        // 更新选择列表和计数
        root.selectedEmailsMap = newSelectedEmailsMap
        root.selectedEmails = newSelectedEmails
        root.selectedCount = newSelectedEmails.length
        root.uiUpdateTrigger++  // 强制触发UI更新
        
        // 更新全选状态
        root.selectAllMode = (root.selectedCount > 0 && root.selectedCount === root.emailList.length)
        
        console.log("当前选中邮箱:", root.selectedEmails)
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
        anchors.centerIn: parent
        width: 380  // 增加宽度，提供更多空间
        height: 320  // 增加高度，确保所有内容和按钮都能完整显示

        background: Rectangle {
            color: "white"
            radius: 8
            border.width: 1
            border.color: "#e0e0e0"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20  // 增加边距，提供更好的视觉效果
            spacing: 16  // 适中的间距，保持良好的布局

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

            // 按钮行 - 保持适当间距
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 44  // 增加按钮区域高度
                Layout.topMargin: 12  // 适中的顶部边距
                spacing: 12  // 增加按钮间距

                Button {
                    text: "重置"
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 36
                    onClicked: {
                        statusFilter.currentIndex = 0
                        domainFilter.text = ""
                        root.currentFilters = {}
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "应用"
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 36
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
                        console.log("确认删除邮箱 - ID:", deleteConfirmDialog.emailId, "地址:", deleteConfirmDialog.emailAddress)
                        
                        if (deleteConfirmDialog.emailId && emailController) {
                            console.log("调用emailController删除方法:", deleteConfirmDialog.emailId)
                            // 直接调用控制器的删除方法
                            emailController.deleteEmail(deleteConfirmDialog.emailId)
                            deleteConfirmDialog.close()
                        } else {
                            console.error("删除失败：邮箱ID无效或emailController不可用")
                        }
                    }
                }
            }
        }
    }



    // 创建标签对话框
    Dialog {
        id: newCreateTagDialog
        title: "创建新标签"
        modal: true
        anchors.centerIn: parent
        width: 400
        height: 350

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // 标签预览
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: "#f8f9fa"
                radius: 8
                border.color: "#e0e0e0"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        width: 40
                        height: 40
                        color: newTagColorField.text || "#2196F3"
                        radius: 20

                        Text {
                            anchors.centerIn: parent
                            text: newTagIconField.text || "🏷️"
                            font.pixelSize: 16
                        }
                    }

                    Column {
                        spacing: 2

                        Text {
                            text: newTagNameField.text || "标签名称"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: "#333"
                        }

                        Text {
                            text: newTagDescField.text || "标签描述"
                            font.pixelSize: 11
                            color: "#666"
                        }
                    }
                }
            }

            // 标签名称
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "标签名称 *"
                    font.pixelSize: 12
                    color: "#333"
                }

                TextField {
                    id: newTagNameField
                    Layout.fillWidth: true
                    placeholderText: "输入标签名称..."
                    selectByMouse: true
                }
            }

            // 标签描述
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "标签描述"
                    font.pixelSize: 12
                    color: "#333"
                }

                TextField {
                    id: newTagDescField
                    Layout.fillWidth: true
                    placeholderText: "输入标签描述（可选）..."
                    selectByMouse: true
                }
            }

            // 标签图标和颜色
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: "图标"
                        font.pixelSize: 12
                        color: "#333"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: newTagIconField
                            Layout.fillWidth: true
                            text: "🏷️"
                            selectByMouse: true
                        }

                        Button {
                            text: "📝"
                            width: 32
                            height: 32
                            onClicked: iconPickerMenu.open()

                            Menu {
                                id: iconPickerMenu
                                Repeater {
                                    model: ["🏷️", "📌", "⭐", "🔥", "💼", "🎯", "📊", "🔧", "💡", "🎨"]
                                    MenuItem {
                                        text: modelData
                                        onTriggered: newTagIconField.text = modelData
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: "颜色"
                        font.pixelSize: 12
                        color: "#333"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: newTagColorField
                            Layout.fillWidth: true
                            text: "#2196F3"
                            selectByMouse: true
                        }

                        Button {
                            text: "🎨"
                            width: 32
                            height: 32
                            onClicked: colorPickerMenu.open()

                            Menu {
                                id: colorPickerMenu
                                Repeater {
                                    model: ["#2196F3", "#4CAF50", "#FF9800", "#F44336", "#9C27B0", "#00BCD4"]
                                    MenuItem {
                                        Rectangle {
                                            width: 20
                                            height: 20
                                            color: modelData
                                            radius: 10
                                        }
                                        onTriggered: newTagColorField.text = modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 操作按钮
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: "取消"
                    onClicked: {
                        newCreateTagDialog.close()
                        clearNewTagFields()
                    }
                }

                Button {
                    text: "创建"
                    Material.background: Material.Blue
                    enabled: newTagNameField.text.trim().length > 0
                    onClicked: {
                        var tagData = {
                            name: newTagNameField.text.trim(),
                            description: newTagDescField.text.trim(),
                            icon: newTagIconField.text.trim() || "🏷️",
                            color: newTagColorField.text.trim() || "#2196F3"
                        }
                        
                        // 创建标签并添加到选中列表
                        createNewTagAndSelect(tagData)
                        newCreateTagDialog.close()
                        clearNewTagFields()
                    }
                }
            }
        }

        function clearNewTagFields() {
            newTagNameField.text = ""
            newTagDescField.text = ""
            newTagIconField.text = "🏷️"
            newTagColorField.text = "#2196F3"
        }

        function createNewTagAndSelect(tagData) {
            console.log("创建并选择新标签:", JSON.stringify(tagData))
            
            // 创建新标签对象
            var newTag = {
                id: Date.now(), // 临时ID
                name: tagData.name,
                description: tagData.description,
                color: tagData.color,
                icon: tagData.icon,
                usage_count: 0
            }
            
            // 添加到标签列表
            allTagsList.push(newTag)
            
            // 自动选择新创建的标签
            addSelectedTag(newTag)
            
            // 发送到后端创建
            if (typeof root.createTag === 'function') {
                root.createTag(tagData)
            }
        }
    }

    // 邮箱导入对话框
    EmailImportDialog {
        id: emailImportDialog

        onImportRequested: function(filePath, format, options) {
            // 发送导入信号到后端
            root.importEmails(filePath, format, options.conflictStrategy)
        }

        onImportCancelled: {
            console.log("用户取消了导入操作")
        }

        onPreviewRequested: function(filePath, format) {
            console.log("预览文件:", filePath, "格式:", format)
            // 这里可以实现文件预览功能
        }

        onFileSelectionRequested: {
            // 请求后端打开文件选择对话框
            console.log("请求文件选择")
            root.requestFileSelection()
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
                        
                        if (root.selectedEmails.length > 0 && emailController) {
                            console.log("调用emailController批量删除方法:", root.selectedEmails)
                            // 直接调用控制器的批量删除方法
                            emailController.batchDeleteEmails(root.selectedEmails)
                            root.clearSelection()
                            batchDeleteDialog.close()
                        } else {
                            console.error("没有选中的邮箱可以删除或emailController不可用")
                        }
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
                        clearAllSelection()
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
                text: "修改选中的 " + root.selectedCount + " 个邮箱状态为:"
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
                        clearAllSelection()
                    }
                }
            }
        }
    }

    // ================== 标签数据处理函数 ==================
    
    // 处理标签列表加载完成
    function onTagsLoaded(tags) {
        console.log("邮箱管理页面：标签列表已加载，数量:", tags.length)
        root.tagList = tags || []
        console.log("邮箱管理页面：当前tagList内容:", JSON.stringify(root.tagList))
        
        // 编辑对话框已删除，无需更新
    }
    
    // 刷新标签列表
    function refreshTagList() {
        console.log("邮箱管理页面：请求刷新标签列表")
        
        // 如果有tagController，尝试从数据库获取真实数据
        if (typeof tagController !== 'undefined' && tagController) {
            try {
                var result = tagController.getAllTags()
                var resultData = JSON.parse(result)
                
                if (resultData.success) {
                    root.tagList = resultData.tags || []
                    console.log("邮箱管理页面：从数据库加载了", root.tagList.length, "个标签")
                } else {
                    console.log("邮箱管理页面：数据库获取标签失败，加载备用数据")
                    loadBackupTagData()
                }
            } catch (e) {
                console.error("邮箱管理页面：获取标签异常:", e)
                loadBackupTagData()
            }
        } else {
            console.log("邮箱管理页面：tagController不可用，发送请求信号")
            root.requestTagRefresh()
            // 同时加载备用数据以确保有数据可用
            loadBackupTagData()
        }
        
        console.log("邮箱管理页面：已发送requestTagRefresh信号，等待后端响应")
    }
    
    // 加载备用标签数据
    function loadBackupTagData() {
        console.log("邮箱管理页面：清空标签数据，等待真实数据加载")
        root.tagList = []
    }
    
    // 处理标签创建成功
    function onTagCreated(tag) {
        console.log("邮箱管理页面：新标签已创建:", tag.name)
        // 重新加载标签列表
        refreshTagList()
    }

    // ==================== 邮箱编辑对话框 ====================
    
    EmailEditDialog {
        id: emailEditDialog
        
        onEditCompleted: function(emailId, notes, tagIds) {
            console.log("编辑完成 - 邮箱ID:", emailId, "备注:", notes, "标签IDs:", tagIds)
            
            if (emailController) {
                try {
                    var result = emailController.updateEmail(emailId, notes, tagIds)
                    var resultData = JSON.parse(result)
                    
                    if (resultData.success) {
                        console.log("邮箱更新成功:", resultData.message)
                        emailEditDialog.close()
                        // 刷新邮箱列表以显示更新后的数据
                        root.refreshRequested()
                    } else {
                        console.error("邮箱更新失败:", resultData.error)
                        // 可以在这里显示错误消息
                    }
                } catch (e) {
                    console.error("解析更新结果失败:", e)
                }
            } else {
                console.error("emailController不可用")
            }
            
            // 重置加载状态
            emailEditDialog.isLoading = false
        }
        
        onTagRefreshRequested: {
            console.log("编辑对话框请求刷新标签")
            refreshTagList()
            // 更新对话框中的可用标签
            emailEditDialog.availableTags = root.tagList || []
        }
        
        onTagCreationRequested: function(tagData) {
            console.log("编辑对话框请求创建标签:", JSON.stringify(tagData))
            // 发送创建标签的信号
            root.createTag(tagData)
        }
    }
}
