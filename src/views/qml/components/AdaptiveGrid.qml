/*
 * 自适应网格布局组件
 * 根据屏幕尺寸自动调整列数和间距
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15

GridLayout {
    id: root

    // ==================== 自定义属性 ====================
    
    // 响应式列数配置
    property var responsiveColumns: ({
        xs: 1,
        sm: 2,
        md: 3,
        lg: 4,
        xl: 5
    })
    
    // 响应式间距配置
    property var responsiveSpacing: ({
        xs: 8,
        sm: 12,
        md: 16,
        lg: 20,
        xl: 24
    })
    
    // 最小项目宽度
    property int minItemWidth: 200
    property int maxItemWidth: 400
    
    // 自动计算列数
    property bool autoColumns: true
    property bool maintainAspectRatio: false
    property real aspectRatio: 1.0
    
    // 当前屏幕尺寸
    readonly property string screenSize: getScreenSize()
    
    // ==================== 布局配置 ====================
    
    columns: autoColumns ? calculateOptimalColumns() : getResponsiveValue(responsiveColumns)
    columnSpacing: getResponsiveValue(responsiveSpacing)
    rowSpacing: columnSpacing
    
    // ==================== 屏幕尺寸检测 ====================
    
    function getScreenSize() {
        if (width < 480) return "xs"
        if (width < 768) return "sm"
        if (width < 1024) return "md"
        if (width < 1440) return "lg"
        return "xl"
    }
    
    function getResponsiveValue(config) {
        return config[screenSize] || config.md || 16
    }

    // ==================== 自动列数计算 ====================
    
    function calculateOptimalColumns() {
        if (!autoColumns) {
            return getResponsiveValue(responsiveColumns)
        }
        
        var availableWidth = width - (2 * anchors.margins || 0)
        var spacing = getResponsiveValue(responsiveSpacing)
        
        // 计算可以容纳的最大列数
        var maxColumns = Math.floor((availableWidth + spacing) / (minItemWidth + spacing))
        
        // 限制最大列数
        var responsiveMax = getResponsiveValue(responsiveColumns)
        maxColumns = Math.min(maxColumns, responsiveMax)
        
        // 确保至少有一列
        return Math.max(1, maxColumns)
    }

    // ==================== 项目尺寸管理 ====================
    
    function updateItemSizes() {
        var cols = columns
        var spacing = columnSpacing
        var availableWidth = width - (cols - 1) * spacing
        var itemWidth = availableWidth / cols
        
        // 限制项目宽度
        itemWidth = Math.max(minItemWidth, Math.min(maxItemWidth, itemWidth))
        
        // 更新所有子项的尺寸
        for (var i = 0; i < children.length; i++) {
            var child = children[i]
            if (child.hasOwnProperty("Layout.preferredWidth")) {
                child.Layout.preferredWidth = itemWidth
                
                if (maintainAspectRatio && child.hasOwnProperty("Layout.preferredHeight")) {
                    child.Layout.preferredHeight = itemWidth / aspectRatio
                }
            }
        }
    }

    // ==================== 动画过渡 ====================
    
    Behavior on columns {
        PropertyAnimation {
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }
    }
    
    Behavior on columnSpacing {
        PropertyAnimation {
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }
    }
    
    Behavior on rowSpacing {
        PropertyAnimation {
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }
    }

    // ==================== 监听器 ====================
    
    onWidthChanged: {
        Qt.callLater(updateItemSizes)
    }
    
    onColumnsChanged: {
        Qt.callLater(updateItemSizes)
    }
    
    onChildrenChanged: {
        Qt.callLater(updateItemSizes)
    }

    // ==================== 工具方法 ====================
    
    function setResponsiveColumns(config) {
        responsiveColumns = config
        columns = Qt.binding(function() { 
            return autoColumns ? calculateOptimalColumns() : getResponsiveValue(responsiveColumns)
        })
    }
    
    function setResponsiveSpacing(config) {
        responsiveSpacing = config
        columnSpacing = Qt.binding(function() { 
            return getResponsiveValue(responsiveSpacing)
        })
        rowSpacing = Qt.binding(function() { 
            return getResponsiveValue(responsiveSpacing)
        })
    }
    
    function getItemAt(row, column) {
        var index = row * columns + column
        return index < children.length ? children[index] : null
    }
    
    function getItemIndex(item) {
        for (var i = 0; i < children.length; i++) {
            if (children[i] === item) {
                return i
            }
        }
        return -1
    }
    
    function getItemPosition(item) {
        var index = getItemIndex(item)
        if (index === -1) return {row: -1, column: -1}
        
        return {
            row: Math.floor(index / columns),
            column: index % columns
        }
    }

    // ==================== 初始化 ====================
    
    Component.onCompleted: {
        updateItemSizes()
    }
}
