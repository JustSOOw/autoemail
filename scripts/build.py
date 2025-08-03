#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - PyQt6跨平台构建脚本

基于PyQt6最佳实践：
- Windows: 生成单个exe文件 (--onefile)
- Linux: 生成目录结构 (--onedir) 
- 正确处理PyQt6依赖和资源文件
- 修复QtCore DLL加载问题

作者: 自动邮箱管理器项目组
创建时间: 2025年1月
"""

import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional

# 设置编码处理
if platform.system() == "Windows":
    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8")
        except Exception:
            pass
    os.environ["PYTHONIOENCODING"] = "utf-8"

# 项目配置
PROJECT_NAME = "EmailDomainManager"
VERSION = "1.0.0"
AUTHOR = "Email Domain Manager Team"
DESCRIPTION = "域名邮箱管理器 - 基于PyQt6的邮箱生成和管理工具"

# 路径配置
ROOT_DIR = Path(__file__).parent.parent
SRC_DIR = ROOT_DIR / "src"
BUILD_DIR = ROOT_DIR / "build"
DIST_DIR = ROOT_DIR / "dist"
RESOURCES_DIR = ROOT_DIR / "src" / "resources"

# 支持的平台配置
SUPPORTED_PLATFORMS = {
    "windows": {
        "name": "Windows",
        "executable_ext": ".exe",
        "icon_file": "app.ico",
        "build_mode": "onefile",
        "pyinstaller_args": [
            "--onefile",
            "--windowed", 
            "--noconsole",
            "--clean",
            "--noconfirm"
        ],
    },
    "linux": {
        "name": "Linux",
        "executable_ext": "",
        "icon_file": "app.png",
        "build_mode": "onedir",
        "pyinstaller_args": [
            "--onedir",
            "--windowed",
            "--clean",
            "--noconfirm"
        ],
    }
}


def print_step(message: str):
    """打印构建步骤信息"""
    print(f"\n{'='*60}")
    print(f"🔧 {message}")
    print('='*60)


def get_current_platform() -> str:
    """获取当前平台"""
    system = platform.system().lower()
    if system == "windows":
        return "windows"
    elif system == "linux":
        return "linux"
    else:
        raise ValueError(f"不支持的平台: {system}")


def get_platform_config(platform_name: str) -> Dict:
    """获取平台配置"""
    if platform_name not in SUPPORTED_PLATFORMS:
        raise ValueError(f"不支持的平台: {platform_name}")
    return SUPPORTED_PLATFORMS[platform_name]


def check_dependencies():
    """检查构建依赖"""
    print_step("检查构建依赖")
    
    # 检查PyInstaller
    try:
        import PyInstaller
        print(f"✅ PyInstaller版本: {PyInstaller.__version__}")
    except ImportError:
        print("❌ PyInstaller未安装")
        print("请运行: pip install pyinstaller")
        return False
    
    # 检查PyQt6
    try:
        import PyQt6
        print(f"✅ PyQt6已安装")
    except ImportError:
        print("❌ PyQt6未安装")
        print("请运行: pip install PyQt6")
        return False
    
    # 检查主程序文件
    main_file = SRC_DIR / "main.py"
    if not main_file.exists():
        print(f"❌ 主程序文件不存在: {main_file}")
        return False
    print(f"✅ 主程序文件: {main_file}")
    
    return True


def clean_build_dirs():
    """清理构建目录"""
    print_step("清理构建目录")
    
    dirs_to_clean = [BUILD_DIR, DIST_DIR]
    
    for dir_path in dirs_to_clean:
        if dir_path.exists():
            print(f"🗑️  删除目录: {dir_path}")
            shutil.rmtree(dir_path)
        else:
            print(f"📁 目录不存在: {dir_path}")
    
    # 创建必要的目录
    BUILD_DIR.mkdir(exist_ok=True)
    DIST_DIR.mkdir(exist_ok=True)
    
    print("✅ 构建目录清理完成")


def build_application(platform_name: str = None, arch: str = None) -> bool:
    """构建应用程序"""
    if platform_name is None:
        platform_name = get_current_platform()

    if arch is None:
        arch = "x86_64"  # 默认架构

    platform_config = get_platform_config(platform_name)
    print_step(f"构建{platform_config['name']} {arch}版本应用程序")

    # 构建PyInstaller命令
    main_file = SRC_DIR / "main.py"
    cmd = [
        sys.executable,
        "-m", "PyInstaller"
    ]

    # 添加平台特定参数
    cmd.extend(platform_config["pyinstaller_args"])

    # 优化文件大小 - 排除不需要的模块
    exclude_modules = [
        # GUI框架（我们只用PyQt6）
        "tkinter", "tkinter.ttk", "tkinter.constants",
        "PySide2", "PySide6", "PyQt5",

        # 科学计算库（项目不需要）
        "matplotlib", "numpy", "pandas", "scipy",
        "sklearn", "tensorflow", "torch", "keras",

        # 图像处理（除非项目需要）
        "PIL", "Pillow", "cv2", "opencv",

        # 网络框架（项目不需要）
        "flask", "django", "tornado", "fastapi",

        # 开发工具
        "pytest", "unittest", "doctest",
        "pdb", "cProfile", "profile",

        # 其他大型库
        "IPython", "jupyter", "notebook",
        "sphinx", "jinja2",

        # PyQt6中不需要的模块
        "PyQt6.QtWebEngine", "PyQt6.QtWebEngineWidgets",
        "PyQt6.QtCharts", "PyQt6.QtDataVisualization",
        "PyQt6.Qt3D", "PyQt6.QtLocation", "PyQt6.QtPositioning",
        "PyQt6.QtMultimedia", "PyQt6.QtMultimediaWidgets",
        "PyQt6.QtBluetooth", "PyQt6.QtNfc", "PyQt6.QtSensors"
    ]

    for module in exclude_modules:
        cmd.extend(["--exclude-module", module])

    # 平台特定的优化
    if platform_name == "windows":
        # Windows特定排除
        cmd.extend([
            "--exclude-module", "curses",
            "--exclude-module", "readline",
            "--exclude-module", "termios"
        ])
    elif platform_name == "linux":
        # Linux特定排除
        cmd.extend([
            "--exclude-module", "winsound",
            "--exclude-module", "msvcrt",
            "--exclude-module", "winreg"
        ])

    # 移除空的参数
    cmd = [arg for arg in cmd if arg]

    # 添加输出目录（包含架构信息）
    output_dir = f"{platform_name}-{arch}"
    cmd.extend([
        "--distpath", str(DIST_DIR / output_dir),
        "--workpath", str(BUILD_DIR / output_dir),
        "--specpath", str(BUILD_DIR)
    ])

    # 添加应用名称
    cmd.extend(["--name", PROJECT_NAME])
    
    # 添加图标（如果存在）
    icon_file = RESOURCES_DIR / "icons" / platform_config["icon_file"]
    if icon_file.exists():
        cmd.extend(["--icon", str(icon_file)])
        print(f"📎 使用图标: {icon_file}")
    else:
        print(f"⚠️ 图标文件不存在: {icon_file}")
    
    # 添加资源文件
    if RESOURCES_DIR.exists():
        cmd.extend(["--add-data", f"{RESOURCES_DIR}{os.pathsep}."])
        print(f"📁 添加资源目录: {RESOURCES_DIR}")
    
    # 添加QML文件（如果存在）
    qml_dir = SRC_DIR / "views" / "qml"
    if qml_dir.exists():
        cmd.extend(["--add-data", f"{qml_dir}{os.pathsep}qml"])
        print(f"📁 添加QML目录: {qml_dir}")
    
    # 精确的PyQt6依赖管理（避免文件过大）
    # 只收集项目实际使用的模块
    hidden_imports = [
        # 核心模块（必需）
        "PyQt6.QtCore",
        "PyQt6.QtGui",
        "PyQt6.QtWidgets",

        # QML相关模块（项目使用QML界面）
        "PyQt6.QtQml",
        "PyQt6.QtQuick",
        "PyQt6.QtQuickControls2",
        "PyQt6.QtQuickLayouts",

        # SIP支持（必需）
        "PyQt6.sip",

        # 项目特定模块
        "asyncqt",
        "cryptography.fernet",
        "sqlite3",
        "json",
        "csv",
        "datetime",
        "pathlib",
        "logging",
        "asyncio",
        "requests"
    ]

    for module in hidden_imports:
        cmd.extend(["--hidden-import", module])

    # 精确添加必需的Qt6文件（避免全部复制）
    try:
        import PyQt6
        qt6_path = Path(PyQt6.__file__).parent

        # 只添加必需的Qt6插件
        qt6_plugins = qt6_path / "Qt6" / "plugins"
        if qt6_plugins.exists():
            # 只添加关键插件，不是全部
            essential_plugins = ["platforms", "imageformats", "styles"]
            for plugin in essential_plugins:
                plugin_path = qt6_plugins / plugin
                if plugin_path.exists():
                    cmd.extend(["--add-data", f"{plugin_path}{os.pathsep}PyQt6/Qt6/plugins/{plugin}"])
                    print(f"📁 添加Qt6插件: {plugin}")

        # 只添加QML必需模块
        qt6_qml = qt6_path / "Qt6" / "qml"
        if qt6_qml.exists():
            # 只添加项目使用的QML模块
            essential_qml = ["QtQuick", "QtQuick.Controls", "QtQuick.Layouts", "QtQuick.Templates"]
            for qml_module in essential_qml:
                qml_path = qt6_qml / qml_module.replace(".", "/")
                if qml_path.exists():
                    cmd.extend(["--add-data", f"{qml_path}{os.pathsep}PyQt6/Qt6/qml/{qml_module.replace('.', '/')}"])
                    print(f"📁 添加QML模块: {qml_module}")

    except Exception as e:
        print(f"⚠️ 无法自动添加Qt6路径: {e}")
        print("   将使用PyInstaller的自动检测功能")
    
    # 添加主文件
    cmd.append(str(main_file))
    
    print(f"🔨 执行命令: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("✅ PyInstaller构建成功")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ PyInstaller构建失败")
        print(f"错误码: {e.returncode}")
        print(f"错误输出: {e.stderr}")
        return False


def verify_build(platform_name: str = None, arch: str = None) -> bool:
    """验证构建结果"""
    if platform_name is None:
        platform_name = get_current_platform()

    if arch is None:
        arch = "x86_64"  # 默认架构

    platform_config = get_platform_config(platform_name)
    print_step(f"验证{platform_config['name']} {arch}构建结果")

    # 检查可执行文件（包含架构信息）
    output_dir = f"{platform_name}-{arch}"
    if platform_config["build_mode"] == "onefile":
        # 单文件模式
        executable_path = DIST_DIR / output_dir / f"{PROJECT_NAME}{platform_config['executable_ext']}"
    else:
        # 目录模式
        executable_path = DIST_DIR / output_dir / PROJECT_NAME / f"{PROJECT_NAME}{platform_config['executable_ext']}"
    
    if not executable_path.exists():
        print(f"❌ 可执行文件不存在: {executable_path}")
        return False
    
    # 检查文件大小
    file_size = executable_path.stat().st_size / (1024 * 1024)  # MB
    print(f"📦 可执行文件: {executable_path}")
    print(f"📏 文件大小: {file_size:.1f} MB")
    
    if file_size < 1:
        print("⚠️ 警告: 文件大小异常小，可能构建不完整")
        return False
    
    print("✅ 构建验证通过")
    return True


def main():
    """主函数"""
    print(f"🚀 开始构建 {PROJECT_NAME} v{VERSION}")
    print(f"📋 描述: {DESCRIPTION}")
    print(f"👥 作者: {AUTHOR}")
    
    # 解析命令行参数
    import argparse
    parser = argparse.ArgumentParser(description="域名邮箱管理器构建脚本")
    parser.add_argument("--platform", choices=["windows", "linux"],
                       help="目标平台 (默认: 当前平台)")
    parser.add_argument("--arch", choices=["x86_64", "arm64"],
                       default="x86_64", help="目标架构 (默认: x86_64)")
    parser.add_argument("--test-only", action="store_true",
                       help="仅测试构建配置，不执行构建")

    args = parser.parse_args()

    # 确定目标平台和架构
    target_platform = args.platform or get_current_platform()
    target_arch = args.arch
    print(f"🎯 目标平台: {SUPPORTED_PLATFORMS[target_platform]['name']}")
    print(f"🏗️ 目标架构: {target_arch}")

    # 检查依赖
    if not check_dependencies():
        print("❌ 依赖检查失败")
        return 1

    if args.test_only:
        print("✅ 测试模式: 构建配置检查通过")
        return 0

    # 清理构建目录
    clean_build_dirs()

    # 构建应用程序
    if not build_application(target_platform, target_arch):
        print("❌ 构建失败")
        return 1

    # 验证构建结果
    if not verify_build(target_platform, target_arch):
        print("❌ 构建验证失败")
        return 1

    print(f"\n🎉 构建完成！")
    print(f"📁 输出目录: {DIST_DIR / f'{target_platform}-{target_arch}'}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
