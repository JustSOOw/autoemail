import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import EmailManager 1.0
import "pages"
import "components"

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    minimumWidth: 1024
    minimumHeight: 768
    visible: true
    title: appName || "域名邮箱管理器"

    // Material Design主题
    Material.theme: Material.Light
    Material.primary: Material.Blue
    Material.accent: Material.Cyan

    // 响应式布局检测
    readonly property string screenSize: {
        if (width < 480) return "xs"
        if (width < 768) return "sm"
        if (width < 1024) return "md"
        if (width < 1440) return "lg"
        return "xl"
    }

    readonly property bool isMobile: screenSize === "xs" || screenSize === "sm"
    readonly property bool isTablet: screenSize === "md"
    readonly property bool isDesktop: screenSize === "lg" || screenSize === "xl"

    // 键盘快捷键支持
    Item {
        anchors.fill: parent
        focus: true
        z: -1

        Keys.onPressed: function(event) {
        // Ctrl+数字键切换页面
        if (event.modifiers & Qt.ControlModifier) {
            switch (event.key) {
                case Qt.Key_1:
                    tabBar.currentIndex = 0
                    event.accepted = true
                    break
                case Qt.Key_2:
                    tabBar.currentIndex = 1
                    event.accepted = true
                    break
                case Qt.Key_3:
                    tabBar.currentIndex = 2
                    event.accepted = true
                    break
                case Qt.Key_4:
                    tabBar.currentIndex = 3
                    event.accepted = true
                    break
                case Qt.Key_R:
                    // Ctrl+R 刷新当前页面
                    refreshCurrentPage()
                    event.accepted = true
                    break
                case Qt.Key_N:
                    // Ctrl+N 生成新邮箱
                    if (tabBar.currentIndex === 0 && window.isConfigured) {
                        emailGenerationPage.generateButton.clicked()
                    }
                    event.accepted = true
                    break
                case Qt.Key_D:
                    // Ctrl+D 显示/隐藏调试面板
                    debugPanel.toggle()
                    event.accepted = true
                    break
                case Qt.Key_P:
                    // Ctrl+P: 显示/隐藏性能监控
                    performanceMonitor.showOverlay = !performanceMonitor.showOverlay
                    if (performanceMonitor.showOverlay) {
                        performanceMonitor.enabled = true
                    }
                    event.accepted = true
                    break
                case Qt.Key_T:
                    // Ctrl+T: 显示/隐藏测试面板
                    uxTestSuite.testingEnabled = !uxTestSuite.testingEnabled
                    event.accepted = true
                    break
            }
        }

        // F5 刷新
        if (event.key === Qt.Key_F5) {
            refreshCurrentPage()
            event.accepted = true
        }

        // Escape 清除选择或关闭对话框
        if (event.key === Qt.Key_Escape) {
            if (tabBar.currentIndex === 1) {
                emailManagementPage.clearSelection()
            }
            event.accepted = true
        }
    }
    }

    // 应用程序状态
    property bool isConfigured: configController ? configController.isConfigured() : false
    property string currentDomain: emailController ? emailController.getCurrentDomain() : "未配置"
    property var statistics: emailController ? emailController.getStatistics() : ({})

    // 全局状态管理
    property var globalState: ({
        emailList: [],
        tagList: [],
        currentPage: 1,
        totalPages: 1,
        isLoading: false
    })

    // 初始化
    Component.onCompleted: {
        console.log("应用程序启动完成")
        console.log("快捷键:")
        console.log("  Ctrl+1-4: 切换页面")
        console.log("  Ctrl+N: 生成新邮箱")
        console.log("  Ctrl+R: 刷新页面")
        console.log("  Ctrl+D: 调试面板")
        console.log("  Ctrl+P: 性能监控")
        console.log("  Ctrl+T: UX测试")
        console.log("  F5: 刷新页面")

        // 初始化全局状态
        initializeGlobalState()

        // 延迟初始化，确保所有组件都已加载
        Qt.callLater(function() {
            console.log("开始延迟初始化...")

            if (configController) {
                console.log("加载配置...")
                configController.loadConfig()
            }

            // 再次延迟加载邮箱列表，确保配置已加载
            Qt.callLater(function() {
                if (emailController) {
                    console.log("刷新邮箱列表...")
                    emailController.refreshEmailList()
                }

                // 刷新标签列表
                refreshTagList()

                console.log("初始化完成")
            })
        })

        // 应用性能优化
        if (typeof PerformanceOptimizer !== 'undefined') {
            PerformanceOptimizer.autoOptimize(window)
        }
    }

    // 页面切换处理
    function handlePageSwitch(pageIndex) {
        switch (pageIndex) {
            case 0: // 邮箱生成页面
                mainLogArea.addLog("📄 切换到邮箱生成页面")
                // 刷新统计信息
                if (emailController) {
                    window.statistics = emailController.getStatistics()
                }
                break

            case 1: // 邮箱管理页面
                mainLogArea.addLog("📄 切换到邮箱管理页面")
                // 刷新邮箱列表
                if (emailController) {
                    emailController.refreshEmailList()
                }
                break

            case 2: // 标签管理页面
                mainLogArea.addLog("📄 切换到标签管理页面")
                // 刷新标签列表
                refreshTagList()
                break

            case 3: // 配置管理页面
                mainLogArea.addLog("📄 切换到配置管理页面")
                // 加载最新配置
                if (configController) {
                    configController.loadConfig()
                }
                break
        }
    }

    // 初始化全局状态
    function initializeGlobalState() {
        window.globalState = {
            emailList: [],
            tagList: [],
            currentPage: 1,
            totalPages: 1,
            isLoading: false,
            selectedEmails: [],
            lastRefreshTime: new Date()
        }
    }

    // 刷新标签列表
    function refreshTagList() {
        console.log("刷新标签列表")

        if (typeof tagController !== 'undefined') {
            // 调用后端API获取标签列表
            var result = tagController.getAllTags()
            var resultData = JSON.parse(result)

            if (resultData.success) {
                window.globalState.tagList = resultData.tags
                console.log("成功获取标签列表，数量:", resultData.count)
            } else {
                console.error("获取标签列表失败:", resultData.message)
                // 使用空列表作为后备
                window.globalState.tagList = []
            }
        } else {
            console.log("tagController不可用，使用模拟数据")
            // 后备模拟数据
            window.globalState.tagList = [
                {id: 1, name: "工作", description: "工作相关邮箱", color: "#2196F3", icon: "💼", usage_count: 5},
                {id: 2, name: "个人", description: "个人使用邮箱", color: "#4CAF50", icon: "👤", usage_count: 3},
                {id: 3, name: "测试", description: "测试用途邮箱", color: "#FF9800", icon: "🧪", usage_count: 2}
            ]
        }

        // 更新标签管理页面的数据
        if (tagManagementPage) {
            console.log("更新标签管理页面数据，标签数量:", window.globalState.tagList.length)
            tagManagementPage.tagList = window.globalState.tagList
            tagManagementPage.isLoading = false  // 重置加载状态
        }
    }

    // 刷新当前页面
    function refreshCurrentPage() {
        switch (tabBar.currentIndex) {
            case 0: // 邮箱生成页面
                if (emailController) {
                    window.statistics = emailController.getStatistics()
                }
                globalStatusMessage.showInfo("邮箱生成页面已刷新")
                break

            case 1: // 邮箱管理页面
                if (emailController) {
                    emailController.refreshEmailList()
                }
                emailManagementPage.clearSelection()
                globalStatusMessage.showInfo("邮箱列表已刷新")
                break

            case 2: // 标签管理页面
                refreshTagList()
                globalStatusMessage.showInfo("标签列表已刷新")
                break

            case 3: // 配置管理页面
                if (configController) {
                    configController.loadConfig()
                }
                globalStatusMessage.showInfo("配置已重新加载")
                break
        }
    }

    // 导航到指定页面
    function navigateToPage(pageIndex, showMessage) {
        if (pageIndex >= 0 && pageIndex < 4) {
            tabBar.currentIndex = pageIndex
            if (showMessage) {
                var pageNames = ["邮箱生成", "邮箱管理", "标签管理", "配置管理"]
                globalStatusMessage.showInfo("已切换到" + pageNames[pageIndex] + "页面")
            }
        }
    }

    // 检查页面访问权限
    function checkPageAccess(pageIndex) {
        // 邮箱生成和管理页面需要配置完成
        if ((pageIndex === 0 || pageIndex === 1) && !window.isConfigured) {
            globalStatusMessage.showWarning("请先完成域名配置")
            navigateToPage(3, false) // 跳转到配置页面
            return false
        }
        return true
    }

    // 错误处理
    function handleError(errorType, errorMessage, context) {
        console.error("错误类型:", errorType, "错误信息:", errorMessage, "上下文:", context)

        // 记录错误日志
        mainLogArea.addLog("❌ 错误: " + errorType + " - " + errorMessage)

        // 显示用户友好的错误消息
        var userMessage = getUserFriendlyErrorMessage(errorType, errorMessage)
        globalStatusMessage.showError(userMessage)

        // 根据错误类型执行相应的恢复操作
        performErrorRecovery(errorType, context)
    }

    // 获取用户友好的错误消息
    function getUserFriendlyErrorMessage(errorType, errorMessage) {
        var errorMap = {
            "网络错误": "网络连接失败，请检查网络设置",
            "配置错误": "配置信息有误，请检查配置设置",
            "验证失败": "验证失败，请重试",
            "权限错误": "权限不足，请检查权限设置",
            "数据错误": "数据处理失败，请重试"
        }

        return errorMap[errorType] || errorMessage || "发生未知错误"
    }

    // 执行错误恢复
    function performErrorRecovery(errorType, context) {
        switch (errorType) {
            case "配置错误":
                // 跳转到配置页面
                navigateToPage(3, false)
                break

            case "网络错误":
                // 重试网络操作
                Qt.callLater(function() {
                    if (context && context.retryFunction) {
                        context.retryFunction()
                    }
                })
                break

            case "数据错误":
                // 刷新数据
                refreshCurrentPage()
                break
        }
    }

    // 性能监控
    property var performanceMetrics: ({
        pageLoadTimes: {},
        apiCallTimes: {},
        renderTimes: {}
    })

    function recordPerformanceMetric(category, operation, startTime) {
        var endTime = Date.now()
        var duration = endTime - startTime

        if (!performanceMetrics[category]) {
            performanceMetrics[category] = {}
        }

        performanceMetrics[category][operation] = duration

        // 记录性能日志
        if (duration > 1000) { // 超过1秒的操作
            console.warn("性能警告:", category, operation, "耗时", duration, "ms")
        }
    }

    // 内存清理
    function performMemoryCleanup() {
        // 清理过期的日志
        if (mainLogArea.text.length > 10000) {
            var lines = mainLogArea.text.split('\n')
            mainLogArea.text = lines.slice(-100).join('\n')
        }

        // 清理过期的性能指标
        var now = Date.now()
        for (var category in performanceMetrics) {
            for (var operation in performanceMetrics[category]) {
                if (now - performanceMetrics[category][operation].timestamp > 300000) { // 5分钟
                    delete performanceMetrics[category][operation]
                }
            }
        }

        // 触发垃圾回收
        gc()
    }

    // 定期内存清理
    Timer {
        interval: 60000 // 1分钟
        running: true
        repeat: true
        onTriggered: performMemoryCleanup()
    }
    
    // 移动设备抽屉导航
    Drawer {
        id: mobileDrawer
        width: Math.min(window.width * 0.8, 300)
        height: window.height
        visible: window.isMobile

        background: Rectangle {
            color: ThemeManager.colors.surface
            border.width: 1
            border.color: ThemeManager.colors.outline
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacing.md
            spacing: DesignSystem.spacing.md

            // 抽屉标题
            Label {
                text: "邮箱管理系统"
                font.pixelSize: DesignSystem.typography.headline.small
                font.weight: DesignSystem.typography.weight.semiBold
                color: ThemeManager.colors.textOnSurface
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: ThemeManager.colors.outline
            }

            // 导航项目
            Repeater {
                model: [
                    {text: "邮箱生成", icon: "📧", index: 0},
                    {text: "邮箱管理", icon: "📋", index: 1},
                    {text: "标签管理", icon: "🏷️", index: 2},
                    {text: "配置管理", icon: "⚙️", index: 3}
                ]

                ItemDelegate {
                    Layout.fillWidth: true
                    height: 48

                    background: Rectangle {
                        color: tabBar.currentIndex === modelData.index ?
                               Qt.rgba(DesignSystem.colors.primary.r,
                                      DesignSystem.colors.primary.g,
                                      DesignSystem.colors.primary.b, 0.1) :
                               "transparent"
                        radius: DesignSystem.radius.sm
                    }

                    contentItem: RowLayout {
                        spacing: DesignSystem.spacing.md

                        Label {
                            text: modelData.icon
                            font.pixelSize: DesignSystem.icons.size.medium
                        }

                        Label {
                            text: modelData.text
                            font.pixelSize: DesignSystem.typography.body.medium
                            color: tabBar.currentIndex === modelData.index ?
                                   DesignSystem.colors.primary :
                                   ThemeManager.colors.textOnSurface
                            Layout.fillWidth: true
                        }
                    }

                    onClicked: {
                        tabBar.currentIndex = modelData.index
                        mobileDrawer.close()
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // 主布局
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // 顶部工具栏
        AppToolBar {
            id: appToolBar
            Layout.fillWidth: true
            title: window.title
            isConfigured: window.isConfigured
            currentDomain: window.currentDomain

            // 移动设备支持
            showMenuButton: window.isMobile

            onMenuClicked: {
                mobileDrawer.open()
            }

            onConfigStatusClicked: {
                // 切换到配置页面
                tabBar.currentIndex = 3
                globalStatusMessage.showInfo("请完成配置设置")
            }
        }

        // 标签栏
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Material.background: "#FAFAFA"

            // 响应式布局调整
            visible: !window.isMobile || !mobileDrawer.opened

            // 移动设备上的标签样式调整
            property real tabWidth: window.isMobile ? Math.max(80, width / 4) : implicitWidth

            // 页面切换动画
            property int previousIndex: 0

            onCurrentIndexChanged: {
                // 记录上一个页面索引用于动画
                if (currentIndex !== previousIndex) {
                    stackLayout.switchPage(previousIndex, currentIndex)
                    previousIndex = currentIndex
                }

                // 页面切换时的逻辑处理
                handlePageSwitch(currentIndex)
            }

            TabButton {
                text: "🏠 邮箱生成"
                font.pixelSize: 14
                width: implicitWidth

                // 未配置时的提示
                ToolTip.visible: !window.isConfigured && hovered
                ToolTip.text: "请先完成域名配置"
            }
            TabButton {
                text: "📋 邮箱管理"
                font.pixelSize: 14
                width: implicitWidth

                // 显示邮箱数量
                Rectangle {
                    visible: window.globalState.emailList.length > 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5
                    width: 20
                    height: 20
                    radius: 10
                    color: Material.Red

                    Label {
                        anchors.centerIn: parent
                        text: window.globalState.emailList.length > 99 ? "99+" : window.globalState.emailList.length.toString()
                        font.pixelSize: 10
                        color: "white"
                    }
                }
            }
            TabButton {
                text: "🏷️ 标签管理"
                font.pixelSize: 14
                width: implicitWidth

                // 显示标签数量
                Rectangle {
                    visible: window.globalState.tagList.length > 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5
                    width: 20
                    height: 20
                    radius: 10
                    color: Material.Green

                    Label {
                        anchors.centerIn: parent
                        text: window.globalState.tagList.length.toString()
                        font.pixelSize: 10
                        color: "white"
                    }
                }
            }
            TabButton {
                text: "⚙️ 配置管理"
                font.pixelSize: 14
                width: implicitWidth

                // 配置状态指示
                Rectangle {
                    id: configIndicator
                    visible: !window.isConfigured
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5
                    width: 8
                    height: 8
                    radius: 4
                    color: Material.Red

                    // 闪烁动画
                    SequentialAnimation {
                        running: !window.isConfigured
                        loops: Animation.Infinite

                        NumberAnimation {
                            target: configIndicator
                            property: "opacity"
                            from: 1.0
                            to: 0.3
                            duration: 800
                        }

                        NumberAnimation {
                            target: configIndicator
                            property: "opacity"
                            from: 0.3
                            to: 1.0
                            duration: 800
                        }
                    }
                }
            }
        }
        
        // 页面内容
        StackLayout {
            id: stackLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // 页面切换动画
            property bool animationEnabled: true
            property int animationDuration: 300

            function switchPage(fromIndex, toIndex) {
                if (!animationEnabled) return

                // 这里可以添加页面切换的动画效果
                // 由于StackLayout的限制，我们使用透明度动画
                var currentItem = itemAt(fromIndex)
                var nextItem = itemAt(toIndex)

                if (currentItem && nextItem) {
                    // 淡出当前页面
                    fadeOutAnimation.target = currentItem
                    fadeOutAnimation.start()

                    // 延迟淡入下一个页面
                    Qt.callLater(function() {
                        fadeInAnimation.target = nextItem
                        fadeInAnimation.start()
                    })
                }
            }

            // 淡出动画
            NumberAnimation {
                id: fadeOutAnimation
                property: "opacity"
                from: 1.0
                to: 0.7
                duration: stackLayout.animationDuration / 2
                easing.type: Easing.OutQuad

                onFinished: {
                    target.opacity = 1.0
                }
            }

            // 淡入动画
            NumberAnimation {
                id: fadeInAnimation
                property: "opacity"
                from: 0.7
                to: 1.0
                duration: stackLayout.animationDuration / 2
                easing.type: Easing.InQuad
            }

            // 邮箱生成页面
            EmailGenerationPage {
                id: emailGenerationPage
                isConfigured: window.isConfigured
                currentDomain: window.currentDomain
                statistics: window.statistics

                onStatusChanged: function(message) {
                    statusLabel.text = message
                    mainLogArea.addLog("ℹ️ " + message)
                }

                onLogMessage: function(message) {
                    mainLogArea.addLog(message)
                }
            }

            // 邮箱管理页面
            EmailManagementPage {
                id: emailManagementPage
                emailList: window.globalState.emailList
                tagList: window.globalState.tagList
                currentPage: window.globalState.currentPage
                totalPages: window.globalState.totalPages
                isLoading: window.globalState.isLoading

                onSearchEmails: function(keyword, status, tags, page) {
                    // 调用后端搜索接口
                    if (emailController) {
                        // 这里需要实现搜索逻辑
                        console.log("搜索邮箱:", keyword, status, tags, page)
                    }
                }

                onDeleteEmail: function(emailId) {
                    // 调用后端删除接口
                    if (emailController) {
                        // 这里需要实现删除逻辑
                        console.log("删除邮箱:", emailId)
                    }
                }

                onEditEmail: function(emailId, emailData) {
                    // 调用后端编辑接口
                    if (emailController) {
                        // 这里需要实现编辑逻辑
                        console.log("编辑邮箱:", emailId, emailData)
                    }
                }

                onImportEmails: function(filePath, format, conflictStrategy) {
                    // 调用后端导入接口
                    if (emailController) {
                        console.log("导入邮箱:", filePath, format, conflictStrategy)
                        emailController.importEmails(filePath, format, conflictStrategy)
                    }
                }

                onRequestFileSelection: function() {
                    // 请求文件选择
                    if (emailController) {
                        console.log("请求文件选择")
                        emailController.selectImportFile()
                    }
                }

                onRefreshRequested: function() {
                    // 刷新邮箱列表
                    if (emailController) {
                        emailController.refreshEmailList()
                    }
                }
            }

            // 标签管理页面
            TagManagementPage {
                id: tagManagementPage
                tagList: window.globalState.tagList
                isLoading: window.globalState.isLoading

                onCreateTag: function(tagData) {
                    // 调用后端创建标签接口
                    console.log("创建标签:", JSON.stringify(tagData))
                    globalStatusMessage.showInfo("正在创建标签: " + tagData.name)

                    if (typeof tagController !== 'undefined') {
                        // 调用真正的后端API
                        var result = tagController.createTag(JSON.stringify(tagData))
                        var resultData = JSON.parse(result)

                        if (resultData.success) {
                            // 创建成功，刷新标签列表
                            refreshTagList()
                            globalStatusMessage.showSuccess(resultData.message)
                            console.log("标签创建成功:", resultData.tag.name)
                        } else {
                            // 创建失败，显示错误信息
                            globalStatusMessage.showError(resultData.message)
                            console.error("标签创建失败:", resultData.message)
                        }
                    } else {
                        // 后备模拟逻辑
                        console.log("tagController不可用，使用模拟创建")
                        Qt.callLater(function() {
                            try {
                                // 生成新的标签ID
                                var newId = Math.max(...window.globalState.tagList.map(tag => tag.id || 0)) + 1

                                // 创建新标签对象
                                var newTag = {
                                    id: newId,
                                    name: tagData.name,
                                    description: tagData.description || "",
                                    color: tagData.color || "#2196F3",
                                    icon: tagData.icon || "🏷️",
                                    usage_count: 0,
                                    created_at: new Date().toISOString()
                                }

                                // 添加到标签列表
                                window.globalState.tagList.push(newTag)

                                // 更新标签管理页面
                                if (tagManagementPage) {
                                    tagManagementPage.tagList = window.globalState.tagList
                                }

                                globalStatusMessage.showSuccess("标签 '" + tagData.name + "' 创建成功！")
                                console.log("标签创建成功，当前标签数量:", window.globalState.tagList.length)

                            } catch (e) {
                                console.error("创建标签失败:", e)
                                globalStatusMessage.showError("创建标签失败: " + e.message)
                            }
                        })
                    }
                }

                onUpdateTag: function(tagId, tagData) {
                    // 调用后端更新标签接口
                    console.log("更新标签:", tagId, JSON.stringify(tagData))
                    globalStatusMessage.showInfo("正在更新标签...")

                    if (typeof tagController !== 'undefined') {
                        var result = tagController.updateTag(tagId, JSON.stringify(tagData))
                        var resultData = JSON.parse(result)

                        if (resultData.success) {
                            refreshTagList()
                            globalStatusMessage.showSuccess(resultData.message)
                        } else {
                            globalStatusMessage.showError(resultData.message)
                        }
                    }
                }

                onDeleteTag: function(tagId) {
                    // 调用后端删除标签接口
                    console.log("删除标签:", tagId)
                    globalStatusMessage.showInfo("正在删除标签...")

                    if (typeof tagController !== 'undefined') {
                        var result = tagController.deleteTag(tagId)
                        var resultData = JSON.parse(result)

                        if (resultData.success) {
                            refreshTagList()
                            globalStatusMessage.showSuccess(resultData.message)
                        } else {
                            globalStatusMessage.showError(resultData.message)
                        }
                    }
                }

                onSearchTags: function(keyword) {
                    // 调用后端搜索标签接口
                    console.log("搜索标签:", keyword)

                    if (typeof tagController !== 'undefined') {
                        var result = tagController.searchTags(keyword)
                        var resultData = JSON.parse(result)

                        if (resultData.success) {
                            // 更新搜索结果
                            if (tagManagementPage) {
                                tagManagementPage.searchResults = resultData.tags
                                tagManagementPage.lastSearchQuery = keyword
                            }
                        }
                    }
                }

                onRefreshRequested: function() {
                    // 刷新标签列表
                    console.log("刷新标签列表")
                    globalStatusMessage.showInfo("正在刷新标签列表...")
                    refreshTagList()
                }
            }

            // 配置管理页面
            ConfigurationPage {
                id: configurationPage
                isConfigured: window.isConfigured
                currentDomain: window.currentDomain
                configData: ({}) // 这里需要从控制器获取配置数据

                onValidateDomain: function(domain) {
                    if (configController) {
                        configController.validateDomain(domain)
                    }
                }

                onSaveDomain: function(domain) {
                    if (configController) {
                        configController.setDomain(domain)
                        // 保存后更新配置状态
                        Qt.callLater(function() {
                            window.isConfigured = configController.isConfigured()
                            window.currentDomain = configController.getCurrentDomain()
                        })
                    }
                }

                onSaveConfig: function(config) {
                    if (configController) {
                        configController.saveConfig(config)
                    }
                }

                onResetConfig: function() {
                    if (configController) {
                        configController.resetConfig()
                    }
                }

                onExportConfig: function() {
                    if (configController) {
                        // 这里需要实现导出配置逻辑
                        console.log("导出配置")
                    }
                }

                onImportConfig: function(configJson) {
                    if (configController) {
                        // 这里需要实现导入配置逻辑
                        console.log("导入配置:", configJson)
                    }
                }
            }
        }

        // 全局状态消息
        StatusMessage {
            id: globalStatusMessage
            Layout.fillWidth: true
            Layout.margins: 20
        }
    }

    // 全局日志区域（隐藏，用于调试）
    TextArea {
        id: mainLogArea
        visible: false

        function addLog(message) {
            var timestamp = new Date().toLocaleTimeString()
            text += "\n[" + timestamp + "] " + message
        }
    }

    // 状态栏
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 32
        color: "#f8f9fa"
        border.color: "#e9ecef"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 15

            Label {
                id: statusLabel
                text: "就绪"
                font.pixelSize: 12
                color: "#333"
            }

            Rectangle {
                width: 1
                height: 16
                color: "#dee2e6"
            }

            Label {
                text: "域名: " + window.currentDomain
                font.pixelSize: 12
                color: "#666"
            }

            Rectangle {
                width: 1
                height: 16
                color: "#dee2e6"
            }

            Label {
                text: "邮箱总数: " + (window.statistics.total_emails || 0)
                font.pixelSize: 12
                color: "#666"
            }

            Item { Layout.fillWidth: true }

            Label {
                id: timeLabel
                text: new Date().toLocaleTimeString()
                font.pixelSize: 12
                color: "#666"

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: timeLabel.text = new Date().toLocaleTimeString()
                }
            }
        }
    }

    // 调试面板
    DebugPanel {
        id: debugPanel
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        z: 1000

        globalState: window.globalState
        statistics: window.statistics
        isConfigured: window.isConfigured
        currentDomain: window.currentDomain
    }

    // 连接邮箱控制器信号
    Connections {
        target: emailController

        function onEmailGenerated(email, status, message) {
            if (status === "success") {
                emailGenerationPage.updateLatestEmail(email)
                emailGenerationPage.addLogMessage("✅ " + message)
                globalStatusMessage.showSuccess("邮箱生成成功: " + email)
                // 更新统计信息
                window.statistics = emailController.getStatistics()
            } else {
                emailGenerationPage.addLogMessage("❌ " + message)
                globalStatusMessage.showError("邮箱生成失败: " + message)
            }
            emailGenerationPage.enableGenerateButton()
        }

        function onStatusChanged(message) {
            statusLabel.text = message
            mainLogArea.addLog("ℹ️ " + message)
            emailGenerationPage.addLogMessage("ℹ️ " + message)
        }

        function onProgressChanged(value) {
            emailGenerationPage.updateProgress(value)
        }

        function onVerificationCodeReceived(email, code) {
            var message = "📧 验证码 (" + email + "): " + code
            mainLogArea.addLog(message)
            emailGenerationPage.addLogMessage(message)
            globalStatusMessage.showInfo("验证码已接收")
        }

        function onErrorOccurred(errorType, errorMessage) {
            var message = "❌ " + errorType + ": " + errorMessage
            mainLogArea.addLog(message)
            emailGenerationPage.addLogMessage(message)
            globalStatusMessage.showError(errorType + ": " + errorMessage)
        }

        function onStatisticsUpdated(stats) {
            window.statistics = stats
        }

        function onEmailListUpdated(emailList) {
            console.log("收到邮箱列表更新信号，邮箱数量:", emailList.length)
            window.globalState.emailList = emailList
            window.globalState.lastRefreshTime = new Date()
            mainLogArea.addLog("📧 邮箱列表已更新，共 " + emailList.length + " 个邮箱")

            // 强制更新邮箱管理页面
            if (emailManagementPage) {
                emailManagementPage.emailList = emailList
                emailManagementPage.totalEmails = emailList.length
                emailManagementPage.isLoading = false  // 重置加载状态
                console.log("邮箱管理页面数据已更新，加载状态已重置")
            }
        }

        function onFileSelected(filePath) {
            console.log("用户选择了文件:", filePath)
            // 将选中的文件路径传递给导入对话框
            if (emailManagementPage && emailManagementPage.emailImportDialog) {
                emailManagementPage.emailImportDialog.selectedFilePath = filePath
            }
            mainLogArea.addLog("📁 选择了导入文件: " + filePath)
        }

        function onImportCompleted(result) {
            console.log("导入完成:", result)
            var message = "导入完成: 成功 " + result.success + ", 失败 " + result.failed + ", 跳过 " + result.skipped
            mainLogArea.addLog("📥 " + message)
            globalStatusMessage.showSuccess(message)
        }

        function onImportFailed(errorType, errorMessage) {
            console.log("导入失败:", errorType, errorMessage)
            var message = "导入失败: " + errorMessage
            mainLogArea.addLog("❌ " + message)
            globalStatusMessage.showError(message)
        }
    }

    // 连接配置控制器信号
    Connections {
        target: configController

        function onConfigLoaded(configData) {
            window.currentDomain = configData.domain || "未配置"
            window.isConfigured = configData.is_configured || false
            mainLogArea.addLog("⚙️ 配置加载完成")
            configurationPage.loadConfigData(configData)
            globalStatusMessage.showInfo("配置加载完成")
        }

        function onConfigSaved(success, message) {
            if (success) {
                mainLogArea.addLog("✅ " + message)
                globalStatusMessage.showSuccess(message)
                // 重新加载配置状态
                window.currentDomain = configController.getCurrentDomain()
                window.isConfigured = configController.isConfigured()
            } else {
                mainLogArea.addLog("❌ " + message)
                globalStatusMessage.showError(message)
            }
        }

        function onDomainValidated(isValid, message) {
            configurationPage.updateDomainStatus(isValid, message)
            mainLogArea.addLog((isValid ? "✅ " : "❌ ") + "域名验证: " + message)
            if (isValid) {
                globalStatusMessage.showSuccess("域名验证: " + message)
            } else {
                globalStatusMessage.showError("域名验证: " + message)
            }
        }

        function onStatusChanged(message) {
            statusLabel.text = message
        }

        function onErrorOccurred(errorType, errorMessage) {
            mainLogArea.addLog("❌ " + errorType + ": " + errorMessage)
            globalStatusMessage.showError(errorType + ": " + errorMessage)
        }
    }

    // 连接标签控制器信号
    Connections {
        target: tagController

        function onTagCreated(tagData) {
            console.log("标签创建信号:", JSON.stringify(tagData))
            mainLogArea.addLog("🏷️ 标签创建: " + tagData.name)
            // 自动刷新标签列表
            refreshTagList()
        }

        function onTagUpdated(tagData) {
            console.log("标签更新信号:", JSON.stringify(tagData))
            mainLogArea.addLog("🏷️ 标签更新: " + tagData.name)
            // 自动刷新标签列表
            refreshTagList()
        }

        function onTagDeleted(tagId) {
            console.log("标签删除信号:", tagId)
            mainLogArea.addLog("🏷️ 标签删除: ID " + tagId)
            // 自动刷新标签列表
            refreshTagList()
        }

        function onTagListRefreshed(tagList) {
            console.log("标签列表刷新信号，数量:", tagList.length)
            window.globalState.tagList = tagList
            if (tagManagementPage) {
                tagManagementPage.tagList = tagList
                tagManagementPage.isLoading = false
            }
        }

        function onErrorOccurred(errorMessage) {
            console.error("标签操作错误:", errorMessage)
            mainLogArea.addLog("❌ 标签操作错误: " + errorMessage)
            globalStatusMessage.showError(errorMessage)
        }

        function onOperationCompleted(operationType, success, message) {
            console.log("标签操作完成:", operationType, success, message)
            if (success) {
                mainLogArea.addLog("✅ " + message)
                globalStatusMessage.showSuccess(message)
            } else {
                mainLogArea.addLog("❌ " + message)
                globalStatusMessage.showError(message)
            }
        }
    }

    // ==================== 性能监控和测试工具 ====================

    // 性能监控器 (暂时禁用)
    // PerformanceMonitor {
    //     id: performanceMonitor
    //     anchors.fill: parent
    //     enabled: false
    //     showOverlay: false
    // }

    // UX测试套件 (暂时禁用)
    // UXTestSuite {
    //     id: uxTestSuite
    //     anchors.fill: parent
    //     testingEnabled: false

    //     onTestCompleted: function(testName, results) {
    //         if (!results.passed) {
    //             globalStatusMessage.showError("测试失败: " + testName)
    //         }
    //     }

    //     onAllTestsCompleted: function(summary) {
    //         globalStatusMessage.showSuccess(
    //             "测试完成: " + summary.passedTests + "/" + summary.totalTests +
    //             " 通过 (" + summary.successRate + ")"
    //         )
    //     }
    // }

    // ==================== 初始化和优化 ====================
}