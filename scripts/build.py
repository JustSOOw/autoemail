#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 构建脚本
用于打包应用程序为可执行文件
"""

import os
import sys
import shutil
import subprocess
import platform
from pathlib import Path

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

def print_step(message):
    """打印构建步骤"""
    print(f"\n{'='*60}")
    print(f"🔧 {message}")
    print(f"{'='*60}")

def check_requirements():
    """检查构建环境"""
    print_step("检查构建环境")
    
    # 检查Python版本
    python_version = sys.version_info
    if python_version < (3, 9):
        print(f"❌ Python版本过低: {python_version.major}.{python_version.minor}")
        print("   需要Python 3.9或更高版本")
        return False
    
    print(f"✅ Python版本: {python_version.major}.{python_version.minor}.{python_version.micro}")
    
    # 检查必需的包
    required_packages = [
        "PyQt6",
        "PyInstaller",
        "cryptography",
        "requests"
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package.lower().replace("-", "_"))
            print(f"✅ {package}: 已安装")
        except ImportError:
            missing_packages.append(package)
            print(f"❌ {package}: 未安装")
    
    if missing_packages:
        print(f"\n请安装缺失的包:")
        print(f"pip install {' '.join(missing_packages)}")
        return False
    
    return True

def clean_build():
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
        
        print("✅ 资源目录结构创建完成")
    else:
        print("✅ 资源目录已存在")

def create_spec_file():
    """创建PyInstaller spec文件"""
    print_step("创建PyInstaller配置文件")
    
    # 获取系统信息
    system = platform.system().lower()
    
    # 图标文件路径
    icon_path = RESOURCES_DIR / "icons" / "app.ico"
    if not icon_path.exists():
        icon_path = None
    
    # 创建spec文件内容
    spec_content = f'''# -*- mode: python ; coding: utf-8 -*-
"""
{PROJECT_NAME} PyInstaller配置文件
自动生成，请勿手动编辑
"""

import sys
from pathlib import Path

# 项目路径
project_root = Path(r"{ROOT_DIR}")
src_path = project_root / "src"
resources_path = project_root / "resources"

# 添加源码路径
sys.path.insert(0, str(src_path))

block_cipher = None

a = Analysis(
    [str(src_path / "main.py")],
    pathex=[str(src_path)],
    binaries=[],
    datas=[
        (str(resources_path), "resources"),
    ],
    hiddenimports=[
        "PyQt6.QtCore",
        "PyQt6.QtGui", 
        "PyQt6.QtWidgets",
        "PyQt6.QtSql",
        "sqlite3",
        "cryptography.fernet",
        "asyncqt",
        "requests",
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
        "PIL",
        "cv2",
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
    name="{PROJECT_NAME}",
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
    
    spec_file_path = ROOT_DIR / f"{PROJECT_NAME}.spec"
    
    with open(spec_file_path, 'w', encoding='utf-8') as f:
        f.write(spec_content)
    
    print(f"✅ Spec文件创建完成: {spec_file_path}")
    return spec_file_path

def build_executable(spec_file_path):
    """构建可执行文件"""
    print_step("构建可执行文件")
    
    # PyInstaller命令
    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--clean",
        "--noconfirm", 
        str(spec_file_path)
    ]
    
    print(f"🔨 执行命令: {' '.join(cmd)}")
    
    try:
        # 执行构建
        result = subprocess.run(
            cmd, 
            cwd=ROOT_DIR,
            capture_output=True,
            text=True,
            encoding='utf-8'
        )
        
        if result.returncode == 0:
            print("✅ 构建成功!")
            
            # 显示构建输出的最后几行
            if result.stdout:
                lines = result.stdout.strip().split('\n')
                print("\n📋 构建日志 (最后10行):")
                for line in lines[-10:]:
                    print(f"   {line}")
                    
        else:
            print("❌ 构建失败!")
            print(f"错误代码: {result.returncode}")
            if result.stderr:
                print(f"错误信息:\n{result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ 构建过程中发生异常: {e}")
        return False
    
    return True

def create_installer():
    """创建安装程序 (可选)"""
    print_step("创建安装程序")
    
    exe_path = DIST_DIR / f"{PROJECT_NAME}.exe"
    
    if not exe_path.exists():
        print(f"❌ 可执行文件不存在: {exe_path}")
        return False
    
    # 检查文件大小
    file_size = exe_path.stat().st_size / (1024 * 1024)  # MB
    print(f"📦 可执行文件大小: {file_size:.1f} MB")
    
    # 创建发布目录
    release_dir = DIST_DIR / "release"
    release_dir.mkdir(exist_ok=True)
    
    # 复制可执行文件
    release_exe = release_dir / f"{PROJECT_NAME}_v{VERSION}.exe"
    shutil.copy2(exe_path, release_exe)
    
    # 创建README文件
    readme_content = f"""# {PROJECT_NAME} v{VERSION}

## 安装说明

1. 双击 {PROJECT_NAME}_v{VERSION}.exe 运行程序
2. 首次运行需要配置域名和邮箱设置
3. 详细使用说明请参考项目文档

## 系统要求

- Windows 10 或更高版本
- 4GB RAM (推荐)
- 100MB 磁盘空间

## 技术支持

- 项目主页: https://github.com/your-username/email-domain-manager
- 问题反馈: https://github.com/your-username/email-domain-manager/issues

构建时间: {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
构建版本: {VERSION}
"""
    
    readme_path = release_dir / "README.txt"
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme_content)
    
    print(f"✅ 发布文件创建完成:")
    print(f"   📁 发布目录: {release_dir}")
    print(f"   📦 可执行文件: {release_exe}")
    print(f"   📄 说明文件: {readme_path}")
    
    return True

def main():
    """主构建流程"""
    # 检查是否为测试模式
    test_only = "--test-only" in sys.argv

    print(f"""
╔══════════════════════════════════════════════════════════════╗
║                    {PROJECT_NAME} 构建工具                    ║
║                        版本: {VERSION}                         ║
╚══════════════════════════════════════════════════════════════╝
""")

    if test_only:
        print("🧪 测试构建模式 - 仅验证构建环境")

    # 检查构建环境
    if not check_requirements():
        print("\n❌ 构建环境检查失败，请解决上述问题后重试")
        return 1

    try:
        # 清理构建目录
        clean_build()
        
        # 复制资源文件
        copy_resources()
        
        # 创建spec文件
        spec_file_path = create_spec_file()

        if test_only:
            print("✅ 构建环境验证完成")
            print("📋 构建配置文件已生成")
            print(f"📄 Spec文件: {spec_file_path}")
            return 0

        # 构建可执行文件
        if not build_executable(spec_file_path):
            print("\n❌ 构建失败")
            return 1
        
        # 创建安装程序
        if not create_installer():
            print("\n⚠️  安装程序创建失败，但可执行文件构建成功")
        
        print_step("构建完成")
        print("🎉 构建成功完成!")
        print(f"📦 可执行文件位置: {DIST_DIR / f'{PROJECT_NAME}.exe'}")
        print(f"📁 发布文件位置: {DIST_DIR / 'release'}")
        
        return 0
        
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
