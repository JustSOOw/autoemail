/*
 * 设计系统核心组件
 * 定义应用程序的统一设计规范，包括颜色、字体、间距、动画等
 */

pragma Singleton
import QtQuick 2.15

QtObject {
    id: designSystem

    // ==================== 颜色系统 ====================
    
    readonly property QtObject colors: QtObject {
        // 主色调 - Material Blue
        readonly property color primary: "#2196F3"
        readonly property color primaryLight: "#64B5F6"
        readonly property color primaryDark: "#1976D2"
        readonly property color primaryVariant: "#1565C0"
        
        // 辅助色调 - Material Cyan
        readonly property color secondary: "#00BCD4"
        readonly property color secondaryLight: "#4DD0E1"
        readonly property color secondaryDark: "#0097A7"
        readonly property color secondaryVariant: "#00838F"
        
        // 表面颜色
        readonly property color surface: "#FFFFFF"
        readonly property color surfaceVariant: "#F5F5F5"
        readonly property color surfaceDim: "#FAFAFA"
        readonly property color surfaceContainer: "#F8F9FA"
        readonly property color surfaceContainerHigh: "#E3F2FD"
        
        // 背景颜色
        readonly property color background: "#FAFAFA"
        readonly property color backgroundVariant: "#F5F5F5"
        
        // 文本颜色
        readonly property color onSurface: "#212121"
        readonly property color onSurfaceVariant: "#757575"
        readonly property color onBackground: "#212121"
        readonly property color onPrimary: "#FFFFFF"
        readonly property color onSecondary: "#FFFFFF"
        
        // 状态颜色
        readonly property color success: "#4CAF50"
        readonly property color successLight: "#81C784"
        readonly property color successDark: "#388E3C"
        
        readonly property color warning: "#FF9800"
        readonly property color warningLight: "#FFB74D"
        readonly property color warningDark: "#F57C00"
        
        readonly property color error: "#F44336"
        readonly property color errorLight: "#E57373"
        readonly property color errorDark: "#D32F2F"
        
        readonly property color info: "#2196F3"
        readonly property color infoLight: "#64B5F6"
        readonly property color infoDark: "#1976D2"
        
        // 边框和分割线
        readonly property color outline: "#E0E0E0"
        readonly property color outlineVariant: "#EEEEEE"
        readonly property color divider: "#E0E0E0"
        
        // 阴影颜色
        readonly property color shadow: "#40000000"
        readonly property color shadowLight: "#20000000"
        readonly property color shadowDark: "#60000000"
        
        // 覆盖层颜色
        readonly property color overlay: "#80000000"
        readonly property color overlayLight: "#40000000"
        readonly property color overlayDark: "#A0000000"
        
        // 选中状态颜色
        readonly property color selected: "#E3F2FD"
        readonly property color selectedVariant: "#BBDEFB"
        
        // 悬停状态颜色
        readonly property color hover: "#F5F5F5"
        readonly property color hoverVariant: "#EEEEEE"
        
        // 禁用状态颜色
        readonly property color disabled: "#BDBDBD"
        readonly property color disabledVariant: "#E0E0E0"
    }

    // ==================== 字体系统 ====================
    
    readonly property QtObject typography: QtObject {
        // 字体族
        readonly property string fontFamily: "Segoe UI, Microsoft YaHei, sans-serif"
        readonly property string monospaceFontFamily: "Consolas, Monaco, 'Courier New', monospace"
        
        // 标题字体
        readonly property QtObject headline: QtObject {
            readonly property int large: 32
            readonly property int medium: 28
            readonly property int small: 24
        }
        
        // 正文字体
        readonly property QtObject body: QtObject {
            readonly property int large: 16
            readonly property int medium: 14
            readonly property int small: 12
        }
        
        // 标签字体
        readonly property QtObject label: QtObject {
            readonly property int large: 14
            readonly property int medium: 12
            readonly property int small: 10
        }
        
        // 字重
        readonly property QtObject weight: QtObject {
            readonly property int light: 300
            readonly property int normal: 400
            readonly property int medium: 500
            readonly property int semiBold: 600
            readonly property int bold: 700
        }
        
        // 行高倍数
        readonly property real lineHeightMultiplier: 1.4
    }

    // ==================== 间距系统 ====================
    
    readonly property QtObject spacing: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 16
        readonly property int lg: 24
        readonly property int xl: 32
        readonly property int xxl: 48
        
        // 组件内部间距
        readonly property int componentPadding: 16
        readonly property int componentMargin: 8
        
        // 页面间距
        readonly property int pageMargin: 20
        readonly property int sectionSpacing: 24
    }

    // ==================== 圆角系统 ====================
    
    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int xs: 2
        readonly property int sm: 4
        readonly property int md: 8
        readonly property int lg: 12
        readonly property int xl: 16
        readonly property int full: 9999
    }

    // ==================== 阴影系统 ====================
    
    readonly property QtObject elevation: QtObject {
        readonly property QtObject level0: QtObject {
            readonly property int blur: 0
            readonly property int spread: 0
            readonly property int offsetX: 0
            readonly property int offsetY: 0
            readonly property color color: "transparent"
        }
        
        readonly property QtObject level1: QtObject {
            readonly property int blur: 3
            readonly property int spread: 0
            readonly property int offsetX: 0
            readonly property int offsetY: 1
            readonly property color color: designSystem.colors.shadow
        }
        
        readonly property QtObject level2: QtObject {
            readonly property int blur: 6
            readonly property int spread: 0
            readonly property int offsetX: 0
            readonly property int offsetY: 2
            readonly property color color: designSystem.colors.shadow
        }
        
        readonly property QtObject level3: QtObject {
            readonly property int blur: 10
            readonly property int spread: 0
            readonly property int offsetX: 0
            readonly property int offsetY: 4
            readonly property color color: designSystem.colors.shadow
        }
        
        readonly property QtObject level4: QtObject {
            readonly property int blur: 14
            readonly property int spread: 0
            readonly property int offsetX: 0
            readonly property int offsetY: 6
            readonly property color color: designSystem.colors.shadow
        }
        
        readonly property QtObject level5: QtObject {
            readonly property int blur: 20
            readonly property int spread: 0
            readonly property int offsetX: 0
            readonly property int offsetY: 8
            readonly property color color: designSystem.colors.shadow
        }
    }

    // ==================== 动画系统 ====================
    
    readonly property QtObject animation: QtObject {
        // 持续时间
        readonly property QtObject duration: QtObject {
            readonly property int fast: 150
            readonly property int normal: 250
            readonly property int slow: 350
            readonly property int slower: 500
        }
        
        // 缓动曲线
        readonly property QtObject easing: QtObject {
            readonly property int standard: Easing.OutCubic
            readonly property int decelerate: Easing.OutQuart
            readonly property int accelerate: Easing.InQuart
            readonly property int sharp: Easing.OutBack
            readonly property int emphasized: Easing.OutElastic
        }
    }

    // ==================== 图标系统 ====================
    
    readonly property QtObject icons: QtObject {
        // 常用图标
        readonly property string home: "🏠"
        readonly property string email: "📧"
        readonly property string settings: "⚙️"
        readonly property string search: "🔍"
        readonly property string add: "➕"
        readonly property string edit: "✏️"
        readonly property string delete: "🗑️"
        readonly property string save: "💾"
        readonly property string export: "📤"
        readonly property string import: "📥"
        readonly property string refresh: "🔄"
        readonly property string close: "✕"
        readonly property string check: "✓"
        readonly property string warning: "⚠️"
        readonly property string error: "❌"
        readonly property string success: "✅"
        readonly property string info: "ℹ️"
        readonly property string tag: "🏷️"
        readonly property string filter: "🔽"
        readonly property string sort: "↕️"
        readonly property string copy: "📋"
        readonly property string menu: "☰"
        readonly property string more: "⋯"
        readonly property string back: "⬅️"
        readonly property string forward: "➡️"
        readonly property string up: "⬆️"
        readonly property string down: "⬇️"
        
        // 图标大小
        readonly property QtObject size: QtObject {
            readonly property int small: 16
            readonly property int medium: 20
            readonly property int large: 24
            readonly property int xlarge: 32
        }
    }

    // ==================== 组件尺寸 ====================
    
    readonly property QtObject component: QtObject {
        // 按钮
        readonly property QtObject button: QtObject {
            readonly property int height: 40
            readonly property int heightSmall: 32
            readonly property int heightLarge: 48
            readonly property int minWidth: 64
        }
        
        // 输入框
        readonly property QtObject textField: QtObject {
            readonly property int height: 40
            readonly property int heightSmall: 32
            readonly property int heightLarge: 48
        }
        
        // 列表项
        readonly property QtObject listItem: QtObject {
            readonly property int height: 56
            readonly property int heightSmall: 48
            readonly property int heightLarge: 72
        }
        
        // 工具栏
        readonly property QtObject toolbar: QtObject {
            readonly property int height: 56
            readonly property int heightDense: 48
        }
        
        // 标签页
        readonly property QtObject tab: QtObject {
            readonly property int height: 48
            readonly property int minWidth: 90
        }
    }

    // ==================== 断点系统 ====================
    
    readonly property QtObject breakpoints: QtObject {
        readonly property int xs: 0      // 超小屏幕
        readonly property int sm: 600    // 小屏幕
        readonly property int md: 960    // 中等屏幕
        readonly property int lg: 1280   // 大屏幕
        readonly property int xl: 1920   // 超大屏幕
    }

    // ==================== 工具函数 ====================
    
    // 获取当前屏幕断点
    function getBreakpoint(width) {
        if (width >= breakpoints.xl) return "xl"
        if (width >= breakpoints.lg) return "lg"
        if (width >= breakpoints.md) return "md"
        if (width >= breakpoints.sm) return "sm"
        return "xs"
    }
    
    // 根据断点获取响应式值
    function getResponsiveValue(values, currentBreakpoint) {
        return values[currentBreakpoint] || values.md || values.sm || values.xs
    }
}
