/*
 * 高级搜索栏组件
 * 支持实时搜索、搜索历史、高级筛选、结果高亮等功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: root

    // ==================== 自定义属性 ====================
    
    property string searchText: ""
    property var searchHistory: []
    property var searchSuggestions: []
    property bool showHistory: true
    property bool showSuggestions: true
    property bool enableAdvancedFilter: true
    property bool isSearching: false
    property int maxHistoryItems: 10
    property int searchDelay: 300
    
    // ==================== 信号 ====================
    
    signal searchRequested(string query, var filters)
    signal searchCleared()
    signal historyItemSelected(string query)
    signal advancedFilterRequested()

    // ==================== 基础样式 ====================
    
    implicitHeight: 48
    color: ThemeManager.colors.surface
    radius: DesignSystem.radius.lg
    border.width: searchField.activeFocus ? 2 : 1
    border.color: searchField.activeFocus ? DesignSystem.colors.primary : ThemeManager.colors.outline
    
    // 阴影效果
    layer.enabled: searchField.activeFocus
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 2
        radius: 8
        color: Qt.rgba(DesignSystem.colors.primary.r, 
                      DesignSystem.colors.primary.g, 
                      DesignSystem.colors.primary.b, 0.2)
        spread: 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.sm
        spacing: DesignSystem.spacing.sm

        // 搜索图标
        Label {
            text: root.isSearching ? "⏳" : "🔍"
            font.pixelSize: DesignSystem.icons.size.medium
            color: searchField.activeFocus ? DesignSystem.colors.primary : ThemeManager.colors.onSurfaceVariant
            
            // 搜索中的旋转动画
            RotationAnimation {
                target: parent
                running: root.isSearching
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1000
            }
        }

        // 搜索输入框
        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "搜索邮箱、标签或备注..."
            font.pixelSize: DesignSystem.typography.body.medium
            color: ThemeManager.colors.onSurface
            
            background: Rectangle {
                color: "transparent"
            }
            
            text: root.searchText
            
            onTextChanged: {
                root.searchText = text
                searchTimer.restart()
                
                if (text.length > 0) {
                    updateSuggestions()
                    if (root.showSuggestions && searchSuggestions.length > 0) {
                        suggestionsPopup.open()
                    }
                } else {
                    suggestionsPopup.close()
                }
            }
            
            onActiveFocusChanged: {
                if (activeFocus && text.length === 0 && root.showHistory && searchHistory.length > 0) {
                    historyPopup.open()
                }
            }
            
            Keys.onEscapePressed: {
                text = ""
                focus = false
                suggestionsPopup.close()
                historyPopup.close()
            }
            
            Keys.onReturnPressed: {
                performSearch()
                suggestionsPopup.close()
                historyPopup.close()
            }
            
            Keys.onDownPressed: {
                if (suggestionsPopup.opened) {
                    suggestionsList.forceActiveFocus()
                } else if (historyPopup.opened) {
                    historyList.forceActiveFocus()
                }
            }
        }

        // 清除按钮
        EnhancedButton {
            visible: searchField.text.length > 0
            variant: EnhancedButton.ButtonVariant.Text
            iconText: "✕"
            implicitWidth: 32
            implicitHeight: 32
            
            onClicked: {
                searchField.text = ""
                searchField.forceActiveFocus()
                root.searchCleared()
            }
        }

        // 高级筛选按钮
        EnhancedButton {
            visible: root.enableAdvancedFilter
            variant: EnhancedButton.ButtonVariant.Text
            iconText: "🔽"
            implicitWidth: 32
            implicitHeight: 32
            ToolTip.text: "高级筛选"
            
            onClicked: {
                root.advancedFilterRequested()
                advancedFilterPopup.open()
            }
        }
    }

    // ==================== 搜索定时器 ====================
    
    Timer {
        id: searchTimer
        interval: root.searchDelay
        onTriggered: {
            if (searchField.text.trim().length > 0) {
                performSearch()
            }
        }
    }

    // ==================== 搜索建议弹出框 ====================
    
    Popup {
        id: suggestionsPopup
        y: root.height + 4
        width: root.width
        height: Math.min(suggestionsList.contentHeight + 20, 200)
        
        background: Rectangle {
            color: ThemeManager.colors.surface
            radius: DesignSystem.radius.md
            border.width: 1
            border.color: ThemeManager.colors.outline
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12
                color: DesignSystem.colors.shadow
                spread: 0
            }
        }
        
        ListView {
            id: suggestionsList
            anchors.fill: parent
            anchors.margins: 10
            model: root.searchSuggestions
            
            delegate: ItemDelegate {
                width: suggestionsList.width
                height: 36
                
                contentItem: RowLayout {
                    spacing: DesignSystem.spacing.sm
                    
                    Label {
                        text: "🔍"
                        font.pixelSize: DesignSystem.icons.size.small
                        color: ThemeManager.colors.onSurfaceVariant
                    }
                    
                    Label {
                        Layout.fillWidth: true
                        text: modelData
                        font.pixelSize: DesignSystem.typography.body.medium
                        color: ThemeManager.colors.onSurface
                        elide: Text.ElideRight
                    }
                }
                
                onClicked: {
                    searchField.text = modelData
                    performSearch()
                    suggestionsPopup.close()
                }
            }
        }
    }

    // ==================== 搜索历史弹出框 ====================
    
    Popup {
        id: historyPopup
        y: root.height + 4
        width: root.width
        height: Math.min(historyList.contentHeight + 40, 250)
        
        background: Rectangle {
            color: ThemeManager.colors.surface
            radius: DesignSystem.radius.md
            border.width: 1
            border.color: ThemeManager.colors.outline
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12
                color: DesignSystem.colors.shadow
                spread: 0
            }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            
            RowLayout {
                Layout.fillWidth: true
                
                Label {
                    text: "搜索历史"
                    font.pixelSize: DesignSystem.typography.label.medium
                    font.weight: DesignSystem.typography.weight.semiBold
                    color: ThemeManager.colors.onSurfaceVariant
                }
                
                Item { Layout.fillWidth: true }
                
                EnhancedButton {
                    variant: EnhancedButton.ButtonVariant.Text
                    text: "清空"
                    font.pixelSize: DesignSystem.typography.label.small
                    implicitHeight: 24
                    
                    onClicked: {
                        clearSearchHistory()
                        historyPopup.close()
                    }
                }
            }
            
            ListView {
                id: historyList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.searchHistory
                
                delegate: ItemDelegate {
                    width: historyList.width
                    height: 36
                    
                    contentItem: RowLayout {
                        spacing: DesignSystem.spacing.sm
                        
                        Label {
                            text: "🕒"
                            font.pixelSize: DesignSystem.icons.size.small
                            color: ThemeManager.colors.onSurfaceVariant
                        }
                        
                        Label {
                            Layout.fillWidth: true
                            text: modelData
                            font.pixelSize: DesignSystem.typography.body.medium
                            color: ThemeManager.colors.onSurface
                            elide: Text.ElideRight
                        }
                        
                        EnhancedButton {
                            variant: EnhancedButton.ButtonVariant.Text
                            iconText: "✕"
                            implicitWidth: 24
                            implicitHeight: 24
                            
                            onClicked: {
                                removeFromHistory(index)
                            }
                        }
                    }
                    
                    onClicked: {
                        searchField.text = modelData
                        root.historyItemSelected(modelData)
                        performSearch()
                        historyPopup.close()
                    }
                }
            }
        }
    }

    // ==================== 高级筛选弹出框 ====================
    
    Popup {
        id: advancedFilterPopup
        y: root.height + 4
        width: 320
        height: 280
        
        background: Rectangle {
            color: ThemeManager.colors.surface
            radius: DesignSystem.radius.lg
            border.width: 1
            border.color: ThemeManager.colors.outline
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12
                color: DesignSystem.colors.shadow
                spread: 0
            }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacing.md
            spacing: DesignSystem.spacing.md
            
            Label {
                text: "高级筛选"
                font.pixelSize: DesignSystem.typography.headline.small
                font.weight: DesignSystem.typography.weight.semiBold
                color: ThemeManager.colors.onSurface
            }
            
            // 日期范围筛选
            ColumnLayout {
                Layout.fillWidth: true
                spacing: DesignSystem.spacing.xs
                
                Label {
                    text: "创建时间"
                    font.pixelSize: DesignSystem.typography.label.medium
                    color: ThemeManager.colors.onSurfaceVariant
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: DesignSystem.spacing.sm
                    
                    EnhancedTextField {
                        id: startDateField
                        Layout.fillWidth: true
                        placeholderText: "开始日期"
                        variant: EnhancedTextField.TextFieldVariant.Outlined
                    }
                    
                    Label {
                        text: "至"
                        color: ThemeManager.colors.onSurfaceVariant
                    }
                    
                    EnhancedTextField {
                        id: endDateField
                        Layout.fillWidth: true
                        placeholderText: "结束日期"
                        variant: EnhancedTextField.TextFieldVariant.Outlined
                    }
                }
            }
            
            // 状态筛选
            ColumnLayout {
                Layout.fillWidth: true
                spacing: DesignSystem.spacing.xs
                
                Label {
                    text: "状态"
                    font.pixelSize: DesignSystem.typography.label.medium
                    color: ThemeManager.colors.onSurfaceVariant
                }
                
                Flow {
                    Layout.fillWidth: true
                    spacing: DesignSystem.spacing.xs
                    
                    property var statusOptions: ["全部", "活跃", "非活跃", "归档"]
                    
                    Repeater {
                        model: parent.statusOptions
                        
                        CheckBox {
                            text: modelData
                            font.pixelSize: DesignSystem.typography.label.medium
                            checked: modelData === "全部"
                        }
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
            
            // 操作按钮
            RowLayout {
                Layout.fillWidth: true
                
                EnhancedButton {
                    text: "重置"
                    variant: EnhancedButton.ButtonVariant.Outlined
                    Layout.fillWidth: true
                    
                    onClicked: {
                        resetAdvancedFilter()
                    }
                }
                
                EnhancedButton {
                    text: "应用"
                    variant: EnhancedButton.ButtonVariant.Filled
                    Layout.fillWidth: true
                    
                    onClicked: {
                        applyAdvancedFilter()
                        advancedFilterPopup.close()
                    }
                }
            }
        }
    }

    // ==================== 方法 ====================
    
    function performSearch() {
        if (searchField.text.trim().length === 0) {
            root.searchCleared()
            return
        }
        
        root.isSearching = true
        addToHistory(searchField.text.trim())
        
        var filters = getAdvancedFilters()
        root.searchRequested(searchField.text.trim(), filters)
        
        // 模拟搜索延迟
        Qt.callLater(function() {
            root.isSearching = false
        })
    }
    
    function updateSuggestions() {
        // 这里应该根据输入文本生成搜索建议
        // 暂时使用模拟数据
        root.searchSuggestions = [
            searchField.text + "@example.com",
            searchField.text + "@test.com",
            "标签:" + searchField.text,
            "备注:" + searchField.text
        ]
    }
    
    function addToHistory(query) {
        if (root.searchHistory.indexOf(query) === -1) {
            root.searchHistory.unshift(query)
            if (root.searchHistory.length > root.maxHistoryItems) {
                root.searchHistory.pop()
            }
        }
    }
    
    function removeFromHistory(index) {
        root.searchHistory.splice(index, 1)
    }
    
    function clearSearchHistory() {
        root.searchHistory = []
    }
    
    function getAdvancedFilters() {
        return {
            startDate: startDateField.text,
            endDate: endDateField.text,
            status: getSelectedStatuses()
        }
    }
    
    function getSelectedStatuses() {
        // 获取选中的状态
        return ["活跃"] // 示例
    }
    
    function resetAdvancedFilter() {
        startDateField.text = ""
        endDateField.text = ""
        // 重置其他筛选条件
    }
    
    function applyAdvancedFilter() {
        performSearch()
    }
    
    function focusSearchField() {
        searchField.forceActiveFocus()
    }
    
    function clearSearch() {
        searchField.text = ""
        root.searchCleared()
    }
}
