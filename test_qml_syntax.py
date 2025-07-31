#!/usr/bin/env python3
"""
简单的QML语法检查脚本
检查修复后的QML文件是否有语法错误
"""

import os
import sys
import re

def check_qml_syntax(file_path):
    """检查QML文件的基本语法"""
    print(f"检查文件: {file_path}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 基本语法检查
        errors = []
        
        # 检查括号匹配
        open_braces = content.count('{')
        close_braces = content.count('}')
        if open_braces != close_braces:
            errors.append(f"括号不匹配: {{ {open_braces} vs }} {close_braces}")
        
        # 检查圆括号匹配
        open_parens = content.count('(')
        close_parens = content.count(')')
        if open_parens != close_parens:
            errors.append(f"圆括号不匹配: ( {open_parens} vs ) {close_parens}")
        
        # 检查方括号匹配
        open_brackets = content.count('[')
        close_brackets = content.count(']')
        if open_brackets != close_brackets:
            errors.append(f"方括号不匹配: [ {open_brackets} vs ] {close_brackets}")
        
        # 检查基本的QML结构
        if not re.search(r'import\s+QtQuick', content):
            errors.append("缺少 QtQuick 导入")
        
        if errors:
            print(f"  ❌ 发现 {len(errors)} 个问题:")
            for error in errors:
                print(f"    - {error}")
            return False
        else:
            print(f"  ✅ 语法检查通过")
            return True
            
    except Exception as e:
        print(f"  ❌ 读取文件失败: {e}")
        return False

def main():
    """主函数"""
    print("🔍 QML语法检查工具")
    print("=" * 50)
    
    # 要检查的文件列表
    qml_files = [
        "src/views/qml/components/StatusMessage.qml",
        "src/views/qml/pages/ConfigurationPage.qml", 
        "src/views/qml/pages/EmailManagementPage.qml",
        "src/views/qml/pages/TagManagementPage.qml"
    ]
    
    all_passed = True
    
    for qml_file in qml_files:
        if os.path.exists(qml_file):
            if not check_qml_syntax(qml_file):
                all_passed = False
        else:
            print(f"❌ 文件不存在: {qml_file}")
            all_passed = False
        print()
    
    print("=" * 50)
    if all_passed:
        print("🎉 所有文件语法检查通过！")
        return 0
    else:
        print("❌ 部分文件存在语法问题，请检查修复")
        return 1

if __name__ == "__main__":
    sys.exit(main())
