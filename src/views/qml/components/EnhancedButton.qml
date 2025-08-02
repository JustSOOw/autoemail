/*
 * 增强按钮组件
 * 基于设计系统的高级按钮，支持多种样式和动画效果
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

Button {
    id: root

    // ==================== 自定义属性 ====================
    
    // 按钮变体
    enum ButtonVariant {
        Filled,      // 填充按钮
        Outlined,    // 轮廓按钮
        Text,        // 文本按钮
        Elevated,    // 浮起按钮
        Tonal        // 色调按钮
    }
    
    property int variant: EnhancedButton.ButtonVariant.Filled
    property color customColor: DesignSystem.colors.primary
    property string iconText: ""
    property int iconSize: DesignSystem.icons.size.medium
    property bool iconOnRight: false
    property bool loading: false
    property bool enableRipple: true
    property bool enableHoverEffect: true
    property bool enablePressEffect: true
    property real cornerRadius: DesignSystem.radius.md
    
    // ==================== 基础样式 ====================
    
    implicitWidth: Math.max(DesignSystem.component.button.minWidth, 
                           contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: DesignSystem.component.button.height
    
    leftPadding: DesignSystem.spacing.md
    rightPadding: DesignSystem.spacing.md
    topPadding: DesignSystem.spacing.sm
    bottomPadding: DesignSystem.spacing.sm
    
    font.family: DesignSystem.typography.fontFamily
    font.pixelSize: DesignSystem.typography.body.medium
    font.weight: DesignSystem.typography.weight.medium

    // ==================== 背景样式 ====================
    
    background: Rectangle {
        id: backgroundRect
        radius: root.cornerRadius
        
        // 根据变体设置背景色
        color: {
            if (!root.enabled) {
                return DesignSystem.colors.disabled
            }
            
            switch (root.variant) {
                case EnhancedButton.ButtonVariant.Filled:
                    return root.customColor
                case EnhancedButton.ButtonVariant.Elevated:
                    return ThemeManager.colors.surface
                case EnhancedButton.ButtonVariant.Tonal:
                    return Qt.lighter(root.customColor, 1.8)
                case EnhancedButton.ButtonVariant.Outlined:
                case EnhancedButton.ButtonVariant.Text:
                default:
                    return "transparent"
            }
        }
        
        // 边框
        border.width: root.variant === EnhancedButton.ButtonVariant.Outlined ? 1 : 0
        border.color: root.enabled ? root.customColor : DesignSystem.colors.disabled
        
        // 阴影效果（仅浮起按钮）
        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            visible: root.variant === EnhancedButton.ButtonVariant.Elevated
            color: "#40000000"
            radius: parent.radius
            opacity: 0.3
            z: -1
            y: 2
        }
        
        // 悬停效果
        Rectangle {
            id: hoverOverlay
            anchors.fill: parent
            radius: parent.radius
            color: getHoverColor()
            opacity: root.hovered && root.enableHoverEffect ? 0.08 : 0.0
            
            Behavior on opacity {
                PropertyAnimation {
                    duration: DesignSystem.animation.duration.fast
                    easing.type: DesignSystem.animation.easing.standard
                }
            }
        }
        
        // 按压效果
        Rectangle {
            id: pressOverlay
            anchors.fill: parent
            radius: parent.radius
            color: getPressColor()
            opacity: root.pressed && root.enablePressEffect ? 0.12 : 0.0
            
            Behavior on opacity {
                PropertyAnimation {
                    duration: DesignSystem.animation.duration.fast
                    easing.type: DesignSystem.animation.easing.standard
                }
            }
        }
        
        // 简化的涟漪效果
        Rectangle {
            id: ripple
            anchors.fill: parent
            color: "transparent"
            radius: parent.radius

            Rectangle {
                anchors.centerIn: parent
                width: root.pressed ? parent.width : 0
                height: root.pressed ? parent.height : 0
                color: "#40FFFFFF"
                radius: parent.radius
                opacity: root.pressed ? 0.3 : 0

                Behavior on width { PropertyAnimation { duration: 150 } }
                Behavior on height { PropertyAnimation { duration: 150 } }
                Behavior on opacity { PropertyAnimation { duration: 150 } }
            }
        }
        
        // 按钮缩放动画
        scale: root.pressed && root.enablePressEffect ? 0.98 : 1.0
        
        Behavior on scale {
            PropertyAnimation {
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.sharp
            }
        }
    }

    // ==================== 内容区域 ====================
    
    contentItem: Row {
        spacing: root.iconText && root.text ? DesignSystem.spacing.sm : 0
        layoutDirection: root.iconOnRight ? Qt.RightToLeft : Qt.LeftToRight
        
        // 加载指示器
        BusyIndicator {
            visible: root.loading
            running: root.loading
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.iconSize
            implicitHeight: root.iconSize
            Material.accent: getContentColor()
        }
        
        // 图标
        Label {
            visible: root.iconText && !root.loading
            text: root.iconText
            font.pixelSize: root.iconSize
            color: getContentColor()
            anchors.verticalCenter: parent.verticalCenter
        }
        
        // 文本
        Label {
            visible: root.text && !root.loading
            text: root.text
            font: root.font
            color: getContentColor()
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }
    }

    // ==================== 状态管理 ====================
    
    enabled: !loading
    
    // ==================== 颜色计算方法 ====================
    
    function getContentColor() {
        if (!root.enabled) {
            return DesignSystem.colors.disabled
        }
        
        switch (root.variant) {
            case EnhancedButton.ButtonVariant.Filled:
                return DesignSystem.colors.onPrimary
            case EnhancedButton.ButtonVariant.Elevated:
                return root.customColor
            case EnhancedButton.ButtonVariant.Tonal:
                return Qt.darker(root.customColor, 1.2)
            case EnhancedButton.ButtonVariant.Outlined:
            case EnhancedButton.ButtonVariant.Text:
            default:
                return root.customColor
        }
    }
    
    function getHoverColor() {
        return getContentColor()
    }
    
    function getPressColor() {
        return getContentColor()
    }
    
    function getRippleColor() {
        return Qt.rgba(getContentColor().r, getContentColor().g, getContentColor().b, 0.2)
    }

    // ==================== 动画方法 ====================
    
    function playClickAnimation() {
        clickAnimation.start()
    }
    
    function playSuccessAnimation() {
        successAnimation.start()
    }
    
    function playErrorAnimation() {
        errorAnimation.start()
    }

    // ==================== 动画定义 ====================
    
    // 点击动画
    SequentialAnimation {
        id: clickAnimation
        
        ParallelAnimation {
            PropertyAnimation {
                target: root
                property: "scale"
                to: 0.95
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.sharp
            }
        }
        
        ParallelAnimation {
            PropertyAnimation {
                target: root
                property: "scale"
                to: 1.0
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.sharp
            }
        }
    }
    
    // 成功动画
    SequentialAnimation {
        id: successAnimation
        
        PropertyAnimation {
            target: backgroundRect
            property: "color"
            to: DesignSystem.colors.success
            duration: DesignSystem.animation.duration.normal
        }
        
        PauseAnimation {
            duration: 1000
        }
        
        PropertyAnimation {
            target: backgroundRect
            property: "color"
            to: root.customColor
            duration: DesignSystem.animation.duration.normal
        }
    }
    
    // 错误动画
    SequentialAnimation {
        id: errorAnimation
        
        PropertyAnimation {
            target: backgroundRect
            property: "color"
            to: DesignSystem.colors.error
            duration: DesignSystem.animation.duration.normal
        }
        
        // 摇摆效果
        SequentialAnimation {
            loops: 3
            PropertyAnimation {
                target: root
                property: "x"
                to: root.x + 5
                duration: 50
            }
            PropertyAnimation {
                target: root
                property: "x"
                to: root.x - 5
                duration: 100
            }
            PropertyAnimation {
                target: root
                property: "x"
                to: root.x
                duration: 50
            }
        }
        
        PropertyAnimation {
            target: backgroundRect
            property: "color"
            to: root.customColor
            duration: DesignSystem.animation.duration.normal
        }
    }

    // ==================== 键盘支持 ====================
    
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            playClickAnimation()
            clicked()
            event.accepted = true
        }
    }

    // ==================== 无障碍支持 ====================
    
    Accessible.role: Accessible.Button
    Accessible.name: root.text || root.iconText
    Accessible.description: root.ToolTip.text || ""
    Accessible.onPressAction: clicked()
}
