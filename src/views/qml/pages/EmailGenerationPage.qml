/*
 * 邮箱申请页面 - 重新设计版本
 * 左侧：操作日志和状态信息
 * 右侧：邮箱生成功能区域（横向布局）
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import "../components"

Rectangle {
    id: root
    color: "#f5f5f5"

    // 对外暴露的属性
    property bool isConfigured: false
    property string currentDomain: "未配置"
    property var statistics: ({})
    property var availableTags: []
    property bool isCompactMode: width < 1200  // 调整紧凑模式阈值
    
    // 标签管理相关属性
    property var allTagsList: []  // 所有标签列表
    property var selectedTagsList: []  // 已选择的标签列表
    property var filteredTagsList: []  // 过滤后的标签列表

    // 对外暴露的信号
    signal statusChanged(string message)
    signal logMessage(string message)
    signal requestTagRefresh()
    signal createNewTag(string tagName)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 左侧：操作日志和状态区域
        Rectangle {
            Layout.minimumWidth: 300
            Layout.preferredWidth: 350
            Layout.maximumWidth: 400
            Layout.fillHeight: true
            color: "white"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1

            // 添加阴影效果
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                color: "#10000000"
                radius: parent.radius + 3
                z: -1
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // 标题和状态指示器
                Row {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: root.isConfigured ? "#4CAF50" : "#F44336"
                        anchors.verticalCenter: parent.verticalCenter

                        // 呼吸灯效果
                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1500 }
                            NumberAnimation { to: 1.0; duration: 1500 }
                        }
                    }

                    Label {
                        text: "📝 操作日志"
                        font.bold: true
                        font.pixelSize: 18
                        color: "#333"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // 域名和统计信息卡片
                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    color: "#f8f9fa"
                    radius: 8
                    border.color: "#e9ecef"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // 域名信息
                        Row {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "🌐"
                                font.pixelSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Label {
                                    text: root.currentDomain
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: root.isConfigured ? "#4CAF50" : "#F44336"
                                }

                                Label {
                                    text: root.isConfigured ? "已配置" : "未配置"
                                    font.pixelSize: 11
                                    color: "#666"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#e0e0e0"
                        }

                        // 统计信息
                        Flow {
                            Layout.fillWidth: true
                            spacing: 16

                            Column {
                                spacing: 2
                                Label {
                                    text: (root.statistics.total_emails || 0).toString()
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: "#2196F3"
                                }
                                Label {
                                    text: "总邮箱"
                                    font.pixelSize: 10
                                    color: "#666"
                                }
                            }

                            Column {
                                spacing: 2
                                Label {
                                    text: (root.statistics.today_created || 0).toString()
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: "#FF9800"
                                }
                                Label {
                                    text: "今日创建"
                                    font.pixelSize: 10
                                    color: "#666"
                                }
                            }

                            Column {
                                spacing: 2
                                Label {
                                    text: (root.statistics.success_rate || 100) + "%"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: "#4CAF50"
                                }
                                Label {
                                    text: "成功率"
                                    font.pixelSize: 10
                                    color: "#666"
                                }
                            }
                        }
                    }
                }

                // 最新生成的邮箱
                Rectangle {
                    id: latestEmailCard
                    Layout.fillWidth: true
                    height: 70
                    color: "#e3f2fd"
                    radius: 8
                    border.color: "#2196F3"
                    border.width: 1
                    visible: latestEmailLabel.text !== ""

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: "#2196F3"

                            Text {
                                anchors.centerIn: parent
                                text: "✉️"
                                font.pixelSize: 18
                                color: "white"
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: "最新生成的邮箱"
                                font.pixelSize: 11
                                color: "#1976D2"
                                font.weight: Font.Medium
                            }

                            Label {
                                id: latestEmailLabel
                                text: ""
                                font.pixelSize: 12
                                color: "#1565C0"
                                font.weight: Font.Bold
                                elide: Text.ElideMiddle
                                width: parent.width

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        console.log("复制邮箱地址:", latestEmailLabel.text)
                                        root.logMessage("📋 邮箱地址已复制到剪贴板")
                                    }
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }

                        Button {
                            text: "📋"
                            width: 32
                            height: 32
                            background: Rectangle {
                                color: parent.hovered ? "#1976D2" : "#2196F3"
                                radius: 16
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                console.log("复制邮箱:", latestEmailLabel.text)
                                root.logMessage("📋 邮箱地址已复制")
                            }
                        }
                    }
                }

                // 日志区域
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 8  // 恢复原来的间距
                    clip: true

                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    TextArea {
                        id: logArea
                        readOnly: true
                        wrapMode: TextArea.Wrap
                        font.family: "Consolas, Monaco, monospace"
                        font.pixelSize: 11
                        color: "#333"
                        selectByMouse: true
                        text: "[" + new Date().toLocaleTimeString() + "] 邮箱生成页面已加载\n[" + new Date().toLocaleTimeString() + "] 等待用户操作..."

                        // 添加内边距，防止文本超出背景
                        leftPadding: 12
                        rightPadding: 12
                        topPadding: 10
                        bottomPadding: 10

                        background: Rectangle {
                            color: "#fafafa"
                            radius: 6
                            border.color: "#e0e0e0"
                            border.width: 1
                        }

                        function addLog(message) {
                            var timestamp = new Date().toLocaleTimeString()
                            text += "\n[" + timestamp + "] " + message
                            cursorPosition = length
                        }
                    }
                }
            }
        }

        // 右侧：邮箱生成功能区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1

            // 添加阴影效果
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                color: "#10000000"
                radius: parent.radius + 3
                z: -1
            }

            ScrollView {
                anchors.fill: parent
                anchors.margins: 20  // 减少边距增加内容宽度
                clip: true

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                contentWidth: availableWidth  // 确保内容宽度不超过可用宽度

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 24

                    // 页面标题
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Rectangle {
                            width: 48
                            height: 48
                            radius: 24
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#42A5F5" }
                                GradientStop { position: 1.0; color: "#1976D2" }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "🎯"
                                font.pixelSize: 24
                                color: "white"
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: "邮箱生成器"
                                font.bold: true
                                font.pixelSize: 24
                                color: "#333"
                            }

                            Label {
                                text: "配置生成参数，快速创建邮箱地址"
                                font.pixelSize: 14
                                color: "#666"
                            }
                        }

                        // 紧凑模式下的状态信息
                        Rectangle {
                            Layout.preferredWidth: 200
                            height: 48
                            color: "#f8f9fa"
                            radius: 8
                            border.color: "#e9ecef"
                            visible: root.isCompactMode

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: root.isConfigured ? "#4CAF50" : "#F44336"
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: root.currentDomain
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: root.isConfigured ? "#4CAF50" : "#F44336"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Label {
                                        text: "总数: " + (root.statistics.total_emails || 0) + " | 今日: " + (root.statistics.today_created || 0)
                                        font.pixelSize: 10
                                        color: "#666"
                                    }
                                }
                            }
                        }
                    }

                    // 主要配置区域 - 横向布局
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        // 左列：生成模式和前缀设置
                        ColumnLayout {
                            Layout.preferredWidth: parent.width * 0.45  // 增加左列宽度
                            Layout.alignment: Qt.AlignTop
                            spacing: 16

                            // 生成模式选择
                            GroupBox {
                                Layout.fillWidth: true
                                title: "生成模式"
                                font.pixelSize: 14
                                font.weight: Font.Medium

                                background: Rectangle {
                                    color: "#fafafa"
                                    radius: 8
                                    border.color: "#e0e0e0"
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    ButtonGroup {
                                        id: prefixTypeGroup
                                    }

                                    RadioButton {
                                        id: randomNameRadio
                                        text: "随机名字"
                                        checked: true
                                        ButtonGroup.group: prefixTypeGroup
                                        font.pixelSize: 13

                                        indicator: Rectangle {
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            x: randomNameRadio.leftPadding
                                            y: parent.height / 2 - height / 2
                                            radius: 9
                                            border.color: randomNameRadio.checked ? "#2196F3" : "#ccc"
                                            border.width: 2

                                            Rectangle {
                                                width: 8
                                                height: 8
                                                x: 5
                                                y: 5
                                                radius: 4
                                                color: "#2196F3"
                                                visible: randomNameRadio.checked
                                            }
                                        }
                                    }

                                    Label {
                                        text: "例：john.smith@domain.com"
                                        font.pixelSize: 11
                                        color: "#999"
                                        leftPadding: 30
                                    }

                                    RadioButton {
                                        id: randomStringRadio
                                        text: "随机字符串"
                                        ButtonGroup.group: prefixTypeGroup
                                        font.pixelSize: 13

                                        indicator: Rectangle {
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            x: randomStringRadio.leftPadding
                                            y: parent.height / 2 - height / 2
                                            radius: 9
                                            border.color: randomStringRadio.checked ? "#2196F3" : "#ccc"
                                            border.width: 2

                                            Rectangle {
                                                width: 8
                                                height: 8
                                                x: 5
                                                y: 5
                                                radius: 4
                                                color: "#2196F3"
                                                visible: randomStringRadio.checked
                                            }
                                        }
                                    }

                                    Label {
                                        text: "例：ak7m2x9p@domain.com"
                                        font.pixelSize: 11
                                        color: "#999"
                                        leftPadding: 30
                                    }

                                    RadioButton {
                                        id: customPrefixRadio
                                        text: "自定义前缀"
                                        ButtonGroup.group: prefixTypeGroup
                                        font.pixelSize: 13

                                        indicator: Rectangle {
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            x: customPrefixRadio.leftPadding
                                            y: parent.height / 2 - height / 2
                                            radius: 9
                                            border.color: customPrefixRadio.checked ? "#2196F3" : "#ccc"
                                            border.width: 2

                                            Rectangle {
                                                width: 8
                                                height: 8
                                                x: 5
                                                y: 5
                                                radius: 4
                                                color: "#2196F3"
                                                visible: customPrefixRadio.checked
                                            }
                                        }
                                    }

                                    // 自定义前缀输入 - 浮动标签效果
                                    Item {
                                        Layout.fillWidth: true
                                        height: 54  // 增加高度以容纳浮动标签
                                        visible: customPrefixRadio.checked

                                        Rectangle {
                                            id: customPrefixContainer
                                            anchors.fill: parent
                                            anchors.topMargin: 8  // 为浮动标签留出空间
                                            color: customPrefixRadio.checked ? "white" : "#f5f5f5"
                                            radius: 6
                                            border.color: customPrefixField.activeFocus ? "#2196F3" : "#e0e0e0"
                                            border.width: customPrefixField.activeFocus ? 2 : 1

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                spacing: 8

                                                Text {
                                                    text: "📝"
                                                    font.pixelSize: 14
                                                    color: "#666"
                                                }

                                                TextField {
                                                    id: customPrefixField
                                                    Layout.fillWidth: true
                                                    enabled: customPrefixRadio.checked
                                                    font.pixelSize: 13
                                                    background: Item {}
                                                    selectByMouse: true
                                                    color: "#333"
                                                }
                                            }
                                        }

                                        // 浮动标签
                                        Rectangle {
                                            id: customPrefixFloatingLabel
                                            x: 42  // 右移以避免覆盖图标
                                            y: customPrefixField.activeFocus || customPrefixField.text.length > 0 ? 0 : 20
                                            width: customPrefixLabelText.implicitWidth + 8
                                            height: 16
                                            color: "white"
                                            visible: customPrefixRadio.checked

                                            Text {
                                                id: customPrefixLabelText
                                                anchors.centerIn: parent
                                                text: "输入自定义前缀"
                                                font.pixelSize: customPrefixField.activeFocus || customPrefixField.text.length > 0 ? 11 : 13
                                                color: customPrefixField.activeFocus ? "#2196F3" : "#666"
                                            }

                                            Behavior on y { PropertyAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                            Behavior on color { PropertyAnimation { duration: 200 } }
                                        }
                                    }
                                }
                            }

                            // 批量生成选项
                            GroupBox {
                                Layout.fillWidth: true
                                title: "生成选项"
                                font.pixelSize: 14
                                font.weight: Font.Medium

                                background: Rectangle {
                                    color: "#fafafa"
                                    radius: 8
                                    border.color: "#e0e0e0"
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    CheckBox {
                                        id: batchModeCheckBox
                                        text: "批量生成模式"
                                        font.pixelSize: 13

                                        indicator: Rectangle {
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            x: batchModeCheckBox.leftPadding
                                            y: parent.height / 2 - height / 2
                                            radius: 3
                                            border.color: batchModeCheckBox.checked ? "#2196F3" : "#ccc"
                                            border.width: 2
                                            color: batchModeCheckBox.checked ? "#2196F3" : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✓"
                                                color: "white"
                                                font.pixelSize: 10
                                                font.bold: true
                                                visible: batchModeCheckBox.checked
                                            }
                                        }

                                        onCheckedChanged: {
                                            if (checked) {
                                                batchCountSpinBox.focus = true
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 48  // 增加高度以容纳SpinBox
                                        color: batchModeCheckBox.checked ? "white" : "#f5f5f5"
                                        radius: 6
                                        border.color: batchModeCheckBox.checked ? "#e0e0e0" : "transparent"
                                        border.width: 1
                                        visible: batchModeCheckBox.checked

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10  // 增加边距
                                            spacing: 12

                                            Text {
                                                text: "🔢"
                                                font.pixelSize: 14
                                                color: "#666"
                                            }

                                            Label {
                                                text: "生成数量:"
                                                font.pixelSize: 13
                                                color: "#333"
                                            }

                                            SpinBox {
                                                id: batchCountSpinBox
                                                from: 1
                                                to: 50
                                                value: 5
                                                enabled: batchModeCheckBox.checked
                                                implicitWidth: 100
                                                implicitHeight: 32  // 设置固定高度

                                                background: Rectangle {
                                                    color: "#f8f9fa"
                                                    radius: 4
                                                    border.color: "#e0e0e0"
                                                }
                                            }

                                            Label {
                                                text: "个"
                                                font.pixelSize: 13
                                                color: "#666"
                                            }

                                            Item { Layout.fillWidth: true }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 36  // 增加高度以容纳文本
                                        color: "#fff3e0"
                                        radius: 6
                                        border.color: "#ffcc02"
                                        border.width: 1
                                        visible: batchModeCheckBox.checked

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 8

                                            Text {
                                                text: "💡"
                                                font.pixelSize: 12
                                                color: "#f57c00"
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: "批量模式将同时生成多个邮箱，请注意域名配额限制"
                                                font.pixelSize: 11
                                                color: "#f57c00"
                                                wrapMode: Text.WordWrap  // 确保文字换行
                                                maximumLineCount: 2  // 最多显示2行
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 右列：标签设置和备注
                        ColumnLayout {
                            Layout.preferredWidth: parent.width * 0.55  // 增加右列宽度
                            Layout.alignment: Qt.AlignTop
                            spacing: 16

                            // 标签选择器
                            GroupBox {
                                Layout.fillWidth: true
                                title: "标签设置"
                                font.pixelSize: 14
                                font.weight: Font.Medium

                                background: Rectangle {
                                    color: "#fafafa"
                                    radius: 8
                                    border.color: "#e0e0e0"
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    Label {
                                        text: "为生成的邮箱添加标签，便于分类管理（可选择多个）"
                                        font.pixelSize: 12
                                        color: "#666"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    // 标签搜索框 - 浮动标签效果
                                    Item {
                                        Layout.fillWidth: true
                                        height: 50  // 增加高度以容纳浮动标签

                                        Rectangle {
                                            id: searchInputContainer
                                            anchors.fill: parent
                                            anchors.topMargin: 8  // 为浮动标签留出空间
                                            color: "white"
                                            radius: 6
                                            border.color: tagSearchField.activeFocus ? "#2196F3" : "#ddd"
                                            border.width: tagSearchField.activeFocus ? 2 : 1

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 8
                                                spacing: 8

                                                Text {
                                                    text: "🔍"
                                                    font.pixelSize: 14
                                                    color: "#666"
                                                }

                                                TextField {
                                                    id: tagSearchField
                                                    Layout.fillWidth: true
                                                    font.pixelSize: 13
                                                    color: "#333"
                                                    background: Item {}
                                                    selectByMouse: true

                                                    onTextChanged: {
                                                        filterTags(text)
                                                    }
                                                }

                                                Button {
                                                    visible: tagSearchField.text.length > 0
                                                    text: "✕"
                                                    width: 20
                                                    height: 20
                                                    background: Rectangle {
                                                        color: parent.hovered ? "#f0f0f0" : "transparent"
                                                        radius: 10
                                                    }
                                                    onClicked: {
                                                        tagSearchField.text = ""
                                                        filterTags("")
                                                    }
                                                }
                                            }
                                        }

                                        // 浮动标签
                                        Rectangle {
                                            id: floatingLabel
                                            x: 42  // 右移以避免覆盖搜索图标（20 + 14 + 8 = 42）
                                            y: tagSearchField.activeFocus || tagSearchField.text.length > 0 ? 0 : 20
                                            width: floatingLabelText.implicitWidth + 8
                                            height: 16
                                            color: "white"
                                            visible: true

                                            Text {
                                                id: floatingLabelText
                                                anchors.centerIn: parent
                                                text: "搜索标签"
                                                font.pixelSize: tagSearchField.activeFocus || tagSearchField.text.length > 0 ? 11 : 13
                                                color: tagSearchField.activeFocus ? "#2196F3" : "#666"
                                            }

                                            Behavior on y { PropertyAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                            Behavior on color { PropertyAnimation { duration: 200 } }
                                        }
                                    }

                                    // 已选择的标签显示
                                    Flow {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: selectedTagsRepeater.count > 0 ? implicitHeight : 0
                                        spacing: 6
                                        visible: selectedTagsRepeater.count > 0
                                        
                                        Repeater {
                                            id: selectedTagsRepeater
                                            model: selectedTagsList
                                            
                                            Rectangle {
                                                width: tagContent.implicitWidth + 16
                                                height: 28
                                                color: modelData.color || "#2196F3"
                                                radius: 14
                                                opacity: 0.9
                                                
                                                RowLayout {
                                                    id: tagContent
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    
                                                    Text {
                                                        text: modelData.icon || "🏷️"
                                                        font.pixelSize: 12
                                                        color: "white"
                                                    }
                                                    
                                                    Text {
                                                        text: modelData.name || ""
                                                        font.pixelSize: 12
                                                        font.weight: Font.Medium
                                                        color: "white"
                                                    }
                                                    
                                                    Rectangle {
                                                        width: 16
                                                        height: 16
                                                        radius: 8
                                                        color: "#40ffffff"
                                                        
                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "×"
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: "white"
                                                        }
                                                        
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: removeSelectedTag(modelData)
                                                            hoverEnabled: true
                                                            onContainsMouseChanged: {
                                                                parent.color = containsMouse ? "#60ffffff" : "#40ffffff"
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    // 重要：不接受点击事件，让子元素处理
                                                    acceptedButtons: Qt.NoButton
                                                    onContainsMouseChanged: {
                                                        parent.opacity = containsMouse ? 1.0 : 0.9
                                                    }
                                                }
                                                
                                                Behavior on opacity { PropertyAnimation { duration: 150 } }
                                            }
                                        }
                                    }

                                    // 可选标签列表
                                    ScrollView {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Math.min(availableTagsColumn.implicitHeight, 120)
                                        visible: filteredTagsList.length > 0
                                        clip: true
                                        
                                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                        
                                        Column {
                                            id: availableTagsColumn
                                            width: parent.width
                                            spacing: 2
                                            
                                            Repeater {
                                                model: filteredTagsList
                                                
                                                Rectangle {
                                                    width: parent.width
                                                    height: 32
                                                    color: tagMouseArea.containsMouse ? "#f0f0f0" : "transparent"
                                                    radius: 4
                                                    
                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 8
                                                        anchors.rightMargin: 8
                                                        spacing: 8
                                                        
                                                        Rectangle {
                                                            width: 20
                                                            height: 20
                                                            radius: 10
                                                            color: modelData.color || "#2196F3"
                                                            
                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: modelData.icon || "🏷️"
                                                                font.pixelSize: 10
                                                                color: "white"
                                                            }
                                                        }
                                                        
                                                        Text {
                                                            Layout.fillWidth: true
                                                            text: modelData.name || ""
                                                            font.pixelSize: 13
                                                            color: "#333"
                                                            elide: Text.ElideRight
                                                        }
                                                        
                                                        Text {
                                                            text: (modelData.usage_count || 0) + " 次使用"
                                                            font.pixelSize: 11
                                                            color: "#999"
                                                        }
                                                    }
                                                    
                                                    MouseArea {
                                                        id: tagMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onClicked: addSelectedTag(modelData)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Button {
                                            text: "🔄 刷新标签"
                                            font.pixelSize: 11
                                            implicitHeight: 28
                                            flat: true
                                            onClicked: {
                                                addLogMessage("🔄 正在刷新标签列表...")
                                                loadAllTags()
                                            }

                                            background: Rectangle {
                                                color: parent.hovered ? "#f0f0f0" : "transparent"
                                                radius: 4
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Label {
                                            text: "已选择 " + selectedTagsList.length + " 个标签"
                                            font.pixelSize: 11
                                            color: "#666"
                                        }
                                    }
                                }
                            }

                            // 备注输入 - 浮动标签效果
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 88  // 减少高度，因为移除了标题

                                // 输入框容器
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: 8  // 为浮动标签留出空间
                                    height: 80
                                    color: "white"
                                    radius: 6
                                    border.color: notesField.activeFocus ? "#2196F3" : "#e0e0e0"
                                    border.width: notesField.activeFocus ? 2 : 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 8

                                        Text {
                                            text: "💭"
                                            font.pixelSize: 14
                                            color: "#666"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        TextField {
                                            id: notesField
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            font.pixelSize: 13
                                            background: Item {}
                                            selectByMouse: true
                                            color: "#333"
                                            verticalAlignment: TextInput.AlignVCenter
                                        }
                                    }

                                    // 浮动标签
                                    Rectangle {
                                        x: 42  // 右移以避免覆盖图标
                                        y: notesField.activeFocus || notesField.text.length > 0 ? -8 : 32
                                        width: notesLabelText.implicitWidth + 8
                                        height: 16
                                        color: "white"
                                        visible: notesField.text.length === 0  // 只在没有内容时显示

                                        Text {
                                            id: notesLabelText
                                            anchors.centerIn: parent
                                            text: "为邮箱添加备注说明（可选）"
                                            font.pixelSize: notesField.activeFocus || notesField.text.length > 0 ? 11 : 13
                                            color: notesField.activeFocus ? "#2196F3" : "#666"
                                        }

                                        Behavior on y { PropertyAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                        Behavior on color { PropertyAnimation { duration: 200 } }
                                        Behavior on visible { PropertyAnimation { duration: 150 } }  // 添加显示/隐藏动画
                                    }
                                }
                            }
                        }
                    }

                    // 生成按钮和进度指示器
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        // 进度条
                        ProgressBar {
                            id: progressBar
                            Layout.fillWidth: true
                            value: 0
                            visible: value > 0

                            background: Rectangle {
                                implicitWidth: 200
                                implicitHeight: 6
                                color: "#e0e0e0"
                                radius: 3
                            }

                            contentItem: Item {
                                implicitWidth: 200
                                implicitHeight: 6

                                Rectangle {
                                    width: progressBar.visualPosition * parent.width
                                    height: parent.height
                                    radius: 3
                                    color: "#2196F3"
                                }
                            }
                        }

                        // 生成按钮
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: 12

                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: generateButton.enabled ? "#42A5F5" : "#e0e0e0"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: generateButton.enabled ? "#1976D2" : "#bdbdbd"
                                }
                            }

                            // 阴影效果
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -2
                                color: "#20000000"
                                radius: parent.radius + 2
                                z: -1
                                y: 2
                                visible: generateButton.enabled
                            }

                            Button {
                                id: generateButton
                                anchors.fill: parent
                                text: {
                                    if (isGenerating) {
                                        return "🔄 生成中..."
                                    } else if (batchModeCheckBox.checked) {
                                        return "🎯 批量生成 " + batchCountSpinBox.value + " 个邮箱"
                                    } else {
                                        return "🎯 生成新邮箱"
                                    }
                                }
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                enabled: root.isConfigured && !isGenerating

                                background: Rectangle {
                                    color: "transparent"
                                    radius: 12
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: parent.enabled ? "white" : "#999"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                property bool isGenerating: false

                                onClicked: {
                                    if (!validateInput()) {
                                        return
                                    }

                                    isGenerating = true
                                    safetyTimer.restart()

                                    var prefixType = "random_name"
                                    if (randomStringRadio.checked) prefixType = "random_string"
                                    else if (customPrefixRadio.checked) prefixType = "custom"

                                    var selectedTagIds = getSelectedTagIds()
                                    var selectedTagNames = getSelectedTagNames()

                                    console.log("生成邮箱 - 选中标签:", selectedTagNames)

                                    if (emailController) {
                                        try {
                                            if (batchModeCheckBox.checked) {
                                                addLogMessage("🔄 开始批量生成 " + batchCountSpinBox.value + " 个邮箱...")
                                                if (selectedTagNames.length > 0) {
                                                    addLogMessage("📌 标签: " + selectedTagNames.join(", "))
                                                }
                                                emailController.batchGenerateEmails(
                                                    batchCountSpinBox.value,
                                                    prefixType,
                                                    customPrefixField.text,
                                                    selectedTagIds,
                                                    notesField.text
                                                )
                                            } else {
                                                addLogMessage("🔄 开始生成邮箱...")
                                                if (selectedTagNames.length > 0) {
                                                    addLogMessage("📌 标签: " + selectedTagNames.join(", "))
                                                }
                                                emailController.generateCustomEmail(
                                                    prefixType,
                                                    customPrefixField.text,
                                                    selectedTagIds,
                                                    notesField.text
                                                )
                                            }
                                        } catch (e) {
                                            console.error("生成邮箱时发生错误:", e)
                                            addLogMessage("❌ 生成邮箱时发生错误: " + e)
                                            isGenerating = false
                                        }
                                    } else {
                                        console.error("emailController未初始化")
                                        addLogMessage("❌ 系统错误: 控制器未初始化")
                                        isGenerating = false
                                    }
                                }
                            }

                            // 安全定时器
                            Timer {
                                id: safetyTimer
                                interval: 30000
                                running: generateButton.isGenerating
                                repeat: false
                                onTriggered: {
                                    if (generateButton.isGenerating) {
                                        console.log("安全定时器触发：重置生成按钮状态")
                                        generateButton.isGenerating = false
                                        addLogMessage("⚠️ 生成操作超时，已重置按钮状态")
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }

    // 监听标签控制器的信号
    Connections {
        target: typeof tagController !== 'undefined' ? tagController : null
        
        function onTagCreated(tagData) {
            addLogMessage("🏷️ 新标签已创建: " + tagData.name)
            loadAllTags() // 重新加载标签列表
        }
        
        function onTagUpdated(tagData) {
            addLogMessage("🏷️ 标签已更新: " + tagData.name)
            loadAllTags() // 重新加载标签列表
        }
        
        function onTagDeleted(tagId) {
            addLogMessage("🗑️ 标签已删除 (ID: " + tagId + ")")
            loadAllTags() // 重新加载标签列表
        }
    }

    Component.onCompleted: {
        console.log("邮箱生成页面已初始化")
        loadAllTags()
        root.requestTagRefresh()
        addLogMessage("🔄 正在加载标签列表...")
    }

    // 标签管理函数
    function loadAllTags() {
        // 从数据库加载所有标签
        if (typeof tagController !== 'undefined' && tagController) {
            try {
                var result = tagController.getAllTags()
                var resultData = JSON.parse(result)
                
                if (resultData.success) {
                    allTagsList = resultData.tags || []
                    filteredTagsList = allTagsList.slice() // 复制数组
                    addLogMessage("✅ 已加载 " + resultData.count + " 个标签")
                } else {
                    console.error("获取标签失败:", resultData.error || "未知错误")
                    addLogMessage("❌ 获取标签失败: " + (resultData.error || "未知错误"))
                    loadFallbackTags()
                }
            } catch (e) {
                console.error("加载标签失败:", e)
                addLogMessage("❌ 加载标签失败: " + e)
                loadFallbackTags()
            }
        } else {
            console.log("tagController不可用，加载测试数据")
            addLogMessage("⚠️ tagController不可用，加载测试数据")
            loadFallbackTags()
        }
    }

    function loadFallbackTags() {
        // 备用测试数据
        allTagsList = [
            {id: 1, name: "工作", color: "#2196F3", icon: "💼", usage_count: 15, description: "工作相关邮箱"},
            {id: 2, name: "个人", color: "#4CAF50", icon: "👤", usage_count: 8, description: "个人使用邮箱"},
            {id: 3, name: "购物", color: "#FF9800", icon: "🛒", usage_count: 12, description: "购物网站注册"},
            {id: 4, name: "社交", color: "#9C27B0", icon: "💬", usage_count: 6, description: "社交媒体账号"},
            {id: 5, name: "学习", color: "#F44336", icon: "📚", usage_count: 10, description: "学习平台注册"},
            {id: 6, name: "测试用", color: "#e74c3c", icon: "🧪", usage_count: 3, description: "用于测试目的的邮箱"},
            {id: 7, name: "开发用", color: "#3498db", icon: "💻", usage_count: 5, description: "开发环境使用的邮箱"}
        ]
        filteredTagsList = allTagsList.slice()
        addLogMessage("✅ 已加载 " + allTagsList.length + " 个标签（备用数据）")
    }

    function filterTags(searchText) {
        if (!searchText || searchText.length === 0) {
            filteredTagsList = allTagsList.slice()
            return
        }
        
        var query = searchText.toLowerCase()
        var filtered = []
        
        for (var i = 0; i < allTagsList.length; i++) {
            var tag = allTagsList[i]
            if (tag.name && tag.name.toLowerCase().includes(query)) {
                // 排除已选择的标签
                var isSelected = false
                for (var j = 0; j < selectedTagsList.length; j++) {
                    if (selectedTagsList[j].id === tag.id) {
                        isSelected = true
                        break
                    }
                }
                if (!isSelected) {
                    filtered.push(tag)
                }
            }
        }
        
        filteredTagsList = filtered
    }

    function addSelectedTag(tag) {
        console.log("添加标签被调用:", tag.name)
        
        var newSelectedTags = selectedTagsList.slice()
        
        // 检查是否已存在
        for (var i = 0; i < newSelectedTags.length; i++) {
            if (newSelectedTags[i].id === tag.id) {
                console.log("标签已存在，不重复添加:", tag.name)
                addLogMessage("⚠️ 标签 " + tag.name + " 已存在")
                return  // 已存在，不重复添加
            }
        }
        
        newSelectedTags.push(tag)
        
        // 确保触发UI更新
        selectedTagsList = []
        selectedTagsList = newSelectedTags
        
        // 重新过滤可选标签
        filterTags(tagSearchField.text)
        
        addLogMessage("📌 已添加标签: " + tag.name)
        console.log("标签添加成功，当前标签数量:", selectedTagsList.length)
    }

    function removeSelectedTag(tag) {
        console.log("移除标签被调用:", tag.name, "当前选中标签数量:", selectedTagsList.length)
        
        var newSelectedTags = []
        var found = false
        
        for (var i = 0; i < selectedTagsList.length; i++) {
            if (selectedTagsList[i].id !== tag.id) {
                newSelectedTags.push(selectedTagsList[i])
            } else {
                found = true
            }
        }
        
        if (found) {
            // 先清空数组，然后重新赋值，确保触发UI更新
            var temp = selectedTagsList
            selectedTagsList = []
            selectedTagsList = newSelectedTags
            
            // 重新过滤可选标签
            filterTags(tagSearchField.text)
            
            addLogMessage("🗑️ 已移除标签: " + tag.name)
            console.log("标签移除成功，剩余标签数量:", selectedTagsList.length)
        } else {
            console.log("未找到要移除的标签:", tag.name)
            addLogMessage("⚠️ 未找到要移除的标签: " + tag.name)
        }
    }

    function getSelectedTagIds() {
        var ids = []
        for (var i = 0; i < selectedTagsList.length; i++) {
            ids.push(selectedTagsList[i].id)
        }
        return ids
    }

    function getSelectedTagNames() {
        var names = []
        for (var i = 0; i < selectedTagsList.length; i++) {
            names.push(selectedTagsList[i].name)
        }
        return names
    }

    // 内部方法
    function updateLatestEmail(email) {
        latestEmailLabel.text = email
    }

    function updateProgress(value) {
        progressBar.value = value / 100.0
    }

    function addLogMessage(message) {
        logArea.addLog(message)
    }

    function enableGenerateButton() {
        generateButton.isGenerating = false
        safetyTimer.stop()
        addLogMessage("✅ 生成操作完成，按钮已重新启用")
    }

    function disableGenerateButton() {
        generateButton.isGenerating = true
        addLogMessage("🔒 生成按钮已禁用")
    }

    function refreshTags() {
        console.log("刷新标签列表")
        root.requestTagRefresh()
        addLogMessage("🔄 正在刷新标签列表...")
    }

    function handleNewTag(tagName) {
        console.log("处理新标签创建请求:", tagName)
        root.createNewTag(tagName)
        addLogMessage("📝 正在创建新标签: " + tagName)
    }

    function onTagCreated(tag) {
        console.log("新标签已创建:", tag.name)
        addLogMessage("✅ 标签创建成功: " + tag.name)
        if (tagSelector) {
            tagSelector.selectTagById(tag.id)
        }
    }

    function onTagsLoaded(tags) {
        console.log("标签列表已加载，数量:", tags.length)
        root.availableTags = tags
        addLogMessage("✅ 标签列表已加载，共 " + tags.length + " 个标签")
    }

    function handleBatchResult(result) {
        if (result.success > 0) {
            addLogMessage("✅ 批量生成成功: " + result.success + " 个邮箱")
            if (result.emails && result.emails.length > 0) {
                updateLatestEmail(result.emails[0].email_address)
            }
        }
        if (result.failed > 0) {
            addLogMessage("❌ 生成失败: " + result.failed + " 个邮箱")
        }
        if (result.errors && result.errors.length > 0) {
            result.errors.forEach(function(error) {
                addLogMessage("❌ 错误: " + error)
            })
        }
    }

    function handleBatchProgress(current, total, message) {
        var percentage = Math.round((current / total) * 100)
        updateProgress(percentage)
        addLogMessage("📊 进度: " + current + "/" + total + " (" + percentage + "%) - " + message)
    }

    function validateInput() {
        if (!root.isConfigured) {
            addLogMessage("❌ 请先完成域名配置")
            return false
        }

        if (customPrefixRadio.checked && customPrefixField.text.trim().length === 0) {
            addLogMessage("❌ 请输入自定义前缀")
            return false
        }

        return true
    }

    function clearInputs() {
        customPrefixField.text = ""
        notesField.text = ""
        randomNameRadio.checked = true
        batchModeCheckBox.checked = false
        tagSearchField.text = ""
        selectedTagsList = []
        filterTags("")
        addLogMessage("🧹 输入字段已清空")
    }
}