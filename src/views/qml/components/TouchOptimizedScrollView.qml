/*
 * 触摸优化滚动视图组件
 * 针对触摸设备优化的滚动体验
 */

import QtQuick 2.15
import QtQuick.Controls 2.15

ScrollView {
    id: root

    // ==================== 自定义属性 ====================
    
    property bool enableTouchOptimization: Qt.platform.os === "android" || Qt.platform.os === "ios"
    property bool enablePullToRefresh: false
    property bool enableInfiniteScroll: false
    property bool enableScrollIndicators: true
    property bool enableBounceEffect: true
    property bool enableMomentumScrolling: true
    
    // 滚动参数
    property real pullToRefreshThreshold: 80
    property real infiniteScrollThreshold: 100
    property int scrollAnimationDuration: 300
    property real momentumDecay: 0.95
    
    // 状态
    property bool isRefreshing: false
    property bool isLoadingMore: false
    property real pullDistance: 0
    
    // ==================== 信号 ====================
    
    signal pullToRefreshTriggered()
    signal infiniteScrollTriggered()
    signal scrollPositionChanged(real position)

    // ==================== 触摸优化配置 ====================
    
    Component.onCompleted: {
        if (enableTouchOptimization) {
            applyTouchOptimizations()
        }
    }
    
    function applyTouchOptimizations() {
        // 优化滚动参数
        if (contentItem) {
            contentItem.flickDeceleration = 1500
            contentItem.maximumFlickVelocity = 2500
            contentItem.flickableDirection = Flickable.VerticalFlick
            
            if (enableBounceEffect) {
                contentItem.boundsBehavior = Flickable.DragAndOvershootBounds
            } else {
                contentItem.boundsBehavior = Flickable.StopAtBounds
            }
        }
    }

    // ==================== 自定义滚动条 ====================
    
    ScrollBar.vertical: ScrollBar {
        id: verticalScrollBar
        visible: root.enableScrollIndicators && contentHeight > height
        width: 6
        policy: ScrollBar.AsNeeded
        
        background: Rectangle {
            color: "transparent"
        }
        
        contentItem: Rectangle {
            color: ThemeManager.colors.onSurfaceVariant
            opacity: verticalScrollBar.pressed ? 0.8 : 0.4
            radius: 3
            
            Behavior on opacity {
                PropertyAnimation {
                    duration: DesignSystem.animation.duration.fast
                }
            }
        }
        
        // 触摸设备上自动隐藏
        Timer {
            id: hideScrollBarTimer
            interval: 2000
            onTriggered: {
                if (root.enableTouchOptimization && !verticalScrollBar.pressed) {
                    verticalScrollBar.visible = false
                }
            }
        }
        
        onActiveChanged: {
            if (active) {
                visible = true
                hideScrollBarTimer.restart()
            }
        }
    }
    
    ScrollBar.horizontal: ScrollBar {
        id: horizontalScrollBar
        visible: root.enableScrollIndicators && contentWidth > width
        height: 6
        policy: ScrollBar.AsNeeded
        
        background: Rectangle {
            color: "transparent"
        }
        
        contentItem: Rectangle {
            color: ThemeManager.colors.onSurfaceVariant
            opacity: horizontalScrollBar.pressed ? 0.8 : 0.4
            radius: 3
            
            Behavior on opacity {
                PropertyAnimation {
                    duration: DesignSystem.animation.duration.fast
                }
            }
        }
    }

    // ==================== 下拉刷新 ====================
    
    Rectangle {
        id: pullToRefreshIndicator
        visible: root.enablePullToRefresh
        anchors.horizontalCenter: parent.horizontalCenter
        y: -height + Math.max(0, root.pullDistance)
        width: 60
        height: 60
        radius: 30
        color: ThemeManager.colors.surface
        border.width: 2
        border.color: DesignSystem.colors.primary
        
        opacity: root.pullDistance > 0 ? Math.min(1.0, root.pullDistance / root.pullToRefreshThreshold) : 0
        
        BusyIndicator {
            anchors.centerIn: parent
            running: root.isRefreshing
            visible: root.isRefreshing
            implicitWidth: 30
            implicitHeight: 30
        }
        
        Label {
            anchors.centerIn: parent
            visible: !root.isRefreshing
            text: root.pullDistance > root.pullToRefreshThreshold ? "释放刷新" : "下拉刷新"
            font.pixelSize: DesignSystem.typography.label.small
            color: DesignSystem.colors.primary
        }
        
        // 旋转动画
        rotation: root.isRefreshing ? 0 : (root.pullDistance / root.pullToRefreshThreshold) * 180
        
        Behavior on rotation {
            PropertyAnimation {
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.standard
            }
        }
    }

    // ==================== 无限滚动 ====================
    
    Rectangle {
        id: infiniteScrollIndicator
        visible: root.enableInfiniteScroll && root.isLoadingMore
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        width: 200
        height: 40
        radius: 20
        color: ThemeManager.colors.surface
        border.width: 1
        border.color: ThemeManager.colors.outline
        
        RowLayout {
            anchors.centerIn: parent
            spacing: DesignSystem.spacing.sm
            
            BusyIndicator {
                implicitWidth: 20
                implicitHeight: 20
                running: root.isLoadingMore
            }
            
            Label {
                text: "正在加载更多..."
                font.pixelSize: DesignSystem.typography.body.small
                color: ThemeManager.colors.onSurface
            }
        }
    }

    // ==================== 触摸手势处理 ====================
    
    MouseArea {
        id: touchHandler
        anchors.fill: parent
        enabled: root.enableTouchOptimization
        propagateComposedEvents: true
        
        property real startY: 0
        property real lastY: 0
        property bool isDragging: false
        
        onPressed: function(mouse) {
            startY = mouse.y
            lastY = mouse.y
            isDragging = true
            mouse.accepted = false
        }
        
        onPositionChanged: function(mouse) {
            if (!isDragging) {
                mouse.accepted = false
                return
            }
            
            var deltaY = mouse.y - lastY
            lastY = mouse.y
            
            // 处理下拉刷新
            if (root.enablePullToRefresh && contentItem.contentY <= 0 && deltaY > 0) {
                root.pullDistance = Math.max(0, mouse.y - startY)
                mouse.accepted = true
                return
            }
            
            // 处理无限滚动
            if (root.enableInfiniteScroll && !root.isLoadingMore) {
                var scrollPosition = contentItem.contentY + contentItem.height
                var totalHeight = contentItem.contentHeight
                
                if (scrollPosition >= totalHeight - root.infiniteScrollThreshold) {
                    root.isLoadingMore = true
                    root.infiniteScrollTriggered()
                }
            }
            
            mouse.accepted = false
        }
        
        onReleased: function(mouse) {
            if (root.enablePullToRefresh && root.pullDistance > root.pullToRefreshThreshold && !root.isRefreshing) {
                root.isRefreshing = true
                root.pullToRefreshTriggered()
            }
            
            // 重置下拉距离
            pullDistanceAnimation.start()
            
            isDragging = false
            mouse.accepted = false
        }
    }

    // ==================== 动画 ====================
    
    PropertyAnimation {
        id: pullDistanceAnimation
        target: root
        property: "pullDistance"
        to: 0
        duration: DesignSystem.animation.duration.normal
        easing.type: DesignSystem.animation.easing.standard
    }
    
    // 滚动到顶部动画
    function scrollToTop(animated) {
        if (animated === undefined) animated = true
        
        if (animated) {
            scrollToTopAnimation.start()
        } else {
            contentItem.contentY = 0
        }
    }
    
    PropertyAnimation {
        id: scrollToTopAnimation
        target: contentItem
        property: "contentY"
        to: 0
        duration: root.scrollAnimationDuration
        easing.type: DesignSystem.animation.easing.standard
    }
    
    // 滚动到底部动画
    function scrollToBottom(animated) {
        if (animated === undefined) animated = true
        
        var targetY = Math.max(0, contentItem.contentHeight - contentItem.height)
        
        if (animated) {
            scrollToBottomAnimation.to = targetY
            scrollToBottomAnimation.start()
        } else {
            contentItem.contentY = targetY
        }
    }
    
    PropertyAnimation {
        id: scrollToBottomAnimation
        target: contentItem
        property: "contentY"
        duration: root.scrollAnimationDuration
        easing.type: DesignSystem.animation.easing.standard
    }

    // ==================== 公共方法 ====================
    
    function finishRefresh() {
        root.isRefreshing = false
        root.pullDistance = 0
    }
    
    function finishLoadingMore() {
        root.isLoadingMore = false
    }
    
    function scrollToItem(item, animated) {
        if (!item || !contentItem) return
        
        var itemY = item.mapToItem(contentItem, 0, 0).y
        var targetY = Math.max(0, Math.min(itemY, contentItem.contentHeight - contentItem.height))
        
        if (animated === undefined) animated = true
        
        if (animated) {
            scrollToItemAnimation.to = targetY
            scrollToItemAnimation.start()
        } else {
            contentItem.contentY = targetY
        }
    }
    
    PropertyAnimation {
        id: scrollToItemAnimation
        target: contentItem
        property: "contentY"
        duration: root.scrollAnimationDuration
        easing.type: DesignSystem.animation.easing.standard
    }
    
    function getScrollPosition() {
        if (!contentItem) return 0
        return contentItem.contentY / Math.max(1, contentItem.contentHeight - contentItem.height)
    }
    
    function setScrollPosition(position, animated) {
        if (!contentItem) return
        
        var targetY = position * Math.max(0, contentItem.contentHeight - contentItem.height)
        
        if (animated === undefined) animated = true
        
        if (animated) {
            setScrollPositionAnimation.to = targetY
            setScrollPositionAnimation.start()
        } else {
            contentItem.contentY = targetY
        }
    }
    
    PropertyAnimation {
        id: setScrollPositionAnimation
        target: contentItem
        property: "contentY"
        duration: root.scrollAnimationDuration
        easing.type: DesignSystem.animation.easing.standard
    }

    // ==================== 监听器 ====================
    
    Connections {
        target: contentItem
        
        function onContentYChanged() {
            root.scrollPositionChanged(root.getScrollPosition())
        }
    }
}
