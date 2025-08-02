#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 启动脚本
提供简单的启动入口和环境检查
"""

import os
import sys
from pathlib import Path


def main():
    """主函数"""
    print("🚀 启动域名邮箱管理器...")

    # 检查Python版本
    if sys.version_info < (3, 9):
        print(f"❌ Python版本过低: {sys.version_info.major}.{sys.version_info.minor}")
        print("   需要Python 3.9或更高版本")
        input("按任意键退出...")
        return 1

    # 添加项目路径
    project_root = Path(__file__).parent.parent  # 脚本在scripts目录中
    src_path = project_root / "src"
    sys.path.insert(0, str(src_path))

    try:
        # 导入并运行主程序
        from main import main as app_main

        return app_main()

    except ImportError as e:
        print(f"❌ 导入模块失败: {e}")
        print("请确保已安装所有依赖包:")
        print("pip install -r requirements.txt")
        input("按任意键退出...")
        return 1

    except Exception as e:
        print(f"❌ 启动失败: {e}")
        import traceback

        traceback.print_exc()
        input("按任意键退出...")
        return 1


if __name__ == "__main__":
    sys.exit(main())
