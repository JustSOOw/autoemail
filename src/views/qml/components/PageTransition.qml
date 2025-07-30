/*
 * 页面转换动画组件
 * 提供多种页面切换动画效果
 */

import QtQuick 2.15

Item {
    id: root

    // ==================== 转换类型枚举 ====================
    
    enum TransitionType {
        Fade,           // 淡入淡出
        Slide,          // 滑动
        Scale,          // 缩放
        Flip,           // 翻转
        Push,           // 推入
        Cover,          // 覆盖
        Reveal,         // 揭示
        Cube,           // 立方体
        Stack           // 堆叠
    }

    // ==================== 自定义属性 ====================
    
    property int transitionType: PageTransition.TransitionType.Slide
    property int duration: DesignSystem.animation.duration.normal
    property int easingType: DesignSystem.animation.easing.standard
    property bool running: false
    property Item fromItem: null
    property Item toItem: null
    property string direction: "left" // left, right, up, down
    
    // ==================== 信号 ====================
    
    signal started()
    signal finished()

    // ==================== 主要方法 ====================
    
    function start(from, to, transType, dir) {
        if (running) return
        
        fromItem = from
        toItem = to
        if (transType !== undefined) transitionType = transType
        if (dir !== undefined) direction = dir
        
        running = true
        started()
        
        // 根据转换类型执行相应动画
        switch (transitionType) {
            case PageTransition.TransitionType.Fade:
                startFadeTransition()
                break
            case PageTransition.TransitionType.Slide:
                startSlideTransition()
                break
            case PageTransition.TransitionType.Scale:
                startScaleTransition()
                break
            case PageTransition.TransitionType.Flip:
                startFlipTransition()
                break
            case PageTransition.TransitionType.Push:
                startPushTransition()
                break
            case PageTransition.TransitionType.Cover:
                startCoverTransition()
                break
            case PageTransition.TransitionType.Reveal:
                startRevealTransition()
                break
            case PageTransition.TransitionType.Cube:
                startCubeTransition()
                break
            case PageTransition.TransitionType.Stack:
                startStackTransition()
                break
            default:
                startSlideTransition()
        }
    }

    // ==================== 淡入淡出转换 ====================
    
    function startFadeTransition() {
        if (!fromItem || !toItem) return
        
        toItem.opacity = 0.0
        toItem.visible = true
        
        fadeAnimation.start()
    }
    
    ParallelAnimation {
        id: fadeAnimation
        
        PropertyAnimation {
            target: root.fromItem
            property: "opacity"
            to: 0.0
            duration: root.duration
            easing.type: root.easingType
        }
        
        PropertyAnimation {
            target: root.toItem
            property: "opacity"
            to: 1.0
            duration: root.duration
            easing.type: root.easingType
        }
        
        onFinished: completeTransition()
    }

    // ==================== 滑动转换 ====================
    
    function startSlideTransition() {
        if (!fromItem || !toItem) return
        
        var fromX = 0, fromY = 0
        var toX = 0, toY = 0
        
        switch (direction) {
            case "left":
                toX = toItem.width
                fromX = -fromItem.width
                break
            case "right":
                toX = -toItem.width
                fromX = fromItem.width
                break
            case "up":
                toY = toItem.height
                fromY = -fromItem.height
                break
            case "down":
                toY = -toItem.height
                fromY = fromItem.height
                break
        }
        
        toItem.x = toX
        toItem.y = toY
        toItem.visible = true
        
        slideAnimation.fromX = fromX
        slideAnimation.fromY = fromY
        slideAnimation.start()
    }
    
    ParallelAnimation {
        id: slideAnimation
        
        property real fromX: 0
        property real fromY: 0
        
        PropertyAnimation {
            target: root.fromItem
            property: "x"
            to: slideAnimation.fromX
            duration: root.duration
            easing.type: root.easingType
        }
        
        PropertyAnimation {
            target: root.fromItem
            property: "y"
            to: slideAnimation.fromY
            duration: root.duration
            easing.type: root.easingType
        }
        
        PropertyAnimation {
            target: root.toItem
            property: "x"
            to: 0
            duration: root.duration
            easing.type: root.easingType
        }
        
        PropertyAnimation {
            target: root.toItem
            property: "y"
            to: 0
            duration: root.duration
            easing.type: root.easingType
        }
        
        onFinished: completeTransition()
    }

    // ==================== 缩放转换 ====================
    
    function startScaleTransition() {
        if (!fromItem || !toItem) return
        
        toItem.scale = 0.8
        toItem.opacity = 0.0
        toItem.visible = true
        
        scaleAnimation.start()
    }
    
    ParallelAnimation {
        id: scaleAnimation
        
        // 旧页面缩放退出
        ParallelAnimation {
            PropertyAnimation {
                target: root.fromItem
                property: "scale"
                to: 1.2
                duration: root.duration
                easing.type: root.easingType
            }
            
            PropertyAnimation {
                target: root.fromItem
                property: "opacity"
                to: 0.0
                duration: root.duration
                easing.type: root.easingType
            }
        }
        
        // 新页面缩放进入
        ParallelAnimation {
            PropertyAnimation {
                target: root.toItem
                property: "scale"
                to: 1.0
                duration: root.duration
                easing.type: root.easingType
            }
            
            PropertyAnimation {
                target: root.toItem
                property: "opacity"
                to: 1.0
                duration: root.duration
                easing.type: root.easingType
            }
        }
        
        onFinished: completeTransition()
    }

    // ==================== 翻转转换 ====================
    
    function startFlipTransition() {
        if (!fromItem || !toItem) return
        
        toItem.visible = false
        flipAnimation.start()
    }
    
    SequentialAnimation {
        id: flipAnimation
        
        // 第一阶段：旧页面翻转到90度
        PropertyAnimation {
            target: root.fromItem
            property: direction === "horizontal" ? "rotationY" : "rotationX"
            to: 90
            duration: root.duration / 2
            easing.type: root.easingType
        }
        
        // 切换页面
        ScriptAction {
            script: {
                fromItem.visible = false
                toItem.visible = true
                toItem[direction === "horizontal" ? "rotationY" : "rotationX"] = -90
            }
        }
        
        // 第二阶段：新页面从-90度翻转到0度
        PropertyAnimation {
            target: root.toItem
            property: direction === "horizontal" ? "rotationY" : "rotationX"
            to: 0
            duration: root.duration / 2
            easing.type: root.easingType
        }
        
        onFinished: completeTransition()
    }

    // ==================== 推入转换 ====================
    
    function startPushTransition() {
        if (!fromItem || !toItem) return
        
        var offset = direction === "left" || direction === "right" ? 
                    (direction === "left" ? toItem.width : -toItem.width) :
                    (direction === "up" ? toItem.height : -toItem.height)
        
        if (direction === "left" || direction === "right") {
            toItem.x = offset
            toItem.y = 0
        } else {
            toItem.x = 0
            toItem.y = offset
        }
        
        toItem.visible = true
        pushAnimation.offset = offset
        pushAnimation.start()
    }
    
    ParallelAnimation {
        id: pushAnimation
        
        property real offset: 0
        
        PropertyAnimation {
            target: root.fromItem
            property: root.direction === "left" || root.direction === "right" ? "x" : "y"
            to: -pushAnimation.offset
            duration: root.duration
            easing.type: root.easingType
        }
        
        PropertyAnimation {
            target: root.toItem
            property: root.direction === "left" || root.direction === "right" ? "x" : "y"
            to: 0
            duration: root.duration
            easing.type: root.easingType
        }
        
        onFinished: completeTransition()
    }

    // ==================== 堆叠转换 ====================
    
    function startStackTransition() {
        if (!fromItem || !toItem) return
        
        toItem.scale = 0.9
        toItem.opacity = 0.0
        toItem.visible = true
        
        stackAnimation.start()
    }
    
    SequentialAnimation {
        id: stackAnimation
        
        // 新页面淡入并缩放
        ParallelAnimation {
            PropertyAnimation {
                target: root.toItem
                property: "opacity"
                to: 1.0
                duration: root.duration * 0.6
                easing.type: root.easingType
            }
            
            PropertyAnimation {
                target: root.toItem
                property: "scale"
                to: 1.0
                duration: root.duration * 0.6
                easing.type: root.easingType
            }
        }
        
        // 旧页面淡出
        PropertyAnimation {
            target: root.fromItem
            property: "opacity"
            to: 0.0
            duration: root.duration * 0.4
            easing.type: root.easingType
        }
        
        onFinished: completeTransition()
    }

    // ==================== 完成转换 ====================
    
    function completeTransition() {
        // 重置属性
        if (fromItem) {
            fromItem.visible = false
            fromItem.opacity = 1.0
            fromItem.scale = 1.0
            fromItem.x = 0
            fromItem.y = 0
            fromItem.rotation = 0
            fromItem.rotationX = 0
            fromItem.rotationY = 0
        }
        
        if (toItem) {
            toItem.visible = true
            toItem.opacity = 1.0
            toItem.scale = 1.0
            toItem.x = 0
            toItem.y = 0
            toItem.rotation = 0
            toItem.rotationX = 0
            toItem.rotationY = 0
        }
        
        running = false
        finished()
    }

    // ==================== 工具方法 ====================
    
    function stop() {
        fadeAnimation.stop()
        slideAnimation.stop()
        scaleAnimation.stop()
        flipAnimation.stop()
        pushAnimation.stop()
        stackAnimation.stop()

        completeTransition()
    }

    // ==================== 高级转换效果 ====================

    function startMorphTransition() {
        if (!fromItem || !toItem) return

        // 形变转换效果
        toItem.opacity = 0.0
        toItem.visible = true

        morphAnimation.start()
    }

    ParallelAnimation {
        id: morphAnimation

        // 形状变化
        PropertyAnimation {
            target: root.fromItem
            property: "scale"
            to: 0.0
            duration: root.duration / 2
            easing.type: Easing.InBack
        }

        SequentialAnimation {
            PauseAnimation {
                duration: root.duration / 4
            }

            PropertyAnimation {
                target: root.toItem
                property: "scale"
                from: 0.0
                to: 1.0
                duration: root.duration * 3 / 4
                easing.type: Easing.OutBack
            }
        }

        // 透明度变化
        SequentialAnimation {
            PropertyAnimation {
                target: root.fromItem
                property: "opacity"
                to: 0.0
                duration: root.duration / 2
            }

            PropertyAnimation {
                target: root.toItem
                property: "opacity"
                to: 1.0
                duration: root.duration / 2
            }
        }

        onFinished: completeTransition()
    }

    // 波纹转换效果
    function startRippleTransition(centerX, centerY) {
        if (!fromItem || !toItem) return

        // 创建波纹遮罩
        var rippleMask = Qt.createQmlObject(`
            import QtQuick 2.15
            import QtGraphicalEffects 1.15

            Item {
                anchors.fill: parent

                Rectangle {
                    id: rippleCircle
                    width: 0
                    height: 0
                    radius: 0
                    color: "white"
                    x: ${centerX} - radius
                    y: ${centerY} - radius
                }

                PropertyAnimation {
                    id: rippleAnim
                    target: rippleCircle
                    properties: "width,height,radius"
                    to: Math.max(parent.width, parent.height) * 2
                    duration: ${root.duration}
                    easing.type: ${root.easingType}

                    onFinished: {
                        completeTransition()
                        parent.destroy()
                    }
                }

                Component.onCompleted: rippleAnim.start()
            }
        `, toItem.parent)

        toItem.visible = true
    }
}
