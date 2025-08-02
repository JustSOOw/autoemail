/*
 * 动画列表视图组件
 * 支持进入/退出动画、重排序动画、加载动画等高级效果
 */

import QtQuick 2.15
import QtQuick.Controls 2.15

ListView {
    id: root

    // ==================== 自定义属性 ====================
    
    property bool enableItemAnimations: true
    property bool enableAddAnimation: true
    property bool enableRemoveAnimation: true
    property bool enableMoveAnimation: true
    property bool enableLoadingAnimation: true
    property int animationDuration: DesignSystem.animation.duration.normal
    property int staggerDelay: 50
    property string animationType: "slideIn" // slideIn, fadeIn, scaleIn, flipIn
    
    // ==================== 信号 ====================
    
    signal itemAnimationCompleted(int index)
    signal allAnimationsCompleted()

    // ==================== 基础设置 ====================
    
    clip: true
    
    // 自定义滚动条
    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        width: 8
        policy: ScrollBar.AsNeeded
        
        background: Rectangle {
            color: ThemeManager.colors.outline
            opacity: 0.3
            radius: 4
        }
        
        contentItem: Rectangle {
            color: DesignSystem.colors.primary
            radius: 4
            opacity: scrollBar.pressed ? 0.8 : 0.6
            
            Behavior on opacity {
                PropertyAnimation {
                    duration: DesignSystem.animation.duration.fast
                }
            }
        }
    }

    // ==================== 列表动画 ====================
    
    // 添加动画
    add: Transition {
        enabled: root.enableAddAnimation
        
        SequentialAnimation {
            PauseAnimation {
                duration: root.staggerDelay * (ViewTransition.index % 10)
            }
            
            ParallelAnimation {
                PropertyAnimation {
                    property: getAnimationProperty()
                    from: getAnimationFromValue()
                    to: getAnimationToValue()
                    duration: root.animationDuration
                    easing.type: DesignSystem.animation.easing.sharp
                }
                
                PropertyAnimation {
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: root.animationDuration
                    easing.type: DesignSystem.animation.easing.standard
                }
            }
            
            ScriptAction {
                script: root.itemAnimationCompleted(ViewTransition.index)
            }
        }
    }
    
    // 移除动画
    remove: Transition {
        enabled: root.enableRemoveAnimation
        
        ParallelAnimation {
            PropertyAnimation {
                property: "opacity"
                to: 0.0
                duration: root.animationDuration
                easing.type: DesignSystem.animation.easing.standard
            }
            
            PropertyAnimation {
                property: "scale"
                to: 0.8
                duration: root.animationDuration
                easing.type: DesignSystem.animation.easing.standard
            }
            
            PropertyAnimation {
                property: "x"
                to: -50
                duration: root.animationDuration
                easing.type: DesignSystem.animation.easing.sharp
            }
        }
    }
    
    // 移动动画
    move: Transition {
        enabled: root.enableMoveAnimation
        
        PropertyAnimation {
            properties: "x,y"
            duration: root.animationDuration
            easing.type: DesignSystem.animation.easing.standard
        }
    }
    
    // 位移动画
    displaced: Transition {
        enabled: root.enableMoveAnimation
        
        PropertyAnimation {
            properties: "x,y"
            duration: root.animationDuration
            easing.type: DesignSystem.animation.easing.standard
        }
    }

    // ==================== 加载动画 ====================
    
    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        color: ThemeManager.colors.surface
        visible: root.count === 0 && root.enableLoadingAnimation
        z: 100
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: DesignSystem.spacing.lg
            
            // 加载动画
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 60
                height: 60
                radius: 30
                color: "transparent"
                border.width: 4
                border.color: DesignSystem.colors.primary
                
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: DesignSystem.colors.primary
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 4
                    
                    RotationAnimation {
                        target: parent.parent
                        running: loadingOverlay.visible
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }
            }
            
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "正在加载..."
                font.pixelSize: DesignSystem.typography.body.medium
                color: ThemeManager.colors.onSurfaceVariant
            }
        }
        
        // 骨架屏效果
        Column {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacing.md
            spacing: DesignSystem.spacing.sm
            visible: false // 可以通过属性控制显示
            
            Repeater {
                model: 5
                
                Rectangle {
                    width: parent.width
                    height: 60
                    radius: DesignSystem.radius.md
                    color: ThemeManager.colors.surfaceVariant
                    
                    // 闪烁动画
                    SequentialAnimation {
                        running: true
                        loops: Animation.Infinite
                        
                        PropertyAnimation {
                            target: parent
                            property: "opacity"
                            to: 0.5
                            duration: 800
                            easing.type: Easing.InOutSine
                        }
                        
                        PropertyAnimation {
                            target: parent
                            property: "opacity"
                            to: 1.0
                            duration: 800
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }
    }

    // ==================== 空状态动画 ====================
    
    Item {
        id: emptyState
        anchors.centerIn: parent
        width: 200
        height: 150
        visible: root.count === 0 && !loadingOverlay.visible
        
        ColumnLayout {
            anchors.fill: parent
            spacing: DesignSystem.spacing.md
            
            // 空状态图标
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "📭"
                font.pixelSize: 48
                
                // 浮动动画
                SequentialAnimation {
                    running: emptyState.visible
                    loops: Animation.Infinite
                    
                    PropertyAnimation {
                        target: parent
                        property: "anchors.verticalCenterOffset"
                        to: -5
                        duration: 2000
                        easing.type: Easing.InOutSine
                    }
                    
                    PropertyAnimation {
                        target: parent
                        property: "anchors.verticalCenterOffset"
                        to: 5
                        duration: 2000
                        easing.type: Easing.InOutSine
                    }
                }
            }
            
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "暂无数据"
                font.pixelSize: DesignSystem.typography.body.large
                font.weight: DesignSystem.typography.weight.medium
                color: ThemeManager.colors.onSurfaceVariant
            }
            
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "添加一些内容开始使用吧"
                font.pixelSize: DesignSystem.typography.body.small
                color: ThemeManager.colors.onSurfaceVariant
                opacity: 0.7
            }
        }
        
        // 进入动画
        PropertyAnimation {
            id: emptyStateAnimation
            target: emptyState
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: DesignSystem.animation.duration.slow
            easing.type: DesignSystem.animation.easing.standard
            running: emptyState.visible
        }
    }

    // ==================== 方法 ====================
    
    function getAnimationProperty() {
        switch (root.animationType) {
            case "slideIn": return "x"
            case "fadeIn": return "opacity"
            case "scaleIn": return "scale"
            case "flipIn": return "rotationY"
            default: return "x"
        }
    }
    
    function getAnimationFromValue() {
        switch (root.animationType) {
            case "slideIn": return -100
            case "fadeIn": return 0.0
            case "scaleIn": return 0.0
            case "flipIn": return -90
            default: return -100
        }
    }
    
    function getAnimationToValue() {
        switch (root.animationType) {
            case "slideIn": return 0
            case "fadeIn": return 1.0
            case "scaleIn": return 1.0
            case "flipIn": return 0
            default: return 0
        }
    }
    
    function playItemAnimation(index) {
        // 播放指定项目的动画
        var item = itemAtIndex(index)
        if (item) {
            var animation = Qt.createQmlObject(`
                import QtQuick 2.15
                SequentialAnimation {
                    PropertyAnimation {
                        target: item
                        property: "scale"
                        to: 1.1
                        duration: ${DesignSystem.animation.duration.fast}
                        easing.type: ${DesignSystem.animation.easing.sharp}
                    }
                    PropertyAnimation {
                        target: item
                        property: "scale"
                        to: 1.0
                        duration: ${DesignSystem.animation.duration.fast}
                        easing.type: ${DesignSystem.animation.easing.sharp}
                    }
                }
            `, item)
            animation.start()
        }
    }
    
    function animateToIndex(index) {
        // 动画滚动到指定索引
        var targetY = index * (itemHeight + spacing)
        
        PropertyAnimation {
            target: root
            property: "contentY"
            to: Math.min(targetY, root.contentHeight - root.height)
            duration: root.animationDuration
            easing.type: DesignSystem.animation.easing.standard
        }.start()
    }
    
    function refreshWithAnimation() {
        // 刷新时的动画效果
        var refreshAnimation = Qt.createQmlObject(`
            import QtQuick 2.15
            SequentialAnimation {
                PropertyAnimation {
                    target: root
                    property: "opacity"
                    to: 0.5
                    duration: ${DesignSystem.animation.duration.fast}
                }
                ScriptAction {
                    script: {
                        // 这里可以触发数据刷新
                        console.log("刷新数据")
                    }
                }
                PropertyAnimation {
                    target: root
                    property: "opacity"
                    to: 1.0
                    duration: ${DesignSystem.animation.duration.fast}
                }
            }
        `, root)
        refreshAnimation.start()
    }

    // ==================== 监听器 ====================
    
    onCountChanged: {
        if (count > 0) {
            // 检查是否所有动画都完成了
            Qt.callLater(function() {
                root.allAnimationsCompleted()
            })
        }
    }
    
    // 监听模型变化
    Connections {
        target: root.model
        
        function onModelReset() {
            // 模型重置时的动画
            refreshWithAnimation()
        }
    }
}
