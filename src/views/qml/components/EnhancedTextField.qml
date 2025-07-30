/*
 * 增强输入框组件
 * 基于设计系统的高级输入框，支持多种样式和动画效果
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

TextField {
    id: root

    // ==================== 自定义属性 ====================
    
    // 输入框变体
    enum TextFieldVariant {
        Filled,      // 填充样式
        Outlined,    // 轮廓样式
        Standard     // 标准样式
    }
    
    property int variant: EnhancedTextField.TextFieldVariant.Outlined
    property string labelText: ""
    property string helperText: ""
    property string errorText: ""
    property bool hasError: false
    property string leadingIcon: ""
    property string trailingIcon: ""
    property bool showClearButton: false
    property bool enableFloatingLabel: true
    property color accentColor: DesignSystem.colors.primary
    property real cornerRadius: DesignSystem.radius.sm
    
    // ==================== 基础样式 ====================
    
    implicitWidth: 200
    implicitHeight: DesignSystem.component.textField.height
    
    leftPadding: leadingIcon ? 48 : DesignSystem.spacing.md
    rightPadding: (trailingIcon || showClearButton) ? 48 : DesignSystem.spacing.md
    topPadding: (labelText && enableFloatingLabel) ? 24 : DesignSystem.spacing.sm
    bottomPadding: DesignSystem.spacing.sm
    
    font.family: DesignSystem.typography.fontFamily
    font.pixelSize: DesignSystem.typography.body.medium
    color: ThemeManager.colors.onSurface
    selectionColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.3)
    selectedTextColor: ThemeManager.colors.onSurface
    
    // ==================== 背景样式 ====================
    
    background: Rectangle {
        id: backgroundRect
        radius: root.cornerRadius
        
        // 根据变体设置背景色
        color: {
            switch (root.variant) {
                case EnhancedTextField.TextFieldVariant.Filled:
                    return ThemeManager.colors.surfaceVariant
                case EnhancedTextField.TextFieldVariant.Outlined:
                    return "transparent"
                case EnhancedTextField.TextFieldVariant.Standard:
                default:
                    return "transparent"
            }
        }
        
        // 边框
        border.width: {
            switch (root.variant) {
                case EnhancedTextField.TextFieldVariant.Outlined:
                    return root.activeFocus ? 2 : 1
                case EnhancedTextField.TextFieldVariant.Standard:
                    return 0
                case EnhancedTextField.TextFieldVariant.Filled:
                default:
                    return 0
            }
        }
        
        border.color: {
            if (root.hasError) {
                return DesignSystem.colors.error
            } else if (root.activeFocus) {
                return root.accentColor
            } else {
                return ThemeManager.colors.outline
            }
        }
        
        // 底部线条（标准样式）
        Rectangle {
            visible: root.variant === EnhancedTextField.TextFieldVariant.Standard
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.activeFocus ? 2 : 1
            color: {
                if (root.hasError) {
                    return DesignSystem.colors.error
                } else if (root.activeFocus) {
                    return root.accentColor
                } else {
                    return ThemeManager.colors.outline
                }
            }
            
            Behavior on height {
                PropertyAnimation {
                    duration: DesignSystem.animation.duration.fast
                    easing.type: DesignSystem.animation.easing.standard
                }
            }
            
            Behavior on color {
                ColorAnimation {
                    duration: DesignSystem.animation.duration.fast
                    easing.type: DesignSystem.animation.easing.standard
                }
            }
        }
        
        // 焦点动画
        Behavior on border.width {
            PropertyAnimation {
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.standard
            }
        }
        
        Behavior on border.color {
            ColorAnimation {
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.standard
            }
        }
    }

    // ==================== 浮动标签 ====================
    
    Label {
        id: floatingLabel
        visible: root.labelText
        text: root.labelText
        
        font.family: root.font.family
        font.pixelSize: isFloating ? DesignSystem.typography.label.medium : DesignSystem.typography.body.medium
        color: {
            if (root.hasError) {
                return DesignSystem.colors.error
            } else if (root.activeFocus) {
                return root.accentColor
            } else {
                return ThemeManager.colors.onSurfaceVariant
            }
        }
        
        property bool isFloating: root.activeFocus || root.text.length > 0 || !root.enableFloatingLabel
        
        x: root.leftPadding
        y: isFloating ? 8 : (root.height - height) / 2
        
        Behavior on y {
            PropertyAnimation {
                duration: DesignSystem.animation.duration.normal
                easing.type: DesignSystem.animation.easing.standard
            }
        }
        
        Behavior on font.pixelSize {
            PropertyAnimation {
                duration: DesignSystem.animation.duration.normal
                easing.type: DesignSystem.animation.easing.standard
            }
        }
        
        Behavior on color {
            ColorAnimation {
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.standard
            }
        }
    }

    // ==================== 图标 ====================
    
    // 前置图标
    Label {
        id: leadingIconLabel
        visible: root.leadingIcon
        text: root.leadingIcon
        font.pixelSize: DesignSystem.icons.size.medium
        color: root.activeFocus ? root.accentColor : ThemeManager.colors.onSurfaceVariant
        
        anchors.left: parent.left
        anchors.leftMargin: DesignSystem.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        
        Behavior on color {
            ColorAnimation {
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.standard
            }
        }
    }
    
    // 后置图标
    Label {
        id: trailingIconLabel
        visible: root.trailingIcon && !clearButton.visible
        text: root.trailingIcon
        font.pixelSize: DesignSystem.icons.size.medium
        color: ThemeManager.colors.onSurfaceVariant
        
        anchors.right: parent.right
        anchors.rightMargin: DesignSystem.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.trailingIconClicked()
        }
    }
    
    // 清除按钮
    Button {
        id: clearButton
        visible: root.showClearButton && root.text.length > 0
        text: "✕"
        
        anchors.right: parent.right
        anchors.rightMargin: DesignSystem.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        
        implicitWidth: 32
        implicitHeight: 32
        
        background: Rectangle {
            radius: 16
            color: parent.hovered ? ThemeManager.colors.hover : "transparent"
            
            Behavior on color {
                ColorAnimation {
                    duration: DesignSystem.animation.duration.fast
                }
            }
        }
        
        contentItem: Label {
            text: parent.text
            font.pixelSize: DesignSystem.typography.label.medium
            color: ThemeManager.colors.onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        
        onClicked: {
            root.clear()
            root.forceActiveFocus()
        }
    }

    // ==================== 辅助文本 ====================
    
    Label {
        id: helperLabel
        visible: (root.helperText || root.errorText) && text.length > 0
        text: root.hasError ? root.errorText : root.helperText
        
        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.leftMargin: root.leftPadding
        anchors.right: parent.right
        anchors.rightMargin: root.rightPadding
        
        font.family: root.font.family
        font.pixelSize: DesignSystem.typography.label.small
        color: root.hasError ? DesignSystem.colors.error : ThemeManager.colors.onSurfaceVariant
        wrapMode: Text.WordWrap
        
        Behavior on color {
            ColorAnimation {
                duration: DesignSystem.animation.duration.fast
                easing.type: DesignSystem.animation.easing.standard
            }
        }
    }

    // ==================== 信号 ====================
    
    signal trailingIconClicked()

    // ==================== 动画方法 ====================
    
    function playErrorAnimation() {
        errorAnimation.start()
    }
    
    function playSuccessAnimation() {
        successAnimation.start()
    }

    // ==================== 动画定义 ====================
    
    // 错误动画
    SequentialAnimation {
        id: errorAnimation
        
        // 摇摆效果
        SequentialAnimation {
            loops: 3
            PropertyAnimation {
                target: root
                property: "x"
                to: root.x + 3
                duration: 50
                easing.type: Easing.OutCubic
            }
            PropertyAnimation {
                target: root
                property: "x"
                to: root.x - 3
                duration: 100
                easing.type: Easing.InOutCubic
            }
            PropertyAnimation {
                target: root
                property: "x"
                to: root.x
                duration: 50
                easing.type: Easing.OutCubic
            }
        }
    }
    
    // 成功动画
    SequentialAnimation {
        id: successAnimation
        
        PropertyAnimation {
            target: backgroundRect.border
            property: "color"
            to: DesignSystem.colors.success
            duration: DesignSystem.animation.duration.normal
        }
        
        PauseAnimation {
            duration: 1000
        }
        
        PropertyAnimation {
            target: backgroundRect.border
            property: "color"
            to: root.accentColor
            duration: DesignSystem.animation.duration.normal
        }
    }

    // ==================== 键盘支持 ====================
    
    Keys.onEscapePressed: {
        root.focus = false
    }

    // ==================== 无障碍支持 ====================
    
    Accessible.role: Accessible.EditableText
    Accessible.name: root.labelText || root.placeholderText
    Accessible.description: root.helperText || root.errorText
}
