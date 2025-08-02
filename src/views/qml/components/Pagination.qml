/*
 * 分页组件
 * 提供统一的分页控制和导航功能
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: root
    height: visible ? 50 : 0
    color: "transparent"
    
    // 对外暴露的属性
    property int currentPage: 1
    property int totalPages: 1
    property int totalItems: 0
    property int pageSize: 20
    property bool showPageInfo: true
    property bool showPageSizeSelector: true
    property var pageSizeOptions: [10, 20, 50, 100]
    
    // 对外暴露的信号
    signal pageChanged(int page)
    signal pageSizeChanged(int size)
    
    // 计算属性
    readonly property int startItem: (currentPage - 1) * pageSize + 1
    readonly property int endItem: Math.min(currentPage * pageSize, totalItems)
    readonly property bool hasPrevious: currentPage > 1
    readonly property bool hasNext: currentPage < totalPages
    
    // 显示条件
    visible: totalPages > 1 || showPageSizeSelector
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15
        
        // 页面大小选择器
        RowLayout {
            visible: root.showPageSizeSelector
            spacing: 8
            
            Label {
                text: "每页显示:"
                font.pixelSize: 14
                color: "#666"
            }
            
            ComboBox {
                id: pageSizeCombo
                model: root.pageSizeOptions
                currentIndex: {
                    var index = model.indexOf(root.pageSize)
                    return index >= 0 ? index : 1 // 默认选择20
                }
                
                onCurrentValueChanged: {
                    if (currentValue !== root.pageSize) {
                        root.pageSizeChanged(currentValue)
                    }
                }
                
                delegate: ItemDelegate {
                    width: pageSizeCombo.width
                    text: modelData + " 条"
                    font.pixelSize: 14
                }
                
                contentItem: Text {
                    text: pageSizeCombo.currentValue + " 条"
                    font.pixelSize: 14
                    color: "#333"
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
        
        Item { Layout.fillWidth: true }
        
        // 页面信息
        Label {
            visible: root.showPageInfo && root.totalItems > 0
            text: "显示 " + root.startItem + "-" + root.endItem + " 条，共 " + root.totalItems + " 条"
            font.pixelSize: 14
            color: "#666"
        }
        
        Item { Layout.fillWidth: true }
        
        // 分页控制按钮
        RowLayout {
            visible: root.totalPages > 1
            spacing: 5
            
            // 首页按钮
            Button {
                text: "⏮️"
                enabled: root.hasPrevious
                implicitWidth: 36
                implicitHeight: 36
                ToolTip.text: "首页"
                onClicked: changePage(1)
            }
            
            // 上一页按钮
            Button {
                text: "⬅️"
                enabled: root.hasPrevious
                implicitWidth: 36
                implicitHeight: 36
                ToolTip.text: "上一页"
                onClicked: changePage(root.currentPage - 1)
            }
            
            // 页码按钮组
            Row {
                spacing: 2
                
                Repeater {
                    model: getPageNumbers()
                    
                    Button {
                        text: modelData === "..." ? "..." : modelData.toString()
                        enabled: modelData !== "..." && modelData !== root.currentPage
                        implicitWidth: 36
                        implicitHeight: 36
                        Material.background: modelData === root.currentPage ? Material.Blue : Material.Grey
                        font.bold: modelData === root.currentPage
                        
                        onClicked: {
                            if (modelData !== "...") {
                                changePage(modelData)
                            }
                        }
                    }
                }
            }
            
            // 下一页按钮
            Button {
                text: "➡️"
                enabled: root.hasNext
                implicitWidth: 36
                implicitHeight: 36
                ToolTip.text: "下一页"
                onClicked: changePage(root.currentPage + 1)
            }
            
            // 末页按钮
            Button {
                text: "⏭️"
                enabled: root.hasNext
                implicitWidth: 36
                implicitHeight: 36
                ToolTip.text: "末页"
                onClicked: changePage(root.totalPages)
            }
        }
        
        // 跳转到指定页面
        RowLayout {
            visible: root.totalPages > 5
            spacing: 8
            
            Label {
                text: "跳转到:"
                font.pixelSize: 14
                color: "#666"
            }
            
            TextField {
                id: jumpPageField
                implicitWidth: 60
                implicitHeight: 36
                font.pixelSize: 14
                horizontalAlignment: TextInput.AlignHCenter
                validator: IntValidator {
                    bottom: 1
                    top: root.totalPages
                }
                
                onAccepted: {
                    var page = parseInt(text)
                    if (page >= 1 && page <= root.totalPages) {
                        changePage(page)
                        text = ""
                    }
                }
            }
            
            Button {
                text: "跳转"
                implicitHeight: 36
                enabled: jumpPageField.text.length > 0
                onClicked: jumpPageField.accepted()
            }
        }
    }
    
    // 内部方法
    function changePage(page) {
        if (page >= 1 && page <= root.totalPages && page !== root.currentPage) {
            root.pageChanged(page)
        }
    }
    
    function getPageNumbers() {
        var pages = []
        var current = root.currentPage
        var total = root.totalPages
        
        if (total <= 7) {
            // 总页数少于等于7页，显示所有页码
            for (var i = 1; i <= total; i++) {
                pages.push(i)
            }
        } else {
            // 总页数大于7页，使用省略号
            if (current <= 4) {
                // 当前页在前面
                for (var i = 1; i <= 5; i++) {
                    pages.push(i)
                }
                pages.push("...")
                pages.push(total)
            } else if (current >= total - 3) {
                // 当前页在后面
                pages.push(1)
                pages.push("...")
                for (var i = total - 4; i <= total; i++) {
                    pages.push(i)
                }
            } else {
                // 当前页在中间
                pages.push(1)
                pages.push("...")
                for (var i = current - 1; i <= current + 1; i++) {
                    pages.push(i)
                }
                pages.push("...")
                pages.push(total)
            }
        }
        
        return pages
    }
    
    // 公共方法
    function reset() {
        root.currentPage = 1
        jumpPageField.text = ""
    }
    
    function goToPage(page) {
        changePage(page)
    }
    
    function nextPage() {
        if (root.hasNext) {
            changePage(root.currentPage + 1)
        }
    }
    
    function previousPage() {
        if (root.hasPrevious) {
            changePage(root.currentPage - 1)
        }
    }
    
    function firstPage() {
        changePage(1)
    }
    
    function lastPage() {
        changePage(root.totalPages)
    }
}
