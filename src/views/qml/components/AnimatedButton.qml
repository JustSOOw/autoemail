/*
 * 动画按钮组件
 * 支持多种点击反馈动画和状态转换效果
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

Button {
    id: root

    // ==================== 自定义属性 ====================
    
    property string animationType: "ripple" // ripple, bounce, pulse, shake, glow
    property bool enableHoverAnimation: true
    property bool enablePressAnimation: true
    property bool enableSuccessAnimation: true
    property bool enableErrorAnimation: true
    property color rippleColor: Qt.rgba(1, 1, 1, 0.3)
    property real animationScale: 1.05
    property int animationDuration: DesignSystem.animation.duration.normal
    
    // 状态属性
    property bool isLoading: false
    property bool isSuccess: false
    property bool isError: false
    
    // ==================== 信号 ====================
    
    signal animationCompleted(string type)

    // ==================== 基础样式 ====================
    
    implicitWidth: Math.max(120, contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: 48
    
    // 自定义背景
    background: Rectangle {
        id: backgroundRect
        radius: DesignSystem.radius.md
        color: {
            if (!root.enabled) {
                return DesignSystem.colors.disabled
            } else if (root.isError) {
                return DesignSystem.colors.error
            } else if (root.isSuccess) {
                return DesignSystem.colors.success
            } else {
                return DesignSystem.colors.primary
            }
        }
        
        // 悬停效果
        Rectangle {
            id: hoverOverlay
            anchors.fill: parent
            radius: parent.radius
            color: "white"
            opacity: 0.0
            
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
            color: "black"
            opacity: 0.0
            
            Behavior on opacity {
                PropertyAnimation {
                    duration: DesignSystem.animation.duration.fast
                    easing.type: DesignSystem.animation.easing.standard
                }
            }
        }
        
        // 发光效果
        Rectangle {
            id: glowOverlay
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 0
            border.color: root.rippleColor
            
            Behavior on border.width {
                PropertyAnimation {
                    duration: DesignSystem.animation.duration.normal
                    easing.type: DesignSystem.animation.easing.standard
                }
            }
        }
        
        // 涟漪效果容器
        Item {
            id: rippleContainer
            anchors.fill: parent
            clip: true
            
            function createRipple(x, y) {
                if (root.animationType !== "ripple") return
                
                var ripple = rippleComponent.createObject(rippleContainer, {
                    "startX": x,
                    "startY": y
                })
                ripple.start()
            }
        }
    }

    // ==================== 内容项 ====================
    
    contentItem: Row {
        spacing: DesignSystem.spacing.sm
        anchors.centerIn: parent
        
        // 加载指示器
        BusyIndicator {
            visible: root.isLoading
            running: root.isLoading
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 20
            implicitHeight: 20
            
            Material.accent: root.isError ? DesignSystem.colors.error : 
                           root.isSuccess ? DesignSystem.colors.success : 
                           DesignSystem.colors.primary
        }
        
        // 状态图标
        Label {
            visible: !root.isLoading && (root.isSuccess || root.isError)
            text: root.isSuccess ? "✓" : root.isError ? "✗" : ""
            font.pixelSize: DesignSystem.typography.body.medium
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
        }
        
        // 按钮文本
        Label {
            visible: !root.isLoading || root.text
            text: {
                if (root.isLoading) return "处理中..."
                if (root.isSuccess) return "成功"
                if (root.isError) return "错误"
                return root.text
            }
            font: root.font
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ==================== 涟漪组件 ====================
    
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
            color: root.rippleColor
            
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
                    duration: root.animationDuration
                    easing.type: DesignSystem.animation.easing.standard
                }
                
                SequentialAnimation {
                    PropertyAnimation {
                        target: ripple
                        property: "opacity"
                        from: 0.6
                        to: 0.3
                        duration: root.animationDuration * 0.7
                        easing.type: DesignSystem.animation.easing.standard
                    }
                    
                    PropertyAnimation {
                        target: ripple
                        property: "opacity"
                        from: 0.3
                        to: 0.0
                        duration: root.animationDuration * 0.3
                        easing.type: DesignSystem.animation.easing.standard
                    }
                }
                
                onFinished: {
                    ripple.destroy()
                    root.animationCompleted("ripple")
                }
            }
        }
    }

    // ==================== 交互处理 ====================
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            if (root.enableHoverAnimation) {
                playHoverAnimation()
            }
        }
        
        onExited: {
            if (root.enableHoverAnimation) {
                playHoverExitAnimation()
            }
        }
        
        onPressed: function(mouse) {
            if (root.enablePressAnimation) {
                playPressAnimation()
            }
            
            // 创建涟漪效果
            rippleContainer.createRipple(mouse.x, mouse.y)
        }
        
        onReleased: {
            if (root.enablePressAnimation) {
                playReleaseAnimation()
            }
        }
        
        onClicked: {
            root.clicked()
        }
    }

    // ==================== 动画定义 ====================
    
    // 悬停动画
    function playHoverAnimation() {
        switch (root.animationType) {
            case "bounce":
                bounceHoverAnimation.start()
                break
            case "pulse":
                pulseAnimation.start()
                break
            case "glow":
                glowAnimation.start()
                break
            default:
                defaultHoverAnimation.start()
        }
    }
    
    function playHoverExitAnimation() {
        hoverExitAnimation.start()
        pulseAnimation.stop()
        glowAnimation.stop()
    }
    
    // 按压动画
    function playPressAnimation() {
        switch (root.animationType) {
            case "bounce":
                bouncePressAnimation.start()
                break
            case "shake":
                shakeAnimation.start()
                break
            default:
                defaultPressAnimation.start()
        }
    }
    
    function playReleaseAnimation() {
        releaseAnimation.start()
    }

    // 默认悬停动画
    PropertyAnimation {
        id: defaultHoverAnimation
        target: root
        property: "scale"
        to: root.animationScale
        duration: DesignSystem.animation.duration.fast
        easing.type: DesignSystem.animation.easing.standard
        
        onFinished: {
            hoverOverlay.opacity = 0.1
        }
    }
    
    PropertyAnimation {
        id: hoverExitAnimation
        target: root
        property: "scale"
        to: 1.0
        duration: DesignSystem.animation.duration.fast
        easing.type: DesignSystem.animation.easing.standard
        
        onFinished: {
            hoverOverlay.opacity = 0.0
        }
    }
    
    // 弹跳悬停动画
    SequentialAnimation {
        id: bounceHoverAnimation
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: root.animationScale * 1.1
            duration: DesignSystem.animation.duration.fast
            easing.type: Easing.OutBack
        }
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: root.animationScale
            duration: DesignSystem.animation.duration.fast
            easing.type: Easing.OutBounce
        }
    }
    
    // 脉冲动画
    SequentialAnimation {
        id: pulseAnimation
        loops: Animation.Infinite
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: root.animationScale
            duration: DesignSystem.animation.duration.normal
            easing.type: Easing.InOutSine
        }
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: 1.0
            duration: DesignSystem.animation.duration.normal
            easing.type: Easing.InOutSine
        }
    }
    
    // 发光动画
    SequentialAnimation {
        id: glowAnimation
        loops: Animation.Infinite
        
        PropertyAnimation {
            target: glowOverlay
            property: "border.width"
            to: 3
            duration: DesignSystem.animation.duration.normal
            easing.type: Easing.InOutSine
        }
        
        PropertyAnimation {
            target: glowOverlay
            property: "border.width"
            to: 0
            duration: DesignSystem.animation.duration.normal
            easing.type: Easing.InOutSine
        }
    }
    
    // 按压动画
    PropertyAnimation {
        id: defaultPressAnimation
        target: root
        property: "scale"
        to: 0.95
        duration: DesignSystem.animation.duration.fast
        easing.type: DesignSystem.animation.easing.sharp
        
        onFinished: {
            pressOverlay.opacity = 0.1
        }
    }
    
    PropertyAnimation {
        id: releaseAnimation
        target: root
        property: "scale"
        to: root.hovered ? root.animationScale : 1.0
        duration: DesignSystem.animation.duration.fast
        easing.type: DesignSystem.animation.easing.sharp
        
        onFinished: {
            pressOverlay.opacity = 0.0
        }
    }
    
    // 弹跳按压动画
    SequentialAnimation {
        id: bouncePressAnimation
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: 0.9
            duration: DesignSystem.animation.duration.fast
            easing.type: Easing.InBack
        }
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: root.animationScale
            duration: DesignSystem.animation.duration.normal
            easing.type: Easing.OutElastic
        }
    }
    
    // 摇摆动画
    SequentialAnimation {
        id: shakeAnimation
        loops: 3
        
        PropertyAnimation {
            target: root
            property: "rotation"
            to: 2
            duration: 50
            easing.type: Easing.OutCubic
        }
        
        PropertyAnimation {
            target: root
            property: "rotation"
            to: -2
            duration: 100
            easing.type: Easing.InOutCubic
        }
        
        PropertyAnimation {
            target: root
            property: "rotation"
            to: 0
            duration: 50
            easing.type: Easing.OutCubic
        }
    }

    // ==================== 状态动画 ====================
    
    function playSuccessAnimation() {
        root.isSuccess = true
        successAnimation.start()
    }
    
    function playErrorAnimation() {
        root.isError = true
        errorAnimation.start()
    }
    
    function resetState() {
        root.isLoading = false
        root.isSuccess = false
        root.isError = false
    }
    
    // 成功动画
    SequentialAnimation {
        id: successAnimation
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: 1.1
            duration: DesignSystem.animation.duration.fast
            easing.type: Easing.OutBack
        }
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: 1.0
            duration: DesignSystem.animation.duration.fast
            easing.type: Easing.OutBounce
        }
        
        onFinished: {
            root.animationCompleted("success")
            Qt.callLater(function() {
                resetState()
            })
        }
    }
    
    // 错误动画
    SequentialAnimation {
        id: errorAnimation
        
        SequentialAnimation {
            loops: 2
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
        
        onFinished: {
            root.animationCompleted("error")
            Qt.callLater(function() {
                resetState()
            })
        }
    }

    // ==================== 公共方法 ====================
    
    function startLoading() {
        root.isLoading = true
    }
    
    function stopLoading() {
        root.isLoading = false
    }
    
    function showSuccess() {
        root.isLoading = false
        playSuccessAnimation()
    }
    
    function showError() {
        root.isLoading = false
        playErrorAnimation()
    }
}
