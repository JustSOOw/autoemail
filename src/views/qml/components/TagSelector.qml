/*
 * 标签选择器组件
 * 支持从已有标签中选择多个标签，以及创建新标签
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: root
    color: "#f8f9fa"
    radius: 8
    border.color: "#e0e0e0"
    border.width: 1
    
    // 对外暴露的属性
    property var availableTags: []  // 可用标签列表
    property var selectedTags: []   // 已选择的标签列表
    property bool allowCreateNew: true  // 是否允许创建新标签
    property string placeholderText: "搜索或添加标签..."
    property int maxHeight: 200
    property bool isExpanded: false
    
    // 对外暴露的信号
    signal tagSelected(var tag)
    signal tagDeselected(var tag)
    signal newTagRequested(string tagName)
    signal tagsChanged(var selectedTags)
    
    // 内部属性
    property string searchText: ""
    property var filteredTags: []
    property bool showDropdown: false
    
    implicitHeight: Math.min(contentColumn.implicitHeight + 16, maxHeight)
    
    // 计算过滤后的标签
    function updateFilteredTags() {
        if (!searchText || searchText.length === 0) {
            filteredTags = availableTags.slice()
            return
        }
        
        var query = searchText.toLowerCase()
        var filtered = []
        
        for (var i = 0; i < availableTags.length; i++) {
            var tag = availableTags[i]
            if (tag.name && tag.name.toLowerCase().includes(query)) {
                // 排除已选择的标签
                var isSelected = false
                for (var j = 0; j < selectedTags.length; j++) {
                    if (selectedTags[j].id === tag.id) {
                        isSelected = true
                        break
                    }
                }
                if (!isSelected) {
                    filtered.push(tag)
                }
            }
        }
        
        filteredTags = filtered
    }
    
    // 添加标签到选择列表
    function addTag(tag) {
        var newSelectedTags = selectedTags.slice()
        
        // 检查是否已存在
        for (var i = 0; i < newSelectedTags.length; i++) {
            if (newSelectedTags[i].id === tag.id) {
                return  // 已存在，不重复添加
            }
        }
        
        newSelectedTags.push(tag)
        selectedTags = newSelectedTags
        
        tagSelected(tag)
        tagsChanged(selectedTags)
        
        // 清空搜索
        searchField.text = ""
        showDropdown = false
    }
    
    // 从选择列表移除标签
    function removeTag(tag) {
        var newSelectedTags = []
        
        for (var i = 0; i < selectedTags.length; i++) {
            if (selectedTags[i].id !== tag.id) {
                newSelectedTags.push(selectedTags[i])
            }
        }
        
        selectedTags = newSelectedTags
        
        tagDeselected(tag)
        tagsChanged(selectedTags)
        updateFilteredTags()
    }
    
    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        
        // 搜索输入框
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "white"
            radius: 6
            border.color: searchField.activeFocus ? "#2196F3" : "#ddd"
            border.width: searchField.activeFocus ? 2 : 1
            
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
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: root.placeholderText
                    font.pixelSize: 13
                    color: "#333"
                    background: Item {}
                    selectByMouse: true
                    
                    onTextChanged: {
                        searchText = text
                        updateFilteredTags()
                        showDropdown = text.length > 0
                    }
                    
                    onFocusChanged: {
                        if (focus) {
                            showDropdown = text.length > 0
                        }
                    }
                    
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (allowCreateNew && text.trim().length > 0) {
                                // 检查是否是新标签
                                var isExisting = false
                                for (var i = 0; i < availableTags.length; i++) {
                                    if (availableTags[i].name.toLowerCase() === text.trim().toLowerCase()) {
                                        addTag(availableTags[i])
                                        isExisting = true
                                        break
                                    }
                                }
                                
                                if (!isExisting) {
                                    newTagRequested(text.trim())
                                    searchField.text = ""
                                    showDropdown = false
                                }
                            }
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            searchField.text = ""
                            showDropdown = false
                            searchField.focus = false
                            event.accepted = true
                        }
                    }
                }
                
                Button {
                    visible: searchField.text.length > 0
                    text: "✕"
                    width: 20
                    height: 20
                    background: Rectangle {
                        color: parent.hovered ? "#f0f0f0" : "transparent"
                        radius: 10
                    }
                    onClicked: {
                        searchField.text = ""
                        showDropdown = false
                    }
                }
            }
        }
        
        // 已选择的标签显示
        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: selectedTags.length > 0 ? implicitHeight : 0
            spacing: 6
            visible: selectedTags.length > 0
            
            Repeater {
                model: selectedTags
                
                Rectangle {
                    width: tagContent.implicitWidth + 16
                    height: 28
                    color: modelData.color || "#2196F3"
                    radius: 14
                    
                    // 半透明效果
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
                                onClicked: removeTag(modelData)
                                hoverEnabled: true
                                onContainsMouseChanged: {
                                    parent.color = containsMouse ? "#60ffffff" : "#40ffffff"
                                }
                            }
                        }
                    }
                    
                    // 悬停效果
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: {
                            parent.opacity = containsMouse ? 1.0 : 0.9
                        }
                    }
                    
                    Behavior on opacity { PropertyAnimation { duration: 150 } }
                }
            }
        }
        
        // 下拉列表
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(dropdownContent.implicitHeight, 120)
            visible: showDropdown && (filteredTags.length > 0 || (allowCreateNew && searchText.length > 0))
            clip: true
            
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            
            Column {
                id: dropdownContent
                width: parent.width
                spacing: 2
                
                // 现有标签选项
                Repeater {
                    model: filteredTags
                    
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
                            onClicked: addTag(modelData)
                        }
                    }
                }
                
                // 创建新标签选项
                Rectangle {
                    width: parent.width
                    height: 32
                    color: newTagMouseArea.containsMouse ? "#e8f5e8" : "transparent"
                    radius: 4
                    visible: allowCreateNew && searchText.length > 0
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        
                        Text {
                            text: "➕"
                            font.pixelSize: 14
                            color: "#4CAF50"
                        }
                        
                        Text {
                            Layout.fillWidth: true
                            text: "创建新标签: \"" + searchText + "\""
                            font.pixelSize: 13
                            font.italic: true
                            color: "#4CAF50"
                            elide: Text.ElideRight
                        }
                    }
                    
                    MouseArea {
                        id: newTagMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            newTagRequested(searchText.trim())
                            searchField.text = ""
                            showDropdown = false
                        }
                    }
                }
            }
        }
    }
    
    // 点击外部区域关闭下拉列表
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            showDropdown = false
            searchField.focus = false
        }
    }
    
    // 监听可用标签变化
    onAvailableTagsChanged: {
        updateFilteredTags()
    }
    
    // 对外提供的方法
    function clearSelection() {
        selectedTags = []
        tagsChanged(selectedTags)
    }
    
    function selectTagById(tagId) {
        for (var i = 0; i < availableTags.length; i++) {
            if (availableTags[i].id === tagId) {
                addTag(availableTags[i])
                break
            }
        }
    }
    
    function getSelectedTagIds() {
        var ids = []
        for (var i = 0; i < selectedTags.length; i++) {
            ids.push(selectedTags[i].id)
        }
        return ids
    }
    
    function getSelectedTagNames() {
        var names = []
        for (var i = 0; i < selectedTags.length; i++) {
            names.push(selectedTags[i].name)
        }
        return names
    }
}