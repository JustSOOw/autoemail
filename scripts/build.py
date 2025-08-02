#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 跨平台构建脚本
支持Linux和Windows平台的打包操作
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
    # 确保stdout能正确处理UTF-8编码
    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8")
        except Exception:
            pass
    # 设置环境变量确保正确的编码
    os.environ["PYTHONIOENCODING"] = "utf-8"

# 项目配置
PROJECT_NAME = "EmailDomainManager"
VERSION = "1.0.0"
AUTHOR = "Email Domain Manager Team"
DESCRIPTION = "域名邮箱管理器 - 基于Cloudflare的邮箱生成和管理工具"

# 路径配置
ROOT_DIR = Path(__file__).parent.parent  # 脚本在scripts目录中，需要上一级
SRC_DIR = ROOT_DIR / "src"
BUILD_DIR = ROOT_DIR / "build"
DIST_DIR = ROOT_DIR / "dist"
RESOURCES_DIR = ROOT_DIR / "src" / "resources"

# 支持的平台配置
SUPPORTED_PLATFORMS = {
    "windows": {
        "name": "Windows",
        "executable_ext": ".exe",
        "icon_ext": ".ico",
        "separator": "\\",
        "pyinstaller_args": ["--windowed"],
    },
    "linux": {
        "name": "Linux",
        "executable_ext": "",
        "icon_ext": ".png",
        "separator": "/",
        "pyinstaller_args": ["--windowed"],
    },
}


def get_current_platform() -> str:
    """获取当前平台标识"""
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


def print_step(message: str):
    """打印构建步骤"""
    print(f"\n{'='*60}")
    print(f"🔧 {message}")
    print(f"{'='*60}")


def print_platform_info(target_platforms: List[str]):
    """打印平台信息"""
    current_platform = get_current_platform()
    print(f"🖥️  当前平台: {SUPPORTED_PLATFORMS[current_platform]['name']}")
    print(f"🎯 目标平台: {', '.join([SUPPORTED_PLATFORMS[p]['name'] for p in target_platforms])}")

    if current_platform not in target_platforms:
        print(f"⚠️  注意: 当前平台({SUPPORTED_PLATFORMS[current_platform]['name']})不在目标平台列表中")


def check_requirements(target_platforms: List[str]) -> bool:
    """检查构建环境"""
    print_step("检查构建环境")

    print_platform_info(target_platforms)

    # 检查Python版本
    python_version = sys.version_info
    if python_version < (3, 9):
        print(f"❌ Python版本过低: {python_version.major}.{python_version.minor}")
        print("   需要Python 3.9或更高版本")
        return False

    print(
        f"✅ Python版本: {python_version.major}.{python_version.minor}.{python_version.micro}"
    )

    # 检查必需的包
    required_packages = {
        "PyQt6": "PyQt6",
        "PyInstaller": "PyInstaller",
        "cryptography": "cryptography",
        "requests": "requests",
        "loguru": "loguru",
        "pydantic": "pydantic",
    }

    missing_packages = []
    for package_name, import_name in required_packages.items():
        try:
            __import__(import_name)
            print(f"✅ {package_name}: 已安装")
        except ImportError:
            missing_packages.append(package_name)
            print(f"❌ {package_name}: 未安装")

    # 特殊检查asyncqt (可选依赖，需要先导入PyQt6)
    try:
        import PyQt6  # 先导入PyQt6
        import asyncqt
        print(f"✅ asyncqt: 已安装")
    except ImportError as e:
        print(f"⚠️  asyncqt: 未安装或不兼容 ({e}) - 这是可选依赖，不影响构建")

    if missing_packages:
        print(f"\n请安装缺失的包:")
        print(f"pip install {' '.join(missing_packages)}")
        return False

    return True


def clean_build(target_platforms: List[str]):
    """清理构建目录"""
    print_step("清理构建目录")

    dirs_to_clean = [BUILD_DIR]

    # 为每个目标平台清理对应的dist目录
    for platform_name in target_platforms:
        platform_dist_dir = DIST_DIR / platform_name
        dirs_to_clean.append(platform_dist_dir)

    for dir_path in dirs_to_clean:
        if dir_path.exists():
            print(f"🗑️  删除目录: {dir_path}")
            shutil.rmtree(dir_path)
        else:
            print(f"📁 目录不存在: {dir_path}")

    # 创建必要的目录
    BUILD_DIR.mkdir(exist_ok=True)
    DIST_DIR.mkdir(exist_ok=True)

    # 为每个目标平台创建dist子目录
    for platform_name in target_platforms:
        platform_dist_dir = DIST_DIR / platform_name
        platform_dist_dir.mkdir(exist_ok=True)

    print("✅ 构建目录清理完成")


def copy_resources():
    """复制资源文件"""
    print_step("复制资源文件")

    if not RESOURCES_DIR.exists():
        print("📁 创建资源目录")
        RESOURCES_DIR.mkdir(exist_ok=True)

        # 创建基础资源结构
        (RESOURCES_DIR / "icons").mkdir(exist_ok=True)
        (RESOURCES_DIR / "styles").mkdir(exist_ok=True)
        (RESOURCES_DIR / "database").mkdir(exist_ok=True)
        (RESOURCES_DIR / "qml").mkdir(exist_ok=True)

        print("✅ 资源目录结构创建完成")
    else:
        print("✅ 资源目录已存在")

    # 确保QML文件被包含
    qml_source = SRC_DIR / "views" / "qml"
    qml_target = RESOURCES_DIR / "qml"

    if qml_source.exists() and not qml_target.exists():
        print("📁 复制QML文件到资源目录")
        shutil.copytree(qml_source, qml_target)
        print("✅ QML文件复制完成")


def create_spec_file(platform_name: str) -> Path:
    """创建PyInstaller spec文件"""
    print_step(f"创建{SUPPORTED_PLATFORMS[platform_name]['name']}平台的PyInstaller配置文件")

    platform_config = get_platform_config(platform_name)

    # 图标文件路径
    icon_ext = platform_config["icon_ext"]
    icon_path = RESOURCES_DIR / "icons" / f"app{icon_ext}"

    # 如果指定平台的图标不存在，尝试其他格式
    if not icon_path.exists():
        for ext in [".ico", ".png", ".icns"]:
            alt_icon = RESOURCES_DIR / "icons" / f"app{ext}"
            if alt_icon.exists():
                icon_path = alt_icon
                break
        else:
            icon_path = None

    # 平台特定的配置
    executable_name = f"{PROJECT_NAME}{platform_config['executable_ext']}"

    # 创建spec文件内容
    spec_content = f'''# -*- mode: python ; coding: utf-8 -*-
"""
{PROJECT_NAME} PyInstaller配置文件 - {platform_config['name']}平台
自动生成，请勿手动编辑
"""

import sys
from pathlib import Path

# 项目路径
project_root = Path(r"{ROOT_DIR}")
src_path = project_root / "src"
resources_path = src_path / "resources"
qml_path = src_path / "views" / "qml"

# 添加源码路径
sys.path.insert(0, str(src_path))

block_cipher = None

# 数据文件配置
datas = []

# 添加资源文件
if resources_path.exists():
    datas.append((str(resources_path), "resources"))

# 添加QML文件
if qml_path.exists():
    datas.append((str(qml_path), "qml"))

# 添加配置文件
config_path = project_root / "config"
if config_path.exists():
    datas.append((str(config_path), "config"))

a = Analysis(
    [str(src_path / "main.py")],
    pathex=[str(src_path)],
    binaries=[],
    datas=datas,
    hiddenimports=[
        "PyQt6.QtCore",
        "PyQt6.QtGui",
        "PyQt6.QtWidgets",
        "PyQt6.QtSql",
        "PyQt6.QtQml",
        "PyQt6.QtQuick",
        "PyQt6.QtQuickControls2",
        "sqlite3",
        "cryptography.fernet",
        "asyncqt",
        "requests",
        "aiohttp",
        "loguru",
        "pydantic",
        "email.mime.text",
        "email.mime.multipart",
        "imaplib",
        "poplib",
        "json",
        "csv",
        "datetime",
        "pathlib",
        "logging",
        "asyncio",
        "regex",
        "ujson",
        "psutil",
    ],
    hookspath=[],
    hooksconfig={{}},
    runtime_hooks=[],
    excludes=[
        "tkinter",
        "matplotlib",
        "numpy",
        "pandas",
        "scipy",
        "cv2",
        "IPython",
        "jupyter",
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="{executable_name}",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,  # 隐藏控制台窗口
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon={f"r'{icon_path}'" if icon_path else "None"},
    version_file=None,
)
'''

    spec_file_path = ROOT_DIR / f"{PROJECT_NAME}_{platform_name}.spec"

    with open(spec_file_path, "w", encoding="utf-8") as f:
        f.write(spec_content)

    print(f"✅ {platform_config['name']}平台Spec文件创建完成: {spec_file_path}")
    return spec_file_path


def build_executable(spec_file_path: Path, platform_name: str) -> bool:
    """构建可执行文件"""
    platform_config = get_platform_config(platform_name)
    print_step(f"构建{platform_config['name']}平台可执行文件")

    # PyInstaller命令
    cmd = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--clean",
        "--noconfirm",
        "--distpath", str(DIST_DIR / platform_name),
        str(spec_file_path),
    ]

    print(f"🔨 执行命令: {' '.join(cmd)}")

    try:
        # 执行构建
        result = subprocess.run(
            cmd, cwd=ROOT_DIR, capture_output=True, text=True, encoding="utf-8"
        )

        if result.returncode == 0:
            print(f"✅ {platform_config['name']}平台构建成功!")

            # 显示构建输出的最后几行
            if result.stdout:
                lines = result.stdout.strip().split("\n")
                print("\n📋 构建日志 (最后10行):")
                for line in lines[-10:]:
                    print(f"   {line}")

        else:
            print(f"❌ {platform_config['name']}平台构建失败!")
            print(f"错误代码: {result.returncode}")
            if result.stderr:
                print(f"错误信息:\n{result.stderr}")
            if result.stdout:
                print(f"输出信息:\n{result.stdout}")
            return False

    except Exception as e:
        print(f"❌ {platform_config['name']}平台构建过程中发生异常: {e}")
        return False

    return True


def create_release_package(platform_name: str) -> bool:
    """创建发布包"""
    platform_config = get_platform_config(platform_name)
    print_step(f"创建{platform_config['name']}平台发布包")

    executable_name = f"{PROJECT_NAME}{platform_config['executable_ext']}"
    exe_path = DIST_DIR / platform_name / executable_name

    if not exe_path.exists():
        print(f"❌ 可执行文件不存在: {exe_path}")
        return False

    # 检查文件大小
    file_size = exe_path.stat().st_size / (1024 * 1024)  # MB
    print(f"📦 可执行文件大小: {file_size:.1f} MB")

    # 创建发布目录
    release_dir = DIST_DIR / platform_name / "release"
    release_dir.mkdir(exist_ok=True)

    # 复制可执行文件
    release_exe_name = f"{PROJECT_NAME}_v{VERSION}_{platform_name}{platform_config['executable_ext']}"
    release_exe = release_dir / release_exe_name
    shutil.copy2(exe_path, release_exe)

    # 创建平台特定的README文件
    system_requirements = {
        "windows": "- Windows 10 或更高版本\n- 4GB RAM (推荐)\n- 100MB 磁盘空间",
        "linux": "- Linux发行版 (Ubuntu 18.04+, CentOS 7+等)\n- 4GB RAM (推荐)\n- 100MB 磁盘空间\n- X11或Wayland显示服务器"
    }

    install_instructions = {
        "windows": f"1. 双击 {release_exe_name} 运行程序",
        "linux": f"1. 给文件添加执行权限: chmod +x {release_exe_name}\n2. 运行程序: ./{release_exe_name}"
    }

    readme_content = f"""# {PROJECT_NAME} v{VERSION} - {platform_config['name']}版本

## 安装说明

{install_instructions[platform_name]}
2. 首次运行需要配置域名和邮箱设置
3. 详细使用说明请参考项目文档

## 系统要求

{system_requirements[platform_name]}

## 技术支持

- 项目主页: https://github.com/your-username/email-domain-manager
- 问题反馈: https://github.com/your-username/email-domain-manager/issues

构建时间: {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
构建版本: {VERSION}
构建平台: {platform_config['name']}
"""

    readme_path = release_dir / "README.txt"
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(readme_content)

    print(f"✅ {platform_config['name']}平台发布文件创建完成:")
    print(f"   📁 发布目录: {release_dir}")
    print(f"   📦 可执行文件: {release_exe}")
    print(f"   📄 说明文件: {readme_path}")

    return True


def parse_arguments() -> tuple[List[str], bool]:
    """解析命令行参数"""
    target_platforms = []
    test_only = False

    for arg in sys.argv[1:]:
        if arg == "--test-only":
            test_only = True
        elif arg == "--windows":
            target_platforms.append("windows")
        elif arg == "--linux":
            target_platforms.append("linux")
        elif arg == "--all":
            target_platforms = ["windows", "linux"]
        elif arg in ["--help", "-h"]:
            print_help()
            sys.exit(0)

    # 如果没有指定平台，默认构建当前平台
    if not target_platforms:
        try:
            current_platform = get_current_platform()
            target_platforms = [current_platform]
        except ValueError:
            print("❌ 无法检测当前平台，请手动指定目标平台")
            print_help()
            sys.exit(1)

    return target_platforms, test_only


def print_help():
    """打印帮助信息"""
    help_text = f"""
{PROJECT_NAME} 跨平台构建工具 v{VERSION}

用法:
    python build.py [选项]

选项:
    --windows       构建Windows版本
    --linux         构建Linux版本
    --all           构建所有支持的平台版本
    --test-only     仅测试构建环境，不执行实际构建
    --help, -h      显示此帮助信息

示例:
    python build.py --windows --linux    # 构建Windows和Linux版本
    python build.py --all                # 构建所有平台版本
    python build.py --test-only          # 仅测试构建环境
    python build.py                      # 构建当前平台版本

支持的平台:
    - Windows (生成 .exe 文件)
    - Linux (生成可执行文件)
"""
    print(help_text)


def build_platform(platform_name: str, test_only: bool = False) -> bool:
    """构建指定平台"""
    platform_config = get_platform_config(platform_name)

    try:
        print_step(f"开始构建{platform_config['name']}平台")

        # 创建spec文件
        spec_file_path = create_spec_file(platform_name)

        if test_only:
            print(f"✅ {platform_config['name']}平台构建配置验证完成")
            print(f"📄 Spec文件: {spec_file_path}")
            return True

        # 构建可执行文件
        if not build_executable(spec_file_path, platform_name):
            print(f"\n❌ {platform_config['name']}平台构建失败")
            return False

        # 创建发布包
        if not create_release_package(platform_name):
            print(f"\n⚠️  {platform_config['name']}平台发布包创建失败，但可执行文件构建成功")

        print(f"✅ {platform_config['name']}平台构建完成")
        return True

    except Exception as e:
        print(f"\n❌ {platform_config['name']}平台构建过程中发生错误: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """主构建流程"""
    # 解析命令行参数
    target_platforms, test_only = parse_arguments()

    # 使用兼容的字符显示标题
    try:
        # 尝试使用Unicode字符
        header = f"""
╔══════════════════════════════════════════════════════════════╗
║                {PROJECT_NAME} 跨平台构建工具                ║
║                        版本: {VERSION}                         ║
╚══════════════════════════════════════════════════════════════╝
"""
        print(header)
    except UnicodeEncodeError:
        # 如果Unicode字符不支持，使用ASCII字符
        header = f"""
+==============================================================+
|                {PROJECT_NAME} 跨平台构建工具                |
|                        版本: {VERSION}                         |
+==============================================================+
"""
        print(header)

    if test_only:
        print("🧪 测试构建模式 - 仅验证构建环境")

    # 检查构建环境
    if not check_requirements(target_platforms):
        print("\n❌ 构建环境检查失败，请解决上述问题后重试")
        return 1

    try:
        # 清理构建目录
        clean_build(target_platforms)

        # 复制资源文件
        copy_resources()

        if test_only:
            print("\n🧪 测试模式 - 验证所有平台配置")
            success_count = 0
            for platform_name in target_platforms:
                if build_platform(platform_name, test_only=True):
                    success_count += 1

            print(f"\n✅ 构建环境验证完成: {success_count}/{len(target_platforms)} 个平台配置正确")
            return 0 if success_count == len(target_platforms) else 1

        # 构建所有目标平台
        print(f"\n🚀 开始构建 {len(target_platforms)} 个平台版本")
        success_platforms = []
        failed_platforms = []

        for platform_name in target_platforms:
            if build_platform(platform_name):
                success_platforms.append(platform_name)
            else:
                failed_platforms.append(platform_name)

        # 构建结果总结
        print_step("构建结果总结")

        if success_platforms:
            print("✅ 构建成功的平台:")
            for platform_name in success_platforms:
                platform_config = get_platform_config(platform_name)
                executable_name = f"{PROJECT_NAME}{platform_config['executable_ext']}"
                exe_path = DIST_DIR / platform_name / executable_name
                release_path = DIST_DIR / platform_name / "release"
                print(f"   🎯 {platform_config['name']}: {exe_path}")
                print(f"      📁 发布包: {release_path}")

        if failed_platforms:
            print("\n❌ 构建失败的平台:")
            for platform_name in failed_platforms:
                platform_config = get_platform_config(platform_name)
                print(f"   ❌ {platform_config['name']}")

        if success_platforms and not failed_platforms:
            print("\n🎉 所有平台构建成功完成!")
            return 0
        elif success_platforms:
            print(f"\n⚠️  部分平台构建成功 ({len(success_platforms)}/{len(target_platforms)})")
            return 1
        else:
            print("\n❌ 所有平台构建失败")
            return 1

    except KeyboardInterrupt:
        print("\n\n⚠️  构建被用户中断")
        return 1
    except Exception as e:
        print(f"\n❌ 构建过程中发生未预期的错误: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
