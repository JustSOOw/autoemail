/*
 * 高亮文本组件
 * 支持搜索关键词高亮显示
 */

import QtQuick 2.15
import QtQuick.Controls 2.15

Text {
    id: root

    // ==================== 自定义属性 ====================
    
    property string originalText: ""
    property string searchQuery: ""
    property color highlightColor: DesignSystem.colors.warning
    property color highlightTextColor: ThemeManager.colors.onSurface
    property bool caseSensitive: false
    property bool wholeWords: false
    property real highlightOpacity: 0.3
    
    // ==================== 基础属性 ====================
    
    textFormat: Text.RichText
    wrapMode: Text.WordWrap
    
    // ==================== 文本处理 ====================
    
    text: processText()
    
    function processText() {
        if (!originalText || !searchQuery) {
            return originalText
        }
        
        var query = searchQuery.trim()
        if (query.length === 0) {
            return originalText
        }
        
        return highlightMatches(originalText, query)
    }
    
    function highlightMatches(text, query) {
        if (!text || !query) return text
        
        var flags = caseSensitive ? "g" : "gi"
        var pattern
        
        if (wholeWords) {
            // 匹配完整单词
            pattern = new RegExp("\\b" + escapeRegExp(query) + "\\b", flags)
        } else {
            // 匹配任何位置
            pattern = new RegExp(escapeRegExp(query), flags)
        }
        
        var highlightStyle = `background-color: ${Qt.rgba(highlightColor.r, highlightColor.g, highlightColor.b, highlightOpacity)}; color: ${highlightTextColor}; padding: 1px 2px; border-radius: 2px;`
        
        return text.replace(pattern, function(match) {
            return `<span style="${highlightStyle}">${match}</span>`
        })
    }
    
    function escapeRegExp(string) {
        return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    }
    
    // ==================== 属性监听 ====================
    
    onOriginalTextChanged: text = processText()
    onSearchQueryChanged: text = processText()
    onCaseSensitiveChanged: text = processText()
    onWholeWordsChanged: text = processText()
    
    // ==================== 动画效果 ====================
    
    // 高亮出现动画
    SequentialAnimation {
        id: highlightAnimation
        running: searchQuery.length > 0
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: 1.02
            duration: DesignSystem.animation.duration.fast
            easing.type: DesignSystem.animation.easing.standard
        }
        
        PropertyAnimation {
            target: root
            property: "scale"
            to: 1.0
            duration: DesignSystem.animation.duration.fast
            easing.type: DesignSystem.animation.easing.standard
        }
    }
    
    // ==================== 公共方法 ====================
    
    function updateHighlight(newQuery) {
        searchQuery = newQuery
    }
    
    function clearHighlight() {
        searchQuery = ""
    }
    
    function getMatchCount() {
        if (!originalText || !searchQuery) return 0
        
        var query = searchQuery.trim()
        if (query.length === 0) return 0
        
        var flags = caseSensitive ? "g" : "gi"
        var pattern
        
        if (wholeWords) {
            pattern = new RegExp("\\b" + escapeRegExp(query) + "\\b", flags)
        } else {
            pattern = new RegExp(escapeRegExp(query), flags)
        }
        
        var matches = originalText.match(pattern)
        return matches ? matches.length : 0
    }
}
