/*
 * 主题管理器
 * 管理应用程序的主题切换和自定义主题
 */

pragma Singleton
import QtQuick 2.15

QtObject {
    id: themeManager

    // ==================== 主题类型 ====================
    
    enum ThemeType {
        Light,
        Dark,
        Auto
    }

    // ==================== 当前主题状态 ====================
    
    property int currentTheme: ThemeManager.ThemeType.Light
    property bool isDarkMode: currentTheme === ThemeManager.ThemeType.Dark || 
                             (currentTheme === ThemeManager.ThemeType.Auto && systemDarkMode)
    property bool systemDarkMode: false // 由系统检测设置

    // ==================== 主题颜色定义 ====================
    
    readonly property QtObject lightTheme: QtObject {
        // 主色调
        readonly property color primary: "#2196F3"
        readonly property color primaryLight: "#64B5F6"
        readonly property color primaryDark: "#1976D2"
        readonly property color primaryVariant: "#1565C0"
        
        // 辅助色调
        readonly property color secondary: "#00BCD4"
        readonly property color secondaryLight: "#4DD0E1"
        readonly property color secondaryDark: "#0097A7"
        
        // 表面和背景
        readonly property color surface: "#FFFFFF"
        readonly property color surfaceVariant: "#F5F5F5"
        readonly property color surfaceDim: "#FAFAFA"
        readonly property color surfaceContainer: "#F8F9FA"
        readonly property color surfaceContainerHigh: "#E3F2FD"
        readonly property color background: "#FAFAFA"
        readonly property color backgroundVariant: "#F5F5F5"
        
        // 文本颜色
        readonly property color textOnSurface: "#212121"
        readonly property color textOnSurfaceVariant: "#757575"
        readonly property color textOnBackground: "#212121"
        readonly property color textOnPrimary: "#FFFFFF"
        readonly property color textOnSecondary: "#FFFFFF"
        
        // 边框和分割线
        readonly property color outline: "#E0E0E0"
        readonly property color outlineVariant: "#EEEEEE"
        readonly property color divider: "#E0E0E0"
        
        // 阴影
        readonly property color shadow: "#40000000"
        readonly property color shadowLight: "#20000000"
        
        // 状态颜色
        readonly property color hover: "#F5F5F5"
        readonly property color selected: "#E3F2FD"
        readonly property color disabled: "#BDBDBD"
    }

    readonly property QtObject darkTheme: QtObject {
        // 主色调
        readonly property color primary: "#90CAF9"
        readonly property color primaryLight: "#BBDEFB"
        readonly property color primaryDark: "#64B5F6"
        readonly property color primaryVariant: "#42A5F5"
        
        // 辅助色调
        readonly property color secondary: "#4DD0E1"
        readonly property color secondaryLight: "#80DEEA"
        readonly property color secondaryDark: "#26C6DA"
        
        // 表面和背景
        readonly property color surface: "#1E1E1E"
        readonly property color surfaceVariant: "#2D2D2D"
        readonly property color surfaceDim: "#121212"
        readonly property color surfaceContainer: "#252525"
        readonly property color surfaceContainerHigh: "#333333"
        readonly property color background: "#121212"
        readonly property color backgroundVariant: "#1E1E1E"
        
        // 文本颜色
        readonly property color textOnSurface: "#FFFFFF"
        readonly property color textOnSurfaceVariant: "#CCCCCC"
        readonly property color textOnBackground: "#FFFFFF"
        readonly property color textOnPrimary: "#000000"
        readonly property color textOnSecondary: "#000000"
        
        // 边框和分割线
        readonly property color outline: "#404040"
        readonly property color outlineVariant: "#333333"
        readonly property color divider: "#404040"
        
        // 阴影
        readonly property color shadow: "#80000000"
        readonly property color shadowLight: "#40000000"
        
        // 状态颜色
        readonly property color hover: "#2D2D2D"
        readonly property color selected: "#1A237E"
        readonly property color disabled: "#666666"
    }

    // ==================== 当前主题颜色 ====================
    
    readonly property QtObject colors: isDarkMode ? darkTheme : lightTheme

    // ==================== 主题切换方法 ====================
    
    function setTheme(themeType) {
        if (themeType !== currentTheme) {
            currentTheme = themeType
            themeChanged()
            saveThemePreference()
        }
    }

    function toggleTheme() {
        if (currentTheme === ThemeManager.ThemeType.Light) {
            setTheme(ThemeManager.ThemeType.Dark)
        } else {
            setTheme(ThemeManager.ThemeType.Light)
        }
    }

    function setLightTheme() {
        setTheme(ThemeManager.ThemeType.Light)
    }

    function setDarkTheme() {
        setTheme(ThemeManager.ThemeType.Dark)
    }

    function setAutoTheme() {
        setTheme(ThemeManager.ThemeType.Auto)
    }

    // ==================== 系统主题检测 ====================
    
    function updateSystemTheme() {
        // 这里应该通过Python后端检测系统主题
        // 暂时使用时间来模拟
        var hour = new Date().getHours()
        systemDarkMode = hour < 6 || hour > 18
    }

    // ==================== 主题持久化 ====================
    
    function saveThemePreference() {
        // 保存主题偏好到本地存储
        if (typeof(Storage) !== "undefined") {
            Storage.setValue("theme", currentTheme)
        }
    }

    function loadThemePreference() {
        // 从本地存储加载主题偏好
        if (typeof(Storage) !== "undefined") {
            var savedTheme = Storage.getValue("theme", ThemeManager.ThemeType.Light)
            currentTheme = savedTheme
        }
    }

    // ==================== 自定义主题支持 ====================
    
    property var customThemes: ({})

    function registerCustomTheme(name, themeData) {
        customThemes[name] = themeData
        customThemesUpdated()
    }

    function applyCustomTheme(name) {
        if (customThemes[name]) {
            // 应用自定义主题
            console.log("应用自定义主题:", name)
        }
    }

    // ==================== 主题动画 ====================
    
    property bool enableThemeTransition: true
    property int themeTransitionDuration: 300

    function animateThemeChange(callback) {
        if (enableThemeTransition) {
            // 创建主题切换动画
            themeTransitionAnimation.callback = callback
            themeTransitionAnimation.start()
        } else {
            callback()
        }
    }

    property var themeTransitionAnimation: SequentialAnimation {
        property var callback: null
        
        PropertyAnimation {
            target: null // 将在运行时设置
            property: "opacity"
            to: 0.7
            duration: themeManager.themeTransitionDuration / 2
            easing.type: Easing.OutCubic
        }
        
        ScriptAction {
            script: {
                if (themeTransitionAnimation.callback) {
                    themeTransitionAnimation.callback()
                }
            }
        }
        
        PropertyAnimation {
            target: null // 将在运行时设置
            property: "opacity"
            to: 1.0
            duration: themeManager.themeTransitionDuration / 2
            easing.type: Easing.InCubic
        }
    }

    // ==================== 信号 ====================

    signal themeChanged()
    signal customThemesUpdated()

    // ==================== 初始化 ====================

    Component.onCompleted: {
        loadThemePreference()
        updateSystemTheme()
    }

    // ==================== 工具方法 ====================
    
    function getThemeName(themeType) {
        switch (themeType) {
            case ThemeManager.ThemeType.Light: return "浅色主题"
            case ThemeManager.ThemeType.Dark: return "深色主题"
            case ThemeManager.ThemeType.Auto: return "跟随系统"
            default: return "未知主题"
        }
    }

    function isLightTheme() {
        return !isDarkMode
    }

    function isDarkTheme() {
        return isDarkMode
    }

    // 获取对比色
    function getContrastColor(backgroundColor) {
        // 简单的对比度计算
        var r = parseInt(backgroundColor.toString().substr(1, 2), 16)
        var g = parseInt(backgroundColor.toString().substr(3, 2), 16)
        var b = parseInt(backgroundColor.toString().substr(5, 2), 16)
        var brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness > 128 ? "#000000" : "#FFFFFF"
    }

    // 获取主题适配的颜色
    function getAdaptiveColor(lightColor, darkColor) {
        return isDarkMode ? darkColor : lightColor
    }
}
