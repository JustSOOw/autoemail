/*
 * 响应式布局管理器
 * 支持多屏幕适配、动态布局调整、触摸设备优化
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    // ==================== 自定义属性 ====================
    
    // 断点定义
    readonly property int breakpointXS: 480    // 超小屏幕
    readonly property int breakpointSM: 768    // 小屏幕
    readonly property int breakpointMD: 1024   // 中等屏幕
    readonly property int breakpointLG: 1440   // 大屏幕
    readonly property int breakpointXL: 1920   // 超大屏幕
    
    // 当前屏幕类型
    readonly property string screenSize: {
        if (width < breakpointXS) return "xs"
        if (width < breakpointSM) return "sm"
        if (width < breakpointMD) return "md"
        if (width < breakpointLG) return "lg"
        return "xl"
    }
    
    // 设备类型检测
    readonly property bool isMobile: screenSize === "xs" || screenSize === "sm"
    readonly property bool isTablet: screenSize === "md"
    readonly property bool isDesktop: screenSize === "lg" || screenSize === "xl"
    readonly property bool isTouchDevice: Qt.platform.os === "android" || Qt.platform.os === "ios"
    
    // 布局配置
    property bool enableResponsive: true
    property bool enableTouchOptimization: isTouchDevice
    property int minTouchTarget: 44 // 最小触摸目标尺寸
    property real scaleFactor: getScaleFactor()
    
    // 内容区域
    property alias contentItem: contentLoader.sourceComponent
    
    // ==================== 信号 ====================
    
    signal screenSizeChanged(string newSize, string oldSize)
    signal orientationChanged(bool isLandscape)

    // ==================== 屏幕尺寸监听 ====================
    
    property string previousScreenSize: ""
    
    onScreenSizeChanged: {
        if (previousScreenSize !== "" && previousScreenSize !== screenSize) {
            root.screenSizeChanged(screenSize, previousScreenSize)
        }
        previousScreenSize = screenSize
    }

    // ==================== 内容加载器 ====================
    
    Loader {
        id: contentLoader
        anchors.fill: parent
        
        // 根据屏幕尺寸调整内容
        onLoaded: {
            if (item) {
                applyResponsiveStyles(item)
            }
        }
    }

    // ==================== 响应式样式应用 ====================
    
    function applyResponsiveStyles(item) {
        if (!root.enableResponsive || !item) return
        
        // 应用基础响应式样式
        applySpacing(item)
        applyFontSizes(item)
        applyTouchOptimization(item)
        applyLayoutAdjustments(item)
    }
    
    function applySpacing(item) {
        var spacing = getResponsiveSpacing()
        
        // 递归应用间距
        function applyToChildren(parent) {
            for (var i = 0; i < parent.children.length; i++) {
                var child = parent.children[i]
                
                // 应用到布局组件
                if (child.hasOwnProperty("spacing")) {
                    child.spacing = spacing.normal
                }
                
                if (child.hasOwnProperty("margins")) {
                    child.margins = spacing.normal
                }
                
                // 应用到特定组件
                if (child.objectName === "responsiveMargins") {
                    child.anchors.margins = spacing.large
                }
                
                if (child.objectName === "responsivePadding") {
                    if (child.hasOwnProperty("padding")) {
                        child.padding = spacing.normal
                    }
                }
                
                applyToChildren(child)
            }
        }
        
        applyToChildren(item)
    }
    
    function applyFontSizes(item) {
        var fontSizes = getResponsiveFontSizes()
        
        function applyToChildren(parent) {
            for (var i = 0; i < parent.children.length; i++) {
                var child = parent.children[i]
                
                if (child.hasOwnProperty("font")) {
                    // 根据组件类型应用字体大小
                    if (child.objectName === "headline") {
                        child.font.pixelSize = fontSizes.headline
                    } else if (child.objectName === "title") {
                        child.font.pixelSize = fontSizes.title
                    } else if (child.objectName === "body") {
                        child.font.pixelSize = fontSizes.body
                    } else if (child.objectName === "caption") {
                        child.font.pixelSize = fontSizes.caption
                    }
                }
                
                applyToChildren(child)
            }
        }
        
        applyToChildren(item)
    }
    
    function applyTouchOptimization(item) {
        if (!root.enableTouchOptimization) return
        
        function applyToChildren(parent) {
            for (var i = 0; i < parent.children.length; i++) {
                var child = parent.children[i]
                
                // 优化按钮和可点击元素
                if (child.hasOwnProperty("implicitHeight") && 
                    (child.toString().indexOf("Button") !== -1 || 
                     child.hasOwnProperty("clicked"))) {
                    
                    child.implicitHeight = Math.max(child.implicitHeight, root.minTouchTarget)
                    
                    if (child.hasOwnProperty("implicitWidth")) {
                        child.implicitWidth = Math.max(child.implicitWidth, root.minTouchTarget)
                    }
                }
                
                // 优化滚动区域
                if (child.toString().indexOf("ScrollView") !== -1 || 
                    child.toString().indexOf("ListView") !== -1) {
                    
                    if (child.hasOwnProperty("flickDeceleration")) {
                        child.flickDeceleration = 1500 // 触摸设备优化
                    }
                    
                    if (child.hasOwnProperty("maximumFlickVelocity")) {
                        child.maximumFlickVelocity = 2500
                    }
                }
                
                applyToChildren(child)
            }
        }
        
        applyToChildren(item)
    }
    
    function applyLayoutAdjustments(item) {
        // 根据屏幕尺寸调整布局
        function applyToChildren(parent) {
            for (var i = 0; i < parent.children.length; i++) {
                var child = parent.children[i]
                
                // 响应式网格布局
                if (child.objectName === "responsiveGrid") {
                    var columns = getResponsiveColumns()
                    if (child.hasOwnProperty("columns")) {
                        child.columns = columns
                    }
                }
                
                // 响应式可见性
                if (child.objectName === "hideOnMobile" && root.isMobile) {
                    child.visible = false
                } else if (child.objectName === "showOnMobile" && !root.isMobile) {
                    child.visible = false
                } else if (child.objectName === "hideOnDesktop" && root.isDesktop) {
                    child.visible = false
                }
                
                // 响应式宽度
                if (child.objectName === "responsiveWidth") {
                    if (child.hasOwnProperty("Layout.preferredWidth")) {
                        child.Layout.preferredWidth = getResponsiveWidth()
                    }
                }
                
                applyToChildren(child)
            }
        }
        
        applyToChildren(item)
    }

    // ==================== 响应式值计算 ====================
    
    function getScaleFactor() {
        switch (screenSize) {
            case "xs": return 0.8
            case "sm": return 0.9
            case "md": return 1.0
            case "lg": return 1.1
            case "xl": return 1.2
            default: return 1.0
        }
    }
    
    function getResponsiveSpacing() {
        var baseSpacing = DesignSystem.spacing.md
        
        return {
            small: Math.round(baseSpacing * 0.5 * scaleFactor),
            normal: Math.round(baseSpacing * scaleFactor),
            large: Math.round(baseSpacing * 1.5 * scaleFactor),
            xlarge: Math.round(baseSpacing * 2 * scaleFactor)
        }
    }
    
    function getResponsiveFontSizes() {
        var baseFontSize = DesignSystem.typography.body.medium
        
        return {
            caption: Math.round(baseFontSize * 0.75 * scaleFactor),
            body: Math.round(baseFontSize * scaleFactor),
            title: Math.round(baseFontSize * 1.25 * scaleFactor),
            headline: Math.round(baseFontSize * 1.5 * scaleFactor)
        }
    }
    
    function getResponsiveColumns() {
        switch (screenSize) {
            case "xs": return 1
            case "sm": return 2
            case "md": return 3
            case "lg": return 4
            case "xl": return 5
            default: return 3
        }
    }
    
    function getResponsiveWidth() {
        switch (screenSize) {
            case "xs": return root.width * 0.95
            case "sm": return root.width * 0.9
            case "md": return root.width * 0.8
            case "lg": return Math.min(root.width * 0.7, 1200)
            case "xl": return Math.min(root.width * 0.6, 1400)
            default: return root.width * 0.8
        }
    }

    // ==================== 工具方法 ====================
    
    function isScreenSize(size) {
        return screenSize === size
    }
    
    function isScreenSizeOrLarger(size) {
        var sizes = ["xs", "sm", "md", "lg", "xl"]
        var currentIndex = sizes.indexOf(screenSize)
        var targetIndex = sizes.indexOf(size)
        return currentIndex >= targetIndex
    }
    
    function isScreenSizeOrSmaller(size) {
        var sizes = ["xs", "sm", "md", "lg", "xl"]
        var currentIndex = sizes.indexOf(screenSize)
        var targetIndex = sizes.indexOf(size)
        return currentIndex <= targetIndex
    }
    
    function getBreakpointValue(values) {
        // values 应该是一个对象，包含不同断点的值
        // 例如: {xs: 10, sm: 15, md: 20, lg: 25, xl: 30}
        
        if (values[screenSize] !== undefined) {
            return values[screenSize]
        }
        
        // 回退到最接近的较小断点
        var sizes = ["xl", "lg", "md", "sm", "xs"]
        var currentIndex = sizes.indexOf(screenSize)
        
        for (var i = currentIndex + 1; i < sizes.length; i++) {
            if (values[sizes[i]] !== undefined) {
                return values[sizes[i]]
            }
        }
        
        // 如果没有找到，返回第一个可用值
        for (var key in values) {
            return values[key]
        }
        
        return null
    }

    // ==================== 调试信息 ====================
    
    Rectangle {
        id: debugInfo
        visible: false // 可以通过属性控制显示
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 200
        height: 120
        color: ThemeManager.colors.surface
        border.width: 1
        border.color: ThemeManager.colors.outline
        radius: 8
        z: 1000
        
        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            
            Label {
                text: "屏幕尺寸: " + root.screenSize
                font.pixelSize: 12
                color: ThemeManager.colors.onSurface
            }
            
            Label {
                text: "分辨率: " + root.width + "x" + root.height
                font.pixelSize: 12
                color: ThemeManager.colors.onSurface
            }
            
            Label {
                text: "设备类型: " + (root.isMobile ? "移动" : root.isTablet ? "平板" : "桌面")
                font.pixelSize: 12
                color: ThemeManager.colors.onSurface
            }
            
            Label {
                text: "触摸设备: " + (root.isTouchDevice ? "是" : "否")
                font.pixelSize: 12
                color: ThemeManager.colors.onSurface
            }
            
            Label {
                text: "缩放因子: " + root.scaleFactor.toFixed(1)
                font.pixelSize: 12
                color: ThemeManager.colors.onSurface
            }
        }
    }

    // ==================== 初始化 ====================
    
    Component.onCompleted: {
        // 初始应用响应式样式
        if (contentLoader.item) {
            applyResponsiveStyles(contentLoader.item)
        }
        
        // 监听屏幕尺寸变化
        root.screenSizeChanged.connect(function(newSize, oldSize) {
            console.log("屏幕尺寸变化:", oldSize, "->", newSize)
            
            // 重新应用样式
            if (contentLoader.item) {
                applyResponsiveStyles(contentLoader.item)
            }
        })
    }
}
