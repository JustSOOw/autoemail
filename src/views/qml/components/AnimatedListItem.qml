/*
 * 动画列表项组件
 * 支持进入/退出动画、悬停效果、选择状态等
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: root

    // ==================== 自定义属性 ====================
    
    property bool selected: false
    property bool hovered: false
    property bool animateOnAppear: true
    property bool enableHoverEffect: true
    property bool enableSelectEffect: true
    property bool enableRippleEffect: true
    property int animationDelay: 0
    property alias contentItem: contentLoader.sourceComponent
    
    // ==================== 基础样式 ====================
    
    width: parent ? parent.width : 200
    height: DesignSystem.component.listItem.height
    
    color: {
        if (selected && enableSelectEffect) {
            return ThemeManager.colors.selected
        } else if (hovered && enableHoverEffect) {
            return ThemeManager.colors.hover
        } else {
            return ThemeManager.colors.surface
        }
    }
    
    radius: DesignSystem.radius.sm
    
    // 边框
    border.width: selected ? 1 : 0
    border.color: DesignSystem.colors.primary
    
    // ==================== 阴影效果 ====================
    
    layer.enabled: hovered || selected
    layer.effect: DropShadow {
        horizontalOffset: DesignSystem.elevation.level1.offsetX
        verticalOffset: DesignSystem.elevation.level1.offsetY
        radius: DesignSystem.elevation.level1.blur
        color: DesignSystem.elevation.level1.color
        spread: DesignSystem.elevation.level1.spread
        opacity: hovered ? 1.0 : 0.5
    }

    // ==================== 内容区域 ====================
    
    Loader {
        id: contentLoader
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.sm
    }

    // ==================== 交互区域 ====================
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            root.hovered = true
            hoverAnimation.start()
        }
        
        onExited: {
            root.hovered = false
            hoverExitAnimation.start()
        }
        
        onClicked: {
            clickAnimation.start()
            root.clicked()
        }
        
        onPressed: {
            if (enableRippleEffect) {
                rippleEffect.start(mouse.x, mouse.y)
            }
        }
    }

    // ==================== 涟漪效果 ====================
    
    Item {
        id: rippleContainer
        anchors.fill: parent
        clip: true
        
        function start(x, y) {
            var ripple = rippleComponent.createObject(rippleContainer, {
                "startX": x,
                "startY": y
            })
            ripple.start()
        }
    }
    
    Component {
        id: rippleComponent
        
        Rectangle {
            id: ripple
            
            property real startX: 0
            property real startY: 0
            property real maxRadius: Math.max(root.width, root.height)
            
            x: startX - radius
            y: startY - radius
            width: radius * 2
            height: radius * 2
            radius: 0
            color: Qt.rgba(DesignSystem.colors.primary.r, 
                          DesignSystem.colors.primary.g, 
                          DesignSystem.colors.primary.b, 0.2)
            
            function start() {
                rippleAnimation.start()
            }
            
            ParallelAnimation {
                id: rippleAnimation
                
                PropertyAnimation {
                    target: ripple
                    property: "radius"
                    from: 0
                    to: ripple.maxRadius
                    duration: DesignSystem.animation.duration.slow
                    easing.type: DesignSystem.animation.easing.standard
                }
                
                SequentialAnimation {
                    PropertyAnimation {
                        target: ripple
                        property: "opacity"
                        from: 0.6
                        to: 0.3
                        duration: DesignSystem.animation.duration.slow * 0.7
                        easing.type: DesignSystem.animation.easing.standard
                    }
                    
                    PropertyAnimation {
                        target: ripple
                        property: "opacity"
                        from: 0.3
                        to: 0.0
                        duration: DesignSystem.animation.duration.slow * 0.3
                        easing.type: DesignSystem.animation.easing.standard
                    }
                }
                
                onFinished: ripple.destroy()
            }
        }
    }

    // ==================== 动画定义 ====================
    
    // 进入动画
    SequentialAnimation {
        id: appearAnimation
        running: root.animateOnAppear
        
        PauseAnimation {
            duration: root.animationDelay
        }
        
        ParallelAnimation {
            PropertyAnimation {
                target: root
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: DesignSystem.animation.duration.normal
                easing.type: DesignSystem.animation.easing.standard
            }
            
            PropertyAnimation {
                target: root
                property: "y"
                from: root.y + 20
                to: root.y
                duration: DesignSystem.animation.duration.normal
                easing.type: DesignSystem.animation.easing.sharp
            }
            
            PropertyAnimation {
                target: root
                property: "scale"
                from: 0.95
                to: 1.0
                duration: DesignSystem.animation.duration.normal
                easing.type: DesignSystem.animation.easing.sharp
            }
        }
    }
    
    // 悬停进入动画
    ParallelAnimation {
        id: hoverAnimation
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: 1.02
            duration: DesignSystem.animation.duration.fast
            easing.type: DesignSystem.animation.easing.standard
        }
    }
    
    // 悬停退出动画
    ParallelAnimation {
        id: hoverExitAnimation
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: 1.0
            duration: DesignSystem.animation.duration.fast
            easing.type: DesignSystem.animation.easing.standard
        }
    }
    
    // 点击动画
    SequentialAnimation {
        id: clickAnimation
        
        ParallelAnimation {
            PropertyAnimation {
                target: root
                property: "scale"
                to: 0.98
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.sharp
            }
        }
        
        ParallelAnimation {
            PropertyAnimation {
                target: root
                property: "scale"
                to: root.hovered ? 1.02 : 1.0
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.sharp
            }
        }
    }
    
    // 选择状态动画
    Behavior on color {
        ColorAnimation {
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }
    }
    
    Behavior on border.width {
        PropertyAnimation {
            duration: DesignSystem.animation.duration.fast
            easing.type: DesignSystem.animation.easing.standard
        }
    }

    // ==================== 退出动画 ====================
    
    function playExitAnimation(onComplete) {
        exitAnimation.onComplete = onComplete
        exitAnimation.start()
    }
    
    ParallelAnimation {
        id: exitAnimation
        
        property var onComplete: null
        
        PropertyAnimation {
            target: root
            property: "opacity"
            to: 0.0
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: 0.95
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.standard
        }
        
        PropertyAnimation {
            target: root
            property: "x"
            to: root.x - 50
            duration: DesignSystem.animation.duration.normal
            easing.type: DesignSystem.animation.easing.sharp
        }
        
        onFinished: {
            if (onComplete) {
                onComplete()
            }
        }
    }

    // ==================== 信号 ====================
    
    signal clicked()
    signal doubleClicked()
    signal rightClicked()

    // ==================== 初始化 ====================
    
    Component.onCompleted: {
        if (!animateOnAppear) {
            opacity = 1.0
            scale = 1.0
        }
    }

    // ==================== 无障碍支持 ====================
    
    Accessible.role: Accessible.ListItem
    Accessible.focusable: true
    Accessible.onPressAction: clicked()
}
