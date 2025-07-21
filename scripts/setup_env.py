#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 虚拟环境设置脚本
确保项目在隔离的虚拟环境中运行
"""

import sys
import os
import subprocess
from pathlib import Path

def check_virtual_env():
    """检查是否在虚拟环境中"""
    return (
        hasattr(sys, 'real_prefix') or 
        (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix)
    )

def get_project_root():
    """获取项目根目录"""
    return Path(__file__).parent.parent

def create_virtual_env():
    """创建虚拟环境"""
    project_root = get_project_root()
    venv_path = project_root / "venv"
    
    print("🔧 创建虚拟环境...")
    print(f"   位置: {venv_path}")
    
    try:
        # 创建虚拟环境
        subprocess.run([
            sys.executable, "-m", "venv", str(venv_path)
        ], check=True, cwd=project_root)
        
        print("✅ 虚拟环境创建成功")
        return venv_path
        
    except subprocess.CalledProcessError as e:
        print(f"❌ 虚拟环境创建失败: {e}")
        return None

def get_venv_python():
    """获取虚拟环境中的Python路径"""
    project_root = get_project_root()
    venv_path = project_root / "venv"
    
    if os.name == 'nt':  # Windows
        python_path = venv_path / "Scripts" / "python.exe"
    else:  # Linux/Mac
        python_path = venv_path / "bin" / "python"
    
    return python_path

def install_dependencies():
    """在虚拟环境中安装依赖"""
    project_root = get_project_root()
    requirements_file = project_root / "requirements.txt"
    python_path = get_venv_python()

    if not requirements_file.exists():
        print("⚠️  requirements.txt 文件不存在")
        return False
    
    print("📦 安装项目依赖...")
    print(f"   使用Python: {python_path}")
    
    try:
        subprocess.run([
            str(python_path), "-m", "pip", "install", "-r", str(requirements_file)
        ], check=True, cwd=project_root)
        
        print("✅ 依赖安装成功")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ 依赖安装失败: {e}")
        return False

def show_activation_instructions():
    """显示虚拟环境激活说明"""
    project_root = get_project_root()
    
    print("\n" + "="*60)
    print("🎯 虚拟环境设置完成")
    print("="*60)
    
    if os.name == 'nt':  # Windows
        activate_script = project_root / "venv" / "Scripts" / "activate.bat"
        print("📋 激活虚拟环境:")
        print(f"   {activate_script}")
        print("   或者:")
        print(f"   cd {project_root}")
        print("   venv\\Scripts\\activate")
    else:  # Linux/Mac
        activate_script = project_root / "venv" / "bin" / "activate"
        print("📋 激活虚拟环境:")
        print(f"   source {activate_script}")
        print("   或者:")
        print(f"   cd {project_root}")
        print("   source venv/bin/activate")
    
    print("\n🚀 激活后运行项目:")
    print("   python run.py")
    print("   python run.py test")
    print("   python run.py build")

def main():
    """主函数"""
    print("🔧 域名邮箱管理器 - 虚拟环境设置")
    print("="*50)
    
    # 检查当前是否在虚拟环境中
    if check_virtual_env():
        print("✅ 当前已在虚拟环境中")
        print(f"   Python路径: {sys.executable}")
        
        # 检查是否需要安装依赖
        try:
            import PyQt6
            print("✅ PyQt6已安装")
        except ImportError:
            print("📦 PyQt6未安装，正在安装依赖...")
            if install_dependencies():
                print("✅ 环境设置完成，可以运行项目")
            else:
                print("❌ 依赖安装失败")
                return 1
        
        return 0
    
    # 检查虚拟环境是否存在
    project_root = get_project_root()
    venv_path = project_root / "venv"
    
    if venv_path.exists():
        print("📁 发现现有虚拟环境")
        print(f"   位置: {venv_path}")
        print("⚠️  请手动激活虚拟环境后再运行项目")
        show_activation_instructions()
        return 0
    
    # 创建新的虚拟环境
    print("🆕 未发现虚拟环境，正在创建...")
    
    venv_path = create_virtual_env()
    if not venv_path:
        print("❌ 虚拟环境创建失败")
        return 1
    
    # 安装依赖
    if install_dependencies():
        print("✅ 虚拟环境设置完成")
        show_activation_instructions()
        return 0
    else:
        print("❌ 虚拟环境设置失败")
        return 1

if __name__ == "__main__":
    sys.exit(main())
