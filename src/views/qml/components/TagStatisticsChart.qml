/*
 * 标签统计图表组件
 * 显示标签使用情况的可视化图表
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: root

    // ==================== 自定义属性 ====================
    
    property var tagList: []
    property string chartType: "bar" // bar, pie, line
    property bool showLegend: true
    property bool animated: true
    property color primaryColor: DesignSystem.colors.primary
    
    // ==================== 基础样式 ====================
    
    color: ThemeManager.colors.surface
    radius: DesignSystem.radius.lg
    border.width: 1
    border.color: ThemeManager.colors.outline

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacing.md
        spacing: DesignSystem.spacing.md

        // 图表标题
        Label {
            text: "标签使用统计"
            font.pixelSize: DesignSystem.typography.headline.small
            font.weight: DesignSystem.typography.weight.semiBold
            color: ThemeManager.colors.onSurface
            Layout.alignment: Qt.AlignHCenter
        }

        // 图表类型切换
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: DesignSystem.spacing.sm

            Repeater {
                model: [
                    {type: "bar", icon: "📊", name: "柱状图"},
                    {type: "pie", icon: "🥧", name: "饼图"},
                    {type: "line", icon: "📈", name: "折线图"}
                ]

                EnhancedButton {
                    text: modelData.icon
                    variant: root.chartType === modelData.type ? 
                            EnhancedButton.ButtonVariant.Filled : 
                            EnhancedButton.ButtonVariant.Outlined
                    implicitWidth: 40
                    implicitHeight: 40
                    ToolTip.text: modelData.name
                    
                    onClicked: {
                        root.chartType = modelData.type
                        chartCanvas.requestPaint()
                    }
                }
            }
        }

        // 图表区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            
            Canvas {
                id: chartCanvas
                anchors.fill: parent
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    
                    if (root.tagList.length === 0) {
                        drawEmptyState(ctx)
                        return
                    }
                    
                    switch (root.chartType) {
                        case "bar":
                            drawBarChart(ctx)
                            break
                        case "pie":
                            drawPieChart(ctx)
                            break
                        case "line":
                            drawLineChart(ctx)
                            break
                    }
                }
                
                // 柱状图绘制
                function drawBarChart(ctx) {
                    var margin = 40
                    var chartWidth = width - margin * 2
                    var chartHeight = height - margin * 2
                    
                    var maxUsage = Math.max(...root.tagList.map(tag => tag.usage_count || 0))
                    if (maxUsage === 0) maxUsage = 1
                    
                    var barWidth = chartWidth / root.tagList.length * 0.8
                    var barSpacing = chartWidth / root.tagList.length * 0.2
                    
                    ctx.fillStyle = ThemeManager.colors.onSurfaceVariant
                    ctx.font = "12px " + DesignSystem.typography.fontFamily
                    
                    for (var i = 0; i < root.tagList.length; i++) {
                        var tag = root.tagList[i]
                        var usage = tag.usage_count || 0
                        var barHeight = (usage / maxUsage) * chartHeight
                        
                        var x = margin + i * (barWidth + barSpacing)
                        var y = margin + chartHeight - barHeight
                        
                        // 绘制柱子
                        ctx.fillStyle = tag.color || root.primaryColor
                        ctx.fillRect(x, y, barWidth, barHeight)
                        
                        // 绘制标签名称
                        ctx.fillStyle = ThemeManager.colors.onSurfaceVariant
                        ctx.textAlign = "center"
                        ctx.fillText(tag.name.substring(0, 8), x + barWidth/2, height - 10)
                        
                        // 绘制数值
                        ctx.fillText(usage.toString(), x + barWidth/2, y - 5)
                    }
                }
                
                // 饼图绘制
                function drawPieChart(ctx) {
                    var centerX = width / 2
                    var centerY = height / 2
                    var radius = Math.min(width, height) / 2 - 40
                    
                    var totalUsage = root.tagList.reduce((sum, tag) => sum + (tag.usage_count || 0), 0)
                    if (totalUsage === 0) totalUsage = 1
                    
                    var currentAngle = -Math.PI / 2
                    
                    for (var i = 0; i < root.tagList.length; i++) {
                        var tag = root.tagList[i]
                        var usage = tag.usage_count || 0
                        var sliceAngle = (usage / totalUsage) * 2 * Math.PI
                        
                        // 绘制扇形
                        ctx.beginPath()
                        ctx.moveTo(centerX, centerY)
                        ctx.arc(centerX, centerY, radius, currentAngle, currentAngle + sliceAngle)
                        ctx.closePath()
                        ctx.fillStyle = tag.color || root.primaryColor
                        ctx.fill()
                        
                        // 绘制边框
                        ctx.strokeStyle = ThemeManager.colors.surface
                        ctx.lineWidth = 2
                        ctx.stroke()
                        
                        currentAngle += sliceAngle
                    }
                }
                
                // 折线图绘制
                function drawLineChart(ctx) {
                    var margin = 40
                    var chartWidth = width - margin * 2
                    var chartHeight = height - margin * 2
                    
                    if (root.tagList.length < 2) return
                    
                    var maxUsage = Math.max(...root.tagList.map(tag => tag.usage_count || 0))
                    if (maxUsage === 0) maxUsage = 1
                    
                    var stepX = chartWidth / (root.tagList.length - 1)
                    
                    // 绘制网格线
                    ctx.strokeStyle = ThemeManager.colors.outlineVariant
                    ctx.lineWidth = 1
                    for (var i = 0; i <= 5; i++) {
                        var y = margin + (chartHeight / 5) * i
                        ctx.beginPath()
                        ctx.moveTo(margin, y)
                        ctx.lineTo(margin + chartWidth, y)
                        ctx.stroke()
                    }
                    
                    // 绘制折线
                    ctx.strokeStyle = root.primaryColor
                    ctx.lineWidth = 3
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    
                    ctx.beginPath()
                    for (var i = 0; i < root.tagList.length; i++) {
                        var tag = root.tagList[i]
                        var usage = tag.usage_count || 0
                        var x = margin + i * stepX
                        var y = margin + chartHeight - (usage / maxUsage) * chartHeight
                        
                        if (i === 0) {
                            ctx.moveTo(x, y)
                        } else {
                            ctx.lineTo(x, y)
                        }
                    }
                    ctx.stroke()
                    
                    // 绘制数据点
                    ctx.fillStyle = root.primaryColor
                    for (var i = 0; i < root.tagList.length; i++) {
                        var tag = root.tagList[i]
                        var usage = tag.usage_count || 0
                        var x = margin + i * stepX
                        var y = margin + chartHeight - (usage / maxUsage) * chartHeight
                        
                        ctx.beginPath()
                        ctx.arc(x, y, 4, 0, 2 * Math.PI)
                        ctx.fill()
                    }
                }
                
                // 空状态绘制
                function drawEmptyState(ctx) {
                    ctx.fillStyle = ThemeManager.colors.onSurfaceVariant
                    ctx.font = "16px " + DesignSystem.typography.fontFamily
                    ctx.textAlign = "center"
                    ctx.fillText("暂无数据", width / 2, height / 2)
                }
            }
            
            // 图表交互
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                
                property point hoveredPoint: Qt.point(-1, -1)
                
                onPositionChanged: function(mouse) {
                    hoveredPoint = Qt.point(mouse.x, mouse.y)
                    // 这里可以添加悬停提示逻辑
                }
                
                onClicked: function(mouse) {
                    // 这里可以添加点击交互逻辑
                    console.log("图表点击:", mouse.x, mouse.y)
                }
            }
        }

        // 图例
        Flow {
            Layout.fillWidth: true
            spacing: DesignSystem.spacing.md
            visible: root.showLegend && root.tagList.length > 0
            
            Repeater {
                model: root.tagList
                
                Row {
                    spacing: DesignSystem.spacing.xs
                    
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: modelData.color || root.primaryColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Label {
                        text: modelData.name + " (" + (modelData.usage_count || 0) + ")"
                        font.pixelSize: DesignSystem.typography.label.small
                        color: ThemeManager.colors.onSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // ==================== 动画效果 ====================
    
    PropertyAnimation {
        id: chartAnimation
        target: chartCanvas
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: DesignSystem.animation.duration.normal
        easing.type: DesignSystem.animation.easing.standard
    }

    // ==================== 数据更新 ====================
    
    onTagListChanged: {
        if (animated) {
            chartAnimation.start()
        }
        chartCanvas.requestPaint()
    }
    
    onChartTypeChanged: {
        if (animated) {
            chartAnimation.start()
        }
    }

    // ==================== 公共方法 ====================
    
    function refreshChart() {
        chartCanvas.requestPaint()
    }
    
    function exportChart() {
        // 导出图表为图片
        chartCanvas.save("tag_statistics_chart.png")
    }
}
