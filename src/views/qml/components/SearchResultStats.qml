/*
 * 搜索结果统计组件
 * 显示搜索结果数量、用时等统计信息
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    // ==================== 自定义属性 ====================
    
    property string searchQuery: ""
    property int totalResults: 0
    property int currentPage: 1
    property int pageSize: 20
    property real searchTime: 0.0
    property bool isSearching: false
    property var searchFilters: ({})
    
    // ==================== 计算属性 ====================
    
    readonly property int startIndex: (currentPage - 1) * pageSize + 1
    readonly property int endIndex: Math.min(currentPage * pageSize, totalResults)
    readonly property bool hasResults: totalResults > 0
    readonly property bool hasQuery: searchQuery.trim().length > 0
    
    // ==================== 基础样式 ====================
    
    implicitHeight: hasQuery ? 40 : 0
    color: ThemeManager.colors.surfaceVariant
    radius: DesignSystem.radius.sm
    border.width: 1
    border.color: ThemeManager.colors.outlineVariant
    
    visible: hasQuery
    
    // 显示/隐藏动画
    Behavior on implicitHeight {
        PropertyAnimation {
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }
    }
    
    Behavior on opacity {
        PropertyAnimation {
            duration: DesignSystem.animation.duration.fast
            easing.type: DesignSystem.animation.easing.standard
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.sm
        spacing: DesignSystem.spacing.md

        // 搜索状态图标
        Label {
            text: {
                if (isSearching) return "⏳"
                if (hasResults) return "🔍"
                return "❌"
            }
            font.pixelSize: DesignSystem.icons.size.medium
            color: {
                if (isSearching) return DesignSystem.colors.warning
                if (hasResults) return DesignSystem.colors.success
                return DesignSystem.colors.error
            }
            
            // 搜索中的动画
            RotationAnimation {
                target: parent
                running: root.isSearching
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1000
            }
        }

        // 搜索结果文本
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            // 主要结果信息
            Label {
                id: mainResultText
                Layout.fillWidth: true
                text: getMainResultText()
                font.pixelSize: DesignSystem.typography.body.medium
                font.weight: DesignSystem.typography.weight.medium
                color: ThemeManager.colors.onSurface
                elide: Text.ElideRight
            }

            // 详细信息
            Label {
                id: detailText
                Layout.fillWidth: true
                text: getDetailText()
                font.pixelSize: DesignSystem.typography.label.small
                color: ThemeManager.colors.onSurfaceVariant
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }

        // 筛选器指示
        Flow {
            Layout.preferredWidth: 120
            spacing: 4
            visible: hasActiveFilters()

            Repeater {
                model: getActiveFiltersList()

                Rectangle {
                    width: filterLabel.width + 12
                    height: 20
                    radius: 10
                    color: DesignSystem.colors.primary
                    opacity: 0.1

                    Label {
                        id: filterLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: DesignSystem.typography.label.small
                        color: DesignSystem.colors.primary
                    }
                }
            }
        }

        // 清除搜索按钮
        EnhancedButton {
            variant: EnhancedButton.ButtonVariant.Text
            iconText: "✕"
            implicitWidth: 32
            implicitHeight: 32
            ToolTip.text: "清除搜索"
            
            onClicked: {
                clearSearch()
            }
        }
    }

    // ==================== 方法 ====================
    
    function getMainResultText() {
        if (isSearching) {
            return "正在搜索 \"" + searchQuery + "\"..."
        }
        
        if (!hasResults) {
            return "未找到 \"" + searchQuery + "\" 的相关结果"
        }
        
        if (totalResults === 1) {
            return "找到 1 个结果"
        }
        
        if (totalResults <= pageSize) {
            return "找到 " + totalResults + " 个结果"
        }
        
        return "显示第 " + startIndex + "-" + endIndex + " 个结果，共 " + totalResults + " 个"
    }
    
    function getDetailText() {
        if (isSearching || !hasResults) {
            return ""
        }
        
        var details = []
        
        if (searchTime > 0) {
            details.push("用时 " + searchTime.toFixed(3) + " 秒")
        }
        
        if (hasActiveFilters()) {
            var filterCount = getActiveFiltersList().length
            details.push("应用了 " + filterCount + " 个筛选条件")
        }
        
        return details.join(" • ")
    }
    
    function hasActiveFilters() {
        if (!searchFilters) return false
        
        for (var key in searchFilters) {
            var value = searchFilters[key]
            if (value && value !== "" && value !== "全部") {
                return true
            }
        }
        return false
    }
    
    function getActiveFiltersList() {
        var filters = []
        
        if (!searchFilters) return filters
        
        if (searchFilters.status && searchFilters.status !== "全部") {
            filters.push("状态:" + searchFilters.status)
        }
        
        if (searchFilters.tags && searchFilters.tags.length > 0) {
            filters.push("标签:" + searchFilters.tags.length)
        }
        
        if (searchFilters.dateRange) {
            filters.push("日期筛选")
        }
        
        return filters
    }
    
    function updateStats(query, results, time, filters) {
        searchQuery = query
        totalResults = results
        searchTime = time
        searchFilters = filters || {}
    }
    
    function setSearching(searching) {
        isSearching = searching
    }
    
    function clearSearch() {
        searchQuery = ""
        totalResults = 0
        searchTime = 0
        searchFilters = {}
        searchCleared()
    }

    // ==================== 信号 ====================
    
    signal searchCleared()

    // ==================== 动画效果 ====================
    
    // 结果更新动画
    SequentialAnimation {
        id: updateAnimation
        
        PropertyAnimation {
            target: mainResultText
            property: "opacity"
            to: 0.5
            duration: DesignSystem.animation.duration.fast
        }
        
        PropertyAnimation {
            target: mainResultText
            property: "opacity"
            to: 1.0
            duration: DesignSystem.animation.duration.fast
        }
    }
    
    // 监听结果变化
    onTotalResultsChanged: {
        if (!isSearching) {
            updateAnimation.start()
        }
    }
    
    // 脉冲动画（搜索中）
    SequentialAnimation {
        running: root.isSearching
        loops: Animation.Infinite
        
        PropertyAnimation {
            target: root
            property: "opacity"
            to: 0.7
            duration: 800
            easing.type: Easing.InOutSine
        }
        
        PropertyAnimation {
            target: root
            property: "opacity"
            to: 1.0
            duration: 800
            easing.type: Easing.InOutSine
        }
    }
}
