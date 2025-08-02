/*
 * 高级动画组件库
 * 提供各种复杂的动画效果和微交互
 */

pragma Singleton
import QtQuick 2.15

QtObject {
    id: animationLibrary

    // ==================== 基础动画配置 ====================
    
    readonly property QtObject config: QtObject {
        readonly property int fastDuration: 150
        readonly property int normalDuration: 250
        readonly property int slowDuration: 350
        readonly property int slowerDuration: 500
        
        readonly property int standardEasing: Easing.OutCubic
        readonly property int sharpEasing: Easing.OutBack
        readonly property int emphasizedEasing: Easing.OutElastic
    }

    // ==================== 淡入淡出动画 ====================
    
    function createFadeIn(target, duration, onComplete) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            PropertyAnimation {
                target: ${target}
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: ${duration || config.normalDuration}
                easing.type: ${config.standardEasing}
                onFinished: {
                    if (${onComplete}) ${onComplete}()
                }
            }
        `, target)
    }

    function createFadeOut(target, duration, onComplete) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            PropertyAnimation {
                target: ${target}
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: ${duration || config.normalDuration}
                easing.type: ${config.standardEasing}
                onFinished: {
                    if (${onComplete}) ${onComplete}()
                }
            }
        `, target)
    }

    // ==================== 滑动动画 ====================
    
    function createSlideInFromLeft(target, distance, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "x"
                    from: ${target}.x - ${distance || 100}
                    to: ${target}.x
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.sharpEasing}
                }
                PropertyAnimation {
                    target: ${target}
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.standardEasing}
                }
            }
        `, target)
    }

    function createSlideInFromRight(target, distance, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "x"
                    from: ${target}.x + ${distance || 100}
                    to: ${target}.x
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.sharpEasing}
                }
                PropertyAnimation {
                    target: ${target}
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.standardEasing}
                }
            }
        `, target)
    }

    function createSlideInFromTop(target, distance, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "y"
                    from: ${target}.y - ${distance || 100}
                    to: ${target}.y
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.sharpEasing}
                }
                PropertyAnimation {
                    target: ${target}
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.standardEasing}
                }
            }
        `, target)
    }

    function createSlideInFromBottom(target, distance, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "y"
                    from: ${target}.y + ${distance || 100}
                    to: ${target}.y
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.sharpEasing}
                }
                PropertyAnimation {
                    target: ${target}
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.standardEasing}
                }
            }
        `, target)
    }

    // ==================== 缩放动画 ====================
    
    function createScaleIn(target, fromScale, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "scale"
                    from: ${fromScale || 0.8}
                    to: 1.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.sharpEasing}
                }
                PropertyAnimation {
                    target: ${target}
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.standardEasing}
                }
            }
        `, target)
    }

    function createScaleOut(target, toScale, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "scale"
                    from: 1.0
                    to: ${toScale || 0.8}
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.standardEasing}
                }
                PropertyAnimation {
                    target: ${target}
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.standardEasing}
                }
            }
        `, target)
    }

    // ==================== 弹跳动画 ====================
    
    function createBounceIn(target, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "scale"
                    from: 0.0
                    to: 1.1
                    duration: ${(duration || config.normalDuration) * 0.6}
                    easing.type: Easing.OutBack
                }
                PropertyAnimation {
                    target: ${target}
                    property: "scale"
                    from: 1.1
                    to: 1.0
                    duration: ${(duration || config.normalDuration) * 0.4}
                    easing.type: Easing.OutCubic
                }
            }
        `, target)
    }

    // ==================== 摇摆动画 ====================
    
    function createShake(target, intensity, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                loops: 3
                PropertyAnimation {
                    target: ${target}
                    property: "x"
                    from: ${target}.x
                    to: ${target}.x + ${intensity || 10}
                    duration: ${(duration || config.fastDuration) / 6}
                    easing.type: Easing.OutCubic
                }
                PropertyAnimation {
                    target: ${target}
                    property: "x"
                    from: ${target}.x + ${intensity || 10}
                    to: ${target}.x - ${intensity || 10}
                    duration: ${(duration || config.fastDuration) / 3}
                    easing.type: Easing.InOutCubic
                }
                PropertyAnimation {
                    target: ${target}
                    property: "x"
                    from: ${target}.x - ${intensity || 10}
                    to: ${target}.x
                    duration: ${(duration || config.fastDuration) / 6}
                    easing.type: Easing.OutCubic
                }
            }
        `, target)
    }

    // ==================== 脉冲动画 ====================
    
    function createPulse(target, minScale, maxScale, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                loops: Animation.Infinite
                PropertyAnimation {
                    target: ${target}
                    property: "scale"
                    from: ${minScale || 1.0}
                    to: ${maxScale || 1.05}
                    duration: ${(duration || config.slowerDuration) / 2}
                    easing.type: Easing.InOutSine
                }
                PropertyAnimation {
                    target: ${target}
                    property: "scale"
                    from: ${maxScale || 1.05}
                    to: ${minScale || 1.0}
                    duration: ${(duration || config.slowerDuration) / 2}
                    easing.type: Easing.InOutSine
                }
            }
        `, target)
    }

    // ==================== 旋转动画 ====================
    
    function createRotateIn(target, fromRotation, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "rotation"
                    from: ${fromRotation || -180}
                    to: 0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.sharpEasing}
                }
                PropertyAnimation {
                    target: ${target}
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.standardEasing}
                }
            }
        `, target)
    }

    function createSpin(target, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            PropertyAnimation {
                target: ${target}
                property: "rotation"
                from: 0
                to: 360
                duration: ${duration || config.slowerDuration}
                loops: Animation.Infinite
                easing.type: Easing.Linear
            }
        `, target)
    }

    // ==================== 组合动画 ====================
    
    function createFlipIn(target, axis, duration) {
        var property = axis === "x" ? "rotation" : "rotationY"
        return Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "${property}"
                    from: -90
                    to: 0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.sharpEasing}
                }
            }
        `, target)
    }

    function createZoomInRotate(target, duration) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            ParallelAnimation {
                PropertyAnimation {
                    target: ${target}
                    property: "scale"
                    from: 0.0
                    to: 1.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.sharpEasing}
                }
                PropertyAnimation {
                    target: ${target}
                    property: "rotation"
                    from: -180
                    to: 0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.sharpEasing}
                }
                PropertyAnimation {
                    target: ${target}
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: ${duration || config.normalDuration}
                    easing.type: ${config.standardEasing}
                }
            }
        `, target)
    }

    // ==================== 工具方法 ====================
    
    function stopAllAnimations(target) {
        // 停止目标对象的所有动画
        if (target && target.children) {
            for (var i = 0; i < target.children.length; i++) {
                var child = target.children[i]
                if (child.hasOwnProperty("stop")) {
                    child.stop()
                }
            }
        }
    }

    function createCustomAnimation(target, properties, duration, easing) {
        var animationCode = `
            import QtQuick 2.15
            ParallelAnimation {
        `
        
        for (var prop in properties) {
            animationCode += `
                PropertyAnimation {
                    target: ${target}
                    property: "${prop}"
                    to: ${properties[prop]}
                    duration: ${duration || config.normalDuration}
                    easing.type: ${easing || config.standardEasing}
                }
            `
        }
        
        animationCode += "}"
        
        return Qt.createQmlObject(animationCode, target)
    }
}
