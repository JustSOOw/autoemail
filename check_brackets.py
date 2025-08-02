#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
括号匹配检查工具
检查文件中的各种括号是否正确闭合
"""

import sys
from pathlib import Path

def check_brackets(file_path):
    """
    检查文件中的括号是否匹配
    支持: () [] {}
    """
    # 括号映射
    bracket_pairs = {
        '(': ')',
        '[': ']',
        '{': '}'
    }
    
    # 反向映射
    closing_brackets = {v: k for k, v in bracket_pairs.items()}
    
    # 栈用于跟踪开放的括号
    stack = []
    
    # 错误信息列表
    errors = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"❌ 无法读取文件: {e}")
        return False
    
    # 逐行检查
    for line_num, line in enumerate(lines, 1):
        for col_num, char in enumerate(line, 1):
            if char in bracket_pairs:
                # 开放括号
                stack.append({
                    'char': char,
                    'line': line_num,
                    'col': col_num,
                    'context': line.strip()
                })
            elif char in closing_brackets:
                # 闭合括号
                if not stack:
                    errors.append({
                        'type': 'unexpected_closing',
                        'char': char,
                        'line': line_num,
                        'col': col_num,
                        'context': line.strip(),
                        'message': f"意外的闭合括号 '{char}'"
                    })
                else:
                    last_open = stack.pop()
                    expected_closing = bracket_pairs[last_open['char']]
                    
                    if char != expected_closing:
                        errors.append({
                            'type': 'mismatched',
                            'char': char,
                            'line': line_num,
                            'col': col_num,
                            'context': line.strip(),
                            'expected': expected_closing,
                            'opened_at': last_open,
                            'message': f"括号不匹配: 期望 '{expected_closing}' 但找到 '{char}'"
                        })
    
    # 检查未闭合的括号
    for unclosed in stack:
        errors.append({
            'type': 'unclosed',
            'char': unclosed['char'],
            'line': unclosed['line'],
            'col': unclosed['col'],
            'context': unclosed['context'],
            'message': f"未闭合的括号 '{unclosed['char']}'"
        })
    
    # 输出结果
    print(f"📁 检查文件: {file_path}")
    print(f"📊 总行数: {len(lines)}")
    print("=" * 50)
    
    if not errors:
        print("✅ 所有括号都正确匹配！")
        return True
    else:
        print(f"❌ 发现 {len(errors)} 个括号问题:")
        print()
        
        for i, error in enumerate(errors, 1):
            print(f"{i}. {error['message']}")
            print(f"   位置: 第 {error['line']} 行, 第 {error['col']} 列")
            print(f"   内容: {error['context']}")
            
            if error['type'] == 'mismatched' and 'opened_at' in error:
                opened = error['opened_at']
                print(f"   对应的开放括号在: 第 {opened['line']} 行, 第 {opened['col']} 列")
                print(f"   开放括号内容: {opened['context']}")
            
            print()
        
        return False

def check_qml_specific(file_path):
    """
    QML文件特定的检查
    """
    print("\n🎨 QML特定检查:")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ 无法读取文件: {e}")
        return
    
    # 检查常见的QML结构
    qml_structures = [
        ('import', 'import语句'),
        ('Rectangle', 'Rectangle组件'),
        ('ColumnLayout', 'ColumnLayout组件'),
        ('RowLayout', 'RowLayout组件'),
        ('Button', 'Button组件'),
        ('Dialog', 'Dialog组件'),
        ('property', '属性定义'),
        ('function', '函数定义'),
        ('signal', '信号定义')
    ]
    
    for keyword, description in qml_structures:
        count = content.count(keyword)
        if count > 0:
            print(f"  📌 {description}: {count} 个")

def main():
    """主函数"""
    if len(sys.argv) != 2:
        print("用法: python check_brackets.py <文件路径>")
        print("示例: python check_brackets.py src/views/qml/pages/EmailManagementPage.qml")
        return 1
    
    file_path = Path(sys.argv[1])
    
    if not file_path.exists():
        print(f"❌ 文件不存在: {file_path}")
        return 1
    
    print("🔍 括号匹配检查工具")
    print("=" * 50)
    
    # 执行括号检查
    is_valid = check_brackets(file_path)
    
    # 如果是QML文件，执行额外检查
    if file_path.suffix.lower() == '.qml':
        check_qml_specific(file_path)
    
    return 0 if is_valid else 1

if __name__ == "__main__":
    sys.exit(main())
