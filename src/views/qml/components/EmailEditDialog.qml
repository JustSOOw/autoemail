/*
 * 邮箱编辑对话框组件
 * 用于编辑邮箱的备注信息和标签
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Dialog {
    id: root
    title: "编辑邮箱信息"
    modal: true
    width: 500
    height: 700
    anchors.centerIn: parent

    // 对外属性
    property int emailId: 0
    property string emailAddress: ""
    property string originalNotes: ""
    property var originalTags: []
    property var availableTags: []

    // 内部状态
    property var selectedTags: []
    property var filteredTags: []
    property bool isLoading: false

    // 信号
    signal editCompleted(int emailId, string notes, var tagIds)
    signal tagRefreshRequested()
    signal tagCreationRequested(var tagData)

    function openDialog(emailId, emailAddress, notes, tags, allTags) {
        root.emailId = emailId
        root.emailAddress = emailAddress
        root.originalNotes = notes || ""
        root.originalTags = tags || []
        root.availableTags = allTags || []

        console.log("打开编辑对话框 - 邮箱标签:", JSON.stringify(tags))
        console.log("打开编辑对话框 - 所有标签:", JSON.stringify(allTags))

        // 初始化UI
        notesField.text = root.originalNotes

        // 将标签名称转换为标签对象
        selectedTags = convertTagNamesToObjects(root.originalTags, root.availableTags)
        console.log("转换后的已选择标签:", JSON.stringify(selectedTags))

        // 过滤可用标签（排除已选择的）
        updateFilteredTags()

        open()
    }

    function convertTagNamesToObjects(tagNames, allTagObjects) {
        var tagObjects = []

        if (!tagNames || !allTagObjects) {
            return tagObjects
        }

        for (var i = 0; i < tagNames.length; i++) {
            var tagName = tagNames[i]

            // 在所有标签中查找匹配的标签对象
            for (var j = 0; j < allTagObjects.length; j++) {
                var tagObj = allTagObjects[j]
                if (tagObj.name === tagName) {
                    tagObjects.push(tagObj)
                    break
                }
            }
        }

        return tagObjects
    }

    function updateFilteredTags() {
        var filtered = []
        var searchText = tagSearchField.text.toLowerCase()

        for (var i = 0; i < availableTags.length; i++) {
            var tag = availableTags[i]
            // 检查是否已选择
            var isSelected = false
            for (var j = 0; j < selectedTags.length; j++) {
                if (selectedTags[j].id === tag.id) {
                    isSelected = true
                    break
                }
            }

            // 搜索过滤
            var matchesSearch = !searchText ||
                               (tag.name && tag.name.toLowerCase().includes(searchText))

            if (!isSelected && matchesSearch) {
                filtered.push(tag)
            }
        }

        filteredTags = filtered
    }

    function addTag(tag) {
        var newSelected = selectedTags.slice()
        newSelected.push(tag)
        selectedTags = newSelected
        updateFilteredTags()
    }

    function removeTag(tagToRemove) {
        var newSelected = []
        for (var i = 0; i < selectedTags.length; i++) {
            if (selectedTags[i].id !== tagToRemove.id) {
                newSelected.push(selectedTags[i])
            }
        }
        selectedTags = newSelected
        updateFilteredTags()
    }

    function getSelectedTagIds() {
        var ids = []
        for (var i = 0; i < selectedTags.length; i++) {
            ids.push(selectedTags[i].id)
        }
        return ids
    }

    background: Rectangle {
        color: "white"
        radius: 12
        border.color: "#e0e0e0"
        border.width: 1

        // 添加阴影效果
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            color: "#10000000"
            radius: parent.radius + 4
            z: -1
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // 邮箱信息显示 - 缩小高度
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: "#f8f9fa"
            radius: 8
            border.color: "#e9ecef"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: "📧"
                    font.pixelSize: 16
                    color: "#495057"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "邮箱地址"
                        font.pixelSize: 10
                        color: "#6c757d"
                        font.weight: Font.Medium
                    }

                    Text {
                        text: root.emailAddress
                        font.pixelSize: 13
                        color: "#212529"
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // 备注编辑区域 - 缩小高度
        GroupBox {
            Layout.fillWidth: true
            title: "备注信息"
            font.pixelSize: 13
            font.weight: Font.Medium

            background: Rectangle {
                color: "#fafafa"
                radius: 8
                border.color: "#e0e0e0"
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                // 备注输入框 - 缩小高度
                TextArea {
                    id: notesField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70

                    // 基本属性设置
                    font.pixelSize: 12
                    color: "#333"
                    selectByMouse: true
                    wrapMode: TextArea.Wrap

                    // 关键修复：设置内边距确保文字显示在输入框内部
                    leftPadding: 10
                    rightPadding: 10
                    topPadding: 8
                    bottomPadding: 8

                    // 自定义背景样式
                    background: Rectangle {
                        color: "white"
                        radius: 6
                        border.color: notesField.activeFocus ? "#2196F3" : "#e0e0e0"
                        border.width: notesField.activeFocus ? 2 : 1
                    }
                }
            }
        }

        // 标签编辑区域 - 修复滚动问题
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#fafafa"
            radius: 8
            border.color: "#e0e0e0"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // 标题
                Label {
                    text: "标签管理"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#333"
                }

                Label {
                    text: "选择或创建标签来分类管理邮箱"
                    font.pixelSize: 11
                    color: "#666"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                // 已选择的标签 - 缩小高度
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: "white"
                    radius: 6
                    border.color: "#e0e0e0"
                    visible: selectedTags.length > 0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Label {
                            text: "已选择的标签 (" + selectedTags.length + ")"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: "#495057"
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: selectedTags

                                Rectangle {
                                    width: tagContent.width + 12
                                    height: 24
                                    color: modelData.color || "#2196F3"
                                    radius: 12

                                    RowLayout {
                                        id: tagContent
                                        anchors.centerIn: parent
                                        spacing: 3

                                        // 智能图标显示
                                        Item {
                                            id: selectedTagIconContainer
                                            width: 12
                                            height: 12

                                            property bool isImagePath: {
                                                var icon = modelData.icon || "🏷️"
                                                return icon.includes("/") || icon.includes("\\") || icon.includes(".png") || icon.includes(".jpg") || icon.includes(".jpeg")
                                            }

                                            Image {
                                                anchors.fill: parent
                                                source: {
                                                    if (!selectedTagIconContainer.isImagePath) return ""
                                                    var icon = modelData.icon || ""
                                                    // 如果已经是file://格式，直接使用
                                                    if (icon.startsWith("file://")) {
                                                        return icon
                                                    }
                                                    // 否则添加file://前缀
                                                    return "file:///" + icon.replace(/\\/g, "/")
                                                }
                                                visible: selectedTagIconContainer.isImagePath
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                cache: true

                                                onStatusChanged: {
                                                    if (status === Image.Error) {
                                                        console.log("已选择标签图片加载失败:", source)
                                                        visible = false
                                                        fallbackIcon.visible = true
                                                    }
                                                }
                                            }

                                            Text {
                                                id: fallbackIcon
                                                anchors.centerIn: parent
                                                text: selectedTagIconContainer.isImagePath ? "🏷️" : (modelData.icon || "🏷️")
                                                font.pixelSize: 10
                                                visible: !selectedTagIconContainer.isImagePath
                                                color: "white"
                                            }
                                        }

                                        Text {
                                            text: modelData.name || ""
                                            font.pixelSize: 10
                                            color: "white"
                                            font.weight: Font.Medium
                                        }

                                        Rectangle {
                                            width: 14
                                            height: 14
                                            color: closeMouseArea.containsMouse ? "#ffffff40" : "transparent"
                                            radius: 7

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                color: "white"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                            }

                                            MouseArea {
                                                id: closeMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: removeTag(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 标签搜索 - 缩小高度
                Item {
                    Layout.fillWidth: true
                    height: 45  // 缩小高度

                    Rectangle {
                        id: searchContainer
                        anchors.fill: parent
                        anchors.topMargin: 6  // 为浮动标签留出空间
                        color: "white"
                        radius: 6
                        border.color: tagSearchField.activeFocus ? "#2196F3" : "#e0e0e0"
                        border.width: tagSearchField.activeFocus ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Text {
                                text: "🔍"
                                font.pixelSize: 12
                                color: "#666"
                            }

                            TextField {
                                id: tagSearchField
                                Layout.fillWidth: true
                                font.pixelSize: 12
                                color: "#333"
                                selectByMouse: true

                                // 移除placeholder，使用浮动标签
                                background: Rectangle {
                                    color: "transparent"
                                }

                                onTextChanged: updateFilteredTags()
                            }

                            Button {
                                text: "🏷️ 新建"
                                font.pixelSize: 10
                                implicitHeight: 20
                                flat: true
                                visible: tagSearchField.text.length > 0

                                background: Rectangle {
                                    color: parent.hovered ? "#2196F3" : "#e3f2fd"
                                    radius: 4
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: parent.hovered ? "white" : "#2196F3"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    var tagData = {
                                        name: tagSearchField.text.trim(),
                                        description: "",
                                        icon: "🏷️",
                                        color: "#2196F3"
                                    }
                                    root.tagCreationRequested(tagData)
                                }
                            }
                        }
                    }

                    // 浮动标签
                    Rectangle {
                        id: floatingLabel
                        x: 40  // 右移以避免覆盖搜索图标
                        y: tagSearchField.activeFocus || tagSearchField.text.length > 0 ? 0 : 16
                        width: floatingLabelText.implicitWidth + 6
                        height: 14
                        color: "white"
                        visible: true

                        Text {
                            id: floatingLabelText
                            anchors.centerIn: parent
                            text: "搜索或创建标签"
                            font.pixelSize: tagSearchField.activeFocus || tagSearchField.text.length > 0 ? 10 : 12
                            color: tagSearchField.activeFocus ? "#2196F3" : "#666"
                        }

                        Behavior on y { PropertyAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { PropertyAnimation { duration: 200 } }
                    }
                }

                // 可选标签列表 - 自动适应剩余高度
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true  // 占用剩余的所有高度
                    Layout.minimumHeight: 100  // 最小高度确保至少显示几个标签
                    visible: filteredTags.length > 0
                    color: "white"
                    radius: 6
                    border.color: "#e0e0e0"

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 4
                        model: filteredTags
                        spacing: 3
                        clip: true  // 启用剪裁

                        // 确保ListView可以滚动
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.VerticalFlick
                        interactive: true  // 明确启用交互

                        // 隐藏滚动条
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AlwaysOff
                        }
                        ScrollBar.horizontal: ScrollBar {
                            policy: ScrollBar.AlwaysOff
                        }

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 32  // 缩小每个标签项的高度
                        color: mouseArea.containsMouse ? "#f8f9fa" : "white"
                        radius: 6
                        border.color: "#e9ecef"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6

                            Rectangle {
                                width: 18
                                height: 18
                                color: modelData.color || "#2196F3"
                                radius: 9

                                // 智能图标显示
                                Item {
                                    id: tagListIconContainer
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14

                                    property bool isImagePath: {
                                        var icon = modelData.icon || "🏷️"
                                        return icon.includes("/") || icon.includes("\\") || icon.includes(".png") || icon.includes(".jpg") || icon.includes(".jpeg")
                                    }

                                    Image {
                                        anchors.fill: parent
                                        source: {
                                            if (!tagListIconContainer.isImagePath) return ""
                                            var icon = modelData.icon || ""
                                            // 如果已经是file://格式，直接使用
                                            if (icon.startsWith("file://")) {
                                                return icon
                                            }
                                            // 否则添加file://前缀
                                            return "file:///" + icon.replace(/\\/g, "/")
                                        }
                                        visible: tagListIconContainer.isImagePath
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        cache: true

                                        onStatusChanged: {
                                            if (status === Image.Error) {
                                                console.log("标签列表图片加载失败:", source)
                                                visible = false
                                                fallbackIcon.visible = true
                                            }
                                        }
                                    }

                                    Text {
                                        id: fallbackIcon
                                        anchors.centerIn: parent
                                        text: tagListIconContainer.isImagePath ? "🏷️" : (modelData.icon || "🏷️")
                                        font.pixelSize: 9
                                        visible: !tagListIconContainer.isImagePath
                                        color: "white"
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || ""
                                font.pixelSize: 11
                                color: "#495057"
                                elide: Text.ElideRight
                            }

                            Text {
                                text: (modelData.usage_count || 0) + " 次使用"
                                font.pixelSize: 9
                                color: "#6c757d"
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: addTag(modelData)
                        }
                    }
                }
            }

                // 无标签提示
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    visible: filteredTags.length === 0 && tagSearchField.text.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            text: "🏷️"
                            font.pixelSize: 24
                            color: "#adb5bd"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "没有可用的标签"
                            font.pixelSize: 12
                            color: "#6c757d"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Button {
                            text: "刷新标签列表"
                            font.pixelSize: 11
                            Layout.alignment: Qt.AlignHCenter
                            onClicked: root.tagRefreshRequested()
                        }
                    }
                }
            }
        }

        // 操作按钮
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "取消"
                Layout.preferredWidth: 100
                onClicked: root.close()
            }

            Item { Layout.fillWidth: true }

            Button {
                text: isLoading ? "保存中..." : "保存"
                Layout.preferredWidth: 100
                Material.background: Material.Blue
                enabled: !isLoading
                onClicked: {
                    isLoading = true
                    var tagIds = getSelectedTagIds()
                    root.editCompleted(root.emailId, notesField.text, tagIds)
                }
            }
        }
    }

    onClosed: {
        // 重置状态
        isLoading = false
        tagSearchField.text = ""
        selectedTags = []
        filteredTags = []
    }
}