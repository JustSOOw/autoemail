/*
 * 可拖拽标签项组件
 * 支持拖拽排序、快速编辑、悬停效果等高级交互
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: root

    // ==================== 自定义属性 ====================
    
    property var tagData: ({})
    property ListView listView: null
    property bool isDragging: false
    property bool isHovered: false
    property bool enableQuickEdit: true
    property bool enableDragReorder: true
    property int originalIndex: -1
    
    // ==================== 信号 ====================
    
    signal editRequested(var tagData)
    signal deleteRequested(int tagId, string tagName)
    signal quickEditRequested(var tagData)
    signal dragStarted(int fromIndex)
    signal dragEnded(int fromIndex, int toIndex)

    // ==================== 基础样式 ====================
    
    color: {
        if (isDragging) {
            return Qt.rgba(ThemeManager.colors.selected.r, 
                          ThemeManager.colors.selected.g, 
                          ThemeManager.colors.selected.b, 0.9)
        } else if (isHovered) {
            return ThemeManager.colors.hover
        } else {
            return ThemeManager.colors.surface
        }
    }
    
    radius: DesignSystem.radius.md
    border.width: isDragging ? 2 : 1
    border.color: isDragging ? DesignSystem.colors.primary : ThemeManager.colors.outline
    
    // 拖拽时的阴影效果
    layer.enabled: isDragging
    layer.effect: DropShadow {
        horizontalOffset: DesignSystem.elevation.level3.offsetX
        verticalOffset: DesignSystem.elevation.level3.offsetY
        radius: DesignSystem.elevation.level3.blur
        color: DesignSystem.elevation.level3.color
        spread: DesignSystem.elevation.level3.spread
    }

    // ==================== 内容布局 ====================
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.md
        spacing: DesignSystem.spacing.md

        // 拖拽手柄
        Rectangle {
            id: dragHandle
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            color: "transparent"
            visible: root.enableDragReorder
            
            Column {
                anchors.centerIn: parent
                spacing: 2
                
                Repeater {
                    model: 3
                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: ThemeManager.colors.onSurfaceVariant
                        opacity: dragHandleArea.containsMouse ? 1.0 : 0.6
                    }
                }
            }
            
            MouseArea {
                id: dragHandleArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeAllCursor
                
                onPressed: {
                    if (root.enableDragReorder) {
                        startDrag()
                    }
                }
            }
        }

        // 标签图标和颜色
        Rectangle {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            color: root.tagData.color || DesignSystem.colors.primary
            radius: 24

            Label {
                anchors.centerIn: parent
                text: root.tagData.icon || "🏷️"
                font.pixelSize: DesignSystem.icons.size.large
            }
            
            // 颜色选择器（快速编辑）
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (root.enableQuickEdit) {
                        colorPickerPopup.open()
                    }
                }
            }
        }

        // 标签信息
        ColumnLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacing.xs

            // 标签名称（可快速编辑）
            TextField {
                id: nameField
                Layout.fillWidth: true
                text: root.tagData.name || ""
                font.pixelSize: DesignSystem.typography.body.medium
                font.weight: DesignSystem.typography.weight.semiBold
                color: ThemeManager.colors.onSurface
                readOnly: !editMode
                
                property bool editMode: false
                
                background: Rectangle {
                    color: nameField.editMode ? ThemeManager.colors.surfaceVariant : "transparent"
                    radius: DesignSystem.radius.sm
                    border.width: nameField.editMode ? 1 : 0
                    border.color: DesignSystem.colors.primary
                }
                
                onEditingFinished: {
                    if (editMode) {
                        saveNameEdit()
                    }
                }
                
                Keys.onEscapePressed: {
                    cancelNameEdit()
                }
                
                Keys.onReturnPressed: {
                    saveNameEdit()
                }
                
                MouseArea {
                    anchors.fill: parent
                    enabled: !nameField.editMode
                    onDoubleClicked: {
                        if (root.enableQuickEdit) {
                            startNameEdit()
                        }
                    }
                }
            }

            // 标签描述和统计信息
            RowLayout {
                Layout.fillWidth: true
                spacing: DesignSystem.spacing.md

                Label {
                    Layout.fillWidth: true
                    text: root.tagData.description || "无描述"
                    font.pixelSize: DesignSystem.typography.body.small
                    color: ThemeManager.colors.onSurfaceVariant
                    elide: Text.ElideRight
                }

                Label {
                    text: "使用: " + (root.tagData.usage_count || 0)
                    font.pixelSize: DesignSystem.typography.label.small
                    color: ThemeManager.colors.onSurfaceVariant
                }

                Label {
                    text: "创建: " + (root.tagData.created_at ? 
                          new Date(root.tagData.created_at).toLocaleDateString() : "")
                    font.pixelSize: DesignSystem.typography.label.small
                    color: ThemeManager.colors.onSurfaceVariant
                }
            }
        }

        // 使用统计图表
        Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 40
            color: "transparent"
            
            // 简单的使用趋势图
            Canvas {
                id: usageChart
                anchors.fill: parent
                
                property var usageData: root.tagData.usage_trend || [1, 3, 2, 5, 4, 6, 8]
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    
                    if (usageData.length < 2) return
                    
                    ctx.strokeStyle = root.tagData.color || DesignSystem.colors.primary
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    
                    var maxValue = Math.max(...usageData)
                    var stepX = width / (usageData.length - 1)
                    
                    ctx.beginPath()
                    for (var i = 0; i < usageData.length; i++) {
                        var x = i * stepX
                        var y = height - (usageData[i] / maxValue) * height
                        
                        if (i === 0) {
                            ctx.moveTo(x, y)
                        } else {
                            ctx.lineTo(x, y)
                        }
                    }
                    ctx.stroke()
                }
                
                Component.onCompleted: requestPaint()
            }
        }

        // 操作按钮
        RowLayout {
            spacing: DesignSystem.spacing.xs

            EnhancedButton {
                variant: EnhancedButton.ButtonVariant.Text
                iconText: "✏️"
                implicitWidth: 32
                implicitHeight: 32
                ToolTip.text: "编辑标签"
                onClicked: root.editRequested(root.tagData)
            }

            EnhancedButton {
                variant: EnhancedButton.ButtonVariant.Text
                iconText: "⚡"
                implicitWidth: 32
                implicitHeight: 32
                ToolTip.text: "快速编辑"
                onClicked: root.quickEditRequested(root.tagData)
            }

            EnhancedButton {
                variant: EnhancedButton.ButtonVariant.Text
                iconText: "🗑️"
                customColor: DesignSystem.colors.error
                implicitWidth: 32
                implicitHeight: 32
                ToolTip.text: "删除标签"
                enabled: (root.tagData.usage_count || 0) === 0
                onClicked: root.deleteRequested(root.tagData.id, root.tagData.name)
            }
        }
    }

    // ==================== 交互区域 ====================
    
    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onEntered: {
            root.isHovered = true
            hoverAnimation.start()
        }
        
        onExited: {
            root.isHovered = false
            hoverExitAnimation.start()
        }
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
            }
        }
        
        onDoubleClicked: {
            if (root.enableQuickEdit) {
                root.quickEditRequested(root.tagData)
            }
        }
    }

    // ==================== 拖拽功能 ====================
    
    Drag.active: dragHandleArea.drag.active
    Drag.source: root
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2
    
    states: [
        State {
            when: root.isDragging
            PropertyChanges {
                target: root
                z: 999
                scale: 1.05
                rotation: 2
            }
        }
    ]
    
    transitions: [
        Transition {
            PropertyAnimation {
                properties: "scale,rotation"
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.standard
            }
        }
    ]

    // ==================== 动画定义 ====================
    
    PropertyAnimation {
        id: hoverAnimation
        target: root
        property: "scale"
        to: 1.02
        duration: DesignSystem.animation.duration.fast
        easing.type: DesignSystem.animation.easing.standard
    }
    
    PropertyAnimation {
        id: hoverExitAnimation
        target: root
        property: "scale"
        to: 1.0
        duration: DesignSystem.animation.duration.fast
        easing.type: DesignSystem.animation.easing.standard
    }

    // ==================== 弹出菜单 ====================
    
    Menu {
        id: contextMenu
        
        MenuItem {
            text: "编辑"
            icon.source: "✏️"
            onTriggered: root.editRequested(root.tagData)
        }
        
        MenuItem {
            text: "快速编辑"
            icon.source: "⚡"
            onTriggered: root.quickEditRequested(root.tagData)
        }
        
        MenuSeparator {}
        
        MenuItem {
            text: "删除"
            icon.source: "🗑️"
            enabled: (root.tagData.usage_count || 0) === 0
            onTriggered: root.deleteRequested(root.tagData.id, root.tagData.name)
        }
    }

    // 颜色选择器弹出框
    Popup {
        id: colorPickerPopup
        width: 200
        height: 120
        
        GridLayout {
            anchors.fill: parent
            columns: 6
            
            property var colors: [
                "#2196F3", "#4CAF50", "#F44336", "#FF9800", 
                "#9C27B0", "#00BCD4", "#795548", "#607D8B"
            ]
            
            Repeater {
                model: parent.colors
                
                Rectangle {
                    width: 24
                    height: 24
                    color: modelData
                    radius: 12
                    border.width: 2
                    border.color: "transparent"
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.tagData.color = modelData
                            usageChart.requestPaint()
                            colorPickerPopup.close()
                        }
                    }
                }
            }
        }
    }

    // ==================== 方法 ====================
    
    function startDrag() {
        root.originalIndex = root.listView.model.indexOf(root.tagData)
        root.isDragging = true
        root.dragStarted(root.originalIndex)
    }
    
    function endDrag(newIndex) {
        root.isDragging = false
        if (newIndex !== root.originalIndex) {
            root.dragEnded(root.originalIndex, newIndex)
        }
    }
    
    function startNameEdit() {
        nameField.editMode = true
        nameField.forceActiveFocus()
        nameField.selectAll()
    }
    
    function saveNameEdit() {
        nameField.editMode = false
        root.tagData.name = nameField.text
        // 这里应该调用保存API
    }
    
    function cancelNameEdit() {
        nameField.editMode = false
        nameField.text = root.tagData.name || ""
    }
}
