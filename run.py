#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 主启动脚本
提供统一的项目入口
"""

import sys
import os
from pathlib import Path

def check_virtual_env():
    """检查是否在虚拟环境中"""
    return (
        hasattr(sys, 'real_prefix') or
        (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix)
    )

def main():
    """主函数"""
    print("🚀 域名邮箱管理器")
    print("=" * 40)

    # 检查Python版本
    if sys.version_info < (3, 9):
        print(f"❌ Python版本过低: {sys.version_info.major}.{sys.version_info.minor}")
        print("   需要Python 3.9或更高版本")
        return 1

    # 检查虚拟环境
    if not check_virtual_env():
        print("⚠️  警告: 未在虚拟环境中运行")
        print("   强烈建议使用虚拟环境以避免依赖冲突")
        print("   运行以下命令设置虚拟环境:")
        print("   python scripts/setup_env.py")
        print()

        # 询问是否继续
        try:
            choice = input("是否继续在全局环境中运行? (y/N): ").strip().lower()
            if choice not in ['y', 'yes']:
                print("👋 已取消运行")
                return 0
        except KeyboardInterrupt:
            print("\n👋 已取消运行")
            return 0
    else:
        print("✅ 运行在虚拟环境中")
        print(f"   Python路径: {sys.executable}")
    
    # 项目根目录
    project_root = Path(__file__).parent
    
    # 检查参数
    if len(sys.argv) > 1:
        command = sys.argv[1].lower()
        
        if command == "test":
            print("🧪 运行测试...")
            os.system(f"python {project_root}/scripts/run_tests.py")
            
        elif command == "build":
            print("🔨 构建应用...")
            os.system(f"python {project_root}/scripts/build.py")
            
        elif command == "start":
            print("▶️ 启动应用...")
            os.system(f"python {project_root}/scripts/start.py")
            
        elif command in ["help", "-h", "--help"]:
            print_help()
            
        else:
            print(f"❌ 未知命令: {command}")
            print_help()
            return 1
    else:
        # 默认启动应用程序
        print("▶️ 启动应用程序...")
        os.system(f"python {project_root}/scripts/start.py")
    
    return 0

def print_help():
    """打印帮助信息"""
    print("""
📋 可用命令:
  python run.py          - 启动应用程序 (默认)
  python run.py start     - 启动应用程序
  python run.py test      - 运行测试
  python run.py build     - 构建exe文件
  python run.py help      - 显示此帮助信息

📝 示例:
  python run.py                    # 启动应用 (现代化QML界面)
  python run.py test               # 运行所有测试
  python run.py build              # 构建可执行文件

🎨 界面特性:
  - Material Design风格
  - 流畅动画效果
  - 响应式布局
  - GPU加速渲染
""")

if __name__ == "__main__":
    sys.exit(main())
