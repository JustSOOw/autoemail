#!/usr/bin/env python3
"""
QML语法检查器
使用PyQt6的QML引擎来检查QML文件的语法错误
"""

import sys
import os
from PyQt6.QtCore import QUrl
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtWidgets import QApplication

def check_qml_syntax(qml_file_path):
    """检查QML文件的语法"""
    print(f"正在检查QML文件: {qml_file_path}")
    
    # 创建Qt应用程序
    app = QApplication(sys.argv)
    
    # 创建QML引擎
    engine = QQmlApplicationEngine()
    
    # 连接错误信号
    def on_warnings(warnings):
        print("QML警告和错误:")
        for warning in warnings:
            print(f"  文件: {warning.url().toString()}")
            print(f"  行号: {warning.line()}")
            print(f"  列号: {warning.column()}")
            print(f"  消息: {warning.description()}")
            print(f"  类型: {warning.messageType()}")
            print("  " + "-" * 50)

    engine.warnings.connect(on_warnings)
    
    # 尝试加载QML文件
    try:
        file_url = QUrl.fromLocalFile(os.path.abspath(qml_file_path))
        print(f"加载文件URL: {file_url.toString()}")
        
        engine.load(file_url)
        
        # 检查是否成功加载
        if engine.rootObjects():
            print("✅ QML文件语法正确，加载成功")
            return True
        else:
            print("❌ QML文件加载失败，可能存在语法错误")
            return False
            
    except Exception as e:
        print(f"❌ 加载QML文件时发生异常: {e}")
        return False
    
    finally:
        app.quit()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("用法: python qml_syntax_checker.py <qml_file_path>")
        sys.exit(1)
    
    qml_file = sys.argv[1]
    
    if not os.path.exists(qml_file):
        print(f"错误: 文件不存在 - {qml_file}")
        sys.exit(1)
    
    success = check_qml_syntax(qml_file)
    sys.exit(0 if success else 1)
