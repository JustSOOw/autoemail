/*
 * 微交互组件库
 * 提供各种细微的交互动画和反馈效果
 */

pragma Singleton
import QtQuick 2.15

QtObject {
    id: microInteractions

    // ==================== 按钮微交互 ====================
    
    // 按钮悬停效果
    function createButtonHover(button) {
        var hoverBehavior = Qt.createQmlObject(`
            import QtQuick 2.15
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                
                onEntered: {
                    hoverAnimation.start()
                }
                
                onExited: {
                    hoverExitAnimation.start()
                }
                
                PropertyAnimation {
                    id: hoverAnimation
                    target: parent
                    property: "scale"
                    to: 1.05
                    duration: ${DesignSystem.animation.duration.fast}
                    easing.type: ${DesignSystem.animation.easing.standard}
                }
                
                PropertyAnimation {
                    id: hoverExitAnimation
                    target: parent
                    property: "scale"
                    to: 1.0
                    duration: ${DesignSystem.animation.duration.fast}
                    easing.type: ${DesignSystem.animation.easing.standard}
                }
            }
        `, button)
        
        return hoverBehavior
    }

    // 按钮点击反馈
    function createButtonPress(button) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                PropertyAnimation {
                    target: ${button}
                    property: "scale"
                    to: 0.95
                    duration: ${DesignSystem.animation.duration.fast}
                    easing.type: ${DesignSystem.animation.easing.sharp}
                }
                PropertyAnimation {
                    target: ${button}
                    property: "scale"
                    to: 1.0
                    duration: ${DesignSystem.animation.duration.fast}
                    easing.type: ${DesignSystem.animation.easing.sharp}
                }
            }
        `, button)
    }

    // ==================== 输入框微交互 ====================
    
    // 输入框焦点动画
    function createInputFocus(inputField) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            Connections {
                target: ${inputField}
                
                function onActiveFocusChanged() {
                    if (${inputField}.activeFocus) {
                        focusInAnimation.start()
                    } else {
                        focusOutAnimation.start()
                    }
                }
                
                PropertyAnimation {
                    id: focusInAnimation
                    target: ${inputField}
                    property: "scale"
                    to: 1.02
                    duration: ${DesignSystem.animation.duration.normal}
                    easing.type: ${DesignSystem.animation.easing.standard}
                }
                
                PropertyAnimation {
                    id: focusOutAnimation
                    target: ${inputField}
                    property: "scale"
                    to: 1.0
                    duration: ${DesignSystem.animation.duration.normal}
                    easing.type: ${DesignSystem.animation.easing.standard}
                }
            }
        `, inputField)
    }

    // 输入验证反馈
    function createValidationFeedback(inputField, isValid) {
        var animation = Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                PropertyAnimation {
                    target: ${inputField}
                    property: "border.color"
                    to: "${isValid ? DesignSystem.colors.success : DesignSystem.colors.error}"
                    duration: ${DesignSystem.animation.duration.fast}
                }
                PauseAnimation {
                    duration: 1000
                }
                PropertyAnimation {
                    target: ${inputField}
                    property: "border.color"
                    to: "${DesignSystem.colors.outline}"
                    duration: ${DesignSystem.animation.duration.normal}
                }
            }
        `, inputField)
        
        animation.start()
        return animation
    }

    // ==================== 列表微交互 ====================
    
    // 列表项悬停效果
    function createListItemHover(listItem) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                
                onEntered: {
                    hoverAnimation.start()
                }
                
                onExited: {
                    hoverExitAnimation.start()
                }
                
                ParallelAnimation {
                    id: hoverAnimation
                    PropertyAnimation {
                        target: parent
                        property: "color"
                        to: "${ThemeManager.colors.hover}"
                        duration: ${DesignSystem.animation.duration.fast}
                    }
                    PropertyAnimation {
                        target: parent
                        property: "scale"
                        to: 1.01
                        duration: ${DesignSystem.animation.duration.fast}
                    }
                }
                
                ParallelAnimation {
                    id: hoverExitAnimation
                    PropertyAnimation {
                        target: parent
                        property: "color"
                        to: "${ThemeManager.colors.surface}"
                        duration: ${DesignSystem.animation.duration.fast}
                    }
                    PropertyAnimation {
                        target: parent
                        property: "scale"
                        to: 1.0
                        duration: ${DesignSystem.animation.duration.fast}
                    }
                }
            }
        `, listItem)
    }

    // 列表项选择动画
    function createListItemSelect(listItem, selected) {
        var animation = Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${listItem}
                    property: "color"
                    to: "${selected ? ThemeManager.colors.selected : ThemeManager.colors.surface}"
                    duration: ${DesignSystem.animation.duration.normal}
                    easing.type: ${DesignSystem.animation.easing.standard}
                }
                PropertyAnimation {
                    target: ${listItem}
                    property: "border.width"
                    to: ${selected ? 2 : 0}
                    duration: ${DesignSystem.animation.duration.normal}
                    easing.type: ${DesignSystem.animation.easing.standard}
                }
            }
        `, listItem)
        
        animation.start()
        return animation
    }

    // ==================== 通知微交互 ====================
    
    // 通知滑入动画
    function createNotificationSlideIn(notification, direction) {
        var fromX = 0, fromY = 0
        
        switch (direction) {
            case "top":
                fromY = -notification.height
                break
            case "bottom":
                fromY = notification.height
                break
            case "left":
                fromX = -notification.width
                break
            case "right":
                fromX = notification.width
                break
        }
        
        notification.x = fromX
        notification.y = fromY
        notification.opacity = 0
        
        var animation = Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${notification}
                    property: "x"
                    to: 0
                    duration: ${DesignSystem.animation.duration.normal}
                    easing.type: ${DesignSystem.animation.easing.sharp}
                }
                PropertyAnimation {
                    target: ${notification}
                    property: "y"
                    to: 0
                    duration: ${DesignSystem.animation.duration.normal}
                    easing.type: ${DesignSystem.animation.easing.sharp}
                }
                PropertyAnimation {
                    target: ${notification}
                    property: "opacity"
                    to: 1.0
                    duration: ${DesignSystem.animation.duration.normal}
                    easing.type: ${DesignSystem.animation.easing.standard}
                }
            }
        `, notification)
        
        animation.start()
        return animation
    }

    // 通知摇摆提醒
    function createNotificationShake(notification) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                loops: 3
                PropertyAnimation {
                    target: ${notification}
                    property: "rotation"
                    to: 2
                    duration: 100
                    easing.type: Easing.OutCubic
                }
                PropertyAnimation {
                    target: ${notification}
                    property: "rotation"
                    to: -2
                    duration: 200
                    easing.type: Easing.InOutCubic
                }
                PropertyAnimation {
                    target: ${notification}
                    property: "rotation"
                    to: 0
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
        `, notification)
    }

    // ==================== 加载微交互 ====================
    
    // 脉冲加载动画
    function createPulseLoading(element) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                loops: Animation.Infinite
                PropertyAnimation {
                    target: ${element}
                    property: "opacity"
                    to: 0.5
                    duration: ${DesignSystem.animation.duration.slow}
                    easing.type: Easing.InOutSine
                }
                PropertyAnimation {
                    target: ${element}
                    property: "opacity"
                    to: 1.0
                    duration: ${DesignSystem.animation.duration.slow}
                    easing.type: Easing.InOutSine
                }
            }
        `, element)
    }

    // 骨架屏动画
    function createSkeletonAnimation(element) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                loops: Animation.Infinite
                PropertyAnimation {
                    target: ${element}
                    property: "color"
                    to: "${ThemeManager.colors.surfaceVariant}"
                    duration: ${DesignSystem.animation.duration.slow}
                    easing.type: Easing.InOutSine
                }
                PropertyAnimation {
                    target: ${element}
                    property: "color"
                    to: "${ThemeManager.colors.surface}"
                    duration: ${DesignSystem.animation.duration.slow}
                    easing.type: Easing.InOutSine
                }
            }
        `, element)
    }

    // ==================== 状态微交互 ====================
    
    // 成功状态动画
    function createSuccessAnimation(element) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                ParallelAnimation {
                    PropertyAnimation {
                        target: ${element}
                        property: "scale"
                        to: 1.1
                        duration: ${DesignSystem.animation.duration.fast}
                        easing.type: ${DesignSystem.animation.easing.sharp}
                    }
                    PropertyAnimation {
                        target: ${element}
                        property: "color"
                        to: "${DesignSystem.colors.success}"
                        duration: ${DesignSystem.animation.duration.fast}
                    }
                }
                ParallelAnimation {
                    PropertyAnimation {
                        target: ${element}
                        property: "scale"
                        to: 1.0
                        duration: ${DesignSystem.animation.duration.normal}
                        easing.type: ${DesignSystem.animation.easing.standard}
                    }
                    PropertyAnimation {
                        target: ${element}
                        property: "color"
                        to: "${ThemeManager.colors.surface}"
                        duration: ${DesignSystem.animation.duration.slower}
                    }
                }
            }
        `, element)
    }

    // 错误状态动画
    function createErrorAnimation(element) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                // 摇摆效果
                SequentialAnimation {
                    loops: 3
                    PropertyAnimation {
                        target: ${element}
                        property: "x"
                        to: ${element}.x + 5
                        duration: 50
                    }
                    PropertyAnimation {
                        target: ${element}
                        property: "x"
                        to: ${element}.x - 5
                        duration: 100
                    }
                    PropertyAnimation {
                        target: ${element}
                        property: "x"
                        to: ${element}.x
                        duration: 50
                    }
                }
                // 颜色变化
                PropertyAnimation {
                    target: ${element}
                    property: "color"
                    to: "${DesignSystem.colors.error}"
                    duration: ${DesignSystem.animation.duration.normal}
                }
                PauseAnimation {
                    duration: 1000
                }
                PropertyAnimation {
                    target: ${element}
                    property: "color"
                    to: "${ThemeManager.colors.surface}"
                    duration: ${DesignSystem.animation.duration.normal}
                }
            }
        `, element)
    }

    // ==================== 工具方法 ====================
    
    // 创建弹性动画
    function createElasticAnimation(target, property, to, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            PropertyAnimation {
                target: ${target}
                property: "${property}"
                to: ${to}
                duration: ${duration || DesignSystem.animation.duration.normal}
                easing.type: Easing.OutElastic
            }
        `, target)
    }

    // 创建弹跳动画
    function createBounceAnimation(target, property, to, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            PropertyAnimation {
                target: ${target}
                property: "${property}"
                to: ${to}
                duration: ${duration || DesignSystem.animation.duration.normal}
                easing.type: Easing.OutBounce
            }
        `, target)
    }
}
