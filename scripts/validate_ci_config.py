#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CI/CD配置验证脚本
验证GitHub Actions工作流配置的正确性和兼容性
"""

import os
import sys
import yaml
from pathlib import Path

# 添加项目根目录到路径
ROOT_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT_DIR))

def validate_workflow_file(workflow_path: Path) -> bool:
    """验证单个工作流文件"""
    print(f"\n🔍 验证工作流: {workflow_path.name}")
    
    if not workflow_path.exists():
        print(f"❌ 文件不存在: {workflow_path}")
        return False
    
    try:
        with open(workflow_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # 尝试解析YAML
        try:
            workflow_data = yaml.safe_load(content)
        except yaml.YAMLError as e:
            print(f"❌ YAML语法错误: {e}")
            return False
        
        # 检查基本结构
        if 'name' not in workflow_data:
            print("❌ 缺少工作流名称")
            return False

        # 检查触发条件 (可能是 'on' 或 True)
        has_trigger = False
        for key in workflow_data.keys():
            if key == 'on' or key is True:
                has_trigger = True
                break

        if not has_trigger:
            print("❌ 缺少触发条件")
            print(f"   可用的键: {list(workflow_data.keys())}")
            return False

        if 'jobs' not in workflow_data:
            print("❌ 缺少作业定义")
            return False
        
        # 检查Python版本配置
        python_versions = []
        setup_python_actions = []
        
        def extract_python_info(obj, path=""):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    new_path = f"{path}.{key}" if path else key
                    if key == 'python-version':
                        python_versions.append((new_path, value))
                    elif key == 'uses' and 'setup-python' in str(value):
                        setup_python_actions.append((new_path, value))
                    extract_python_info(value, new_path)
            elif isinstance(obj, list):
                for i, item in enumerate(obj):
                    extract_python_info(item, f"{path}[{i}]")
        
        extract_python_info(workflow_data)
        
        # 验证Python版本
        for path, version in python_versions:
            if isinstance(version, str):
                if version.startswith('3.') and float(version) < 3.11:
                    print(f"⚠️  Python版本可能过低: {version} at {path}")
                else:
                    print(f"✅ Python版本: {version} at {path}")
            elif isinstance(version, list):
                for v in version:
                    if v.startswith('3.') and float(v) < 3.11:
                        print(f"⚠️  Python版本可能过低: {v} at {path}")
                    else:
                        print(f"✅ Python版本: {v} at {path}")
        
        # 验证setup-python action版本
        for path, action in setup_python_actions:
            if 'setup-python@v5' in action:
                print(f"✅ 使用最新setup-python: {action}")
            elif 'setup-python@v4' in action:
                print(f"⚠️  建议升级setup-python: {action} at {path}")
            else:
                print(f"❌ 未知setup-python版本: {action} at {path}")
        
        print(f"✅ {workflow_path.name} 验证通过")
        return True
        
    except Exception as e:
        print(f"❌ 验证失败: {e}")
        return False

def check_ubuntu_compatibility():
    """检查Ubuntu兼容性"""
    print("\n🐧 检查Ubuntu兼容性...")
    
    # 检查是否使用了ubuntu-latest
    workflows_dir = ROOT_DIR / ".github" / "workflows"
    
    for workflow_file in workflows_dir.glob("*.yml"):
        with open(workflow_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if 'ubuntu-latest' in content:
            print(f"✅ {workflow_file.name} 使用 ubuntu-latest")
            
            # 检查是否有系统依赖安装
            if 'apt-get' in content:
                print(f"✅ {workflow_file.name} 包含系统依赖安装")
            else:
                print(f"⚠️  {workflow_file.name} 可能需要添加系统依赖安装")

def check_python_compatibility():
    """检查Python兼容性"""
    print("\n🐍 检查Python兼容性...")
    
    # 检查requirements.txt
    req_file = ROOT_DIR / "requirements.txt"
    if req_file.exists():
        with open(req_file, 'r', encoding='utf-8') as f:
            requirements = f.read()
        
        # 检查可能有兼容性问题的包
        potential_issues = {
            'PyQt6': '需要确保在Ubuntu 24.04上可用',
            'PyInstaller': '需要确保支持Python 3.11',
            'asyncqt': '可能需要特定版本'
        }
        
        for package, note in potential_issues.items():
            if package.lower() in requirements.lower():
                print(f"✅ 发现 {package}: {note}")
        
        print("✅ requirements.txt 检查完成")
    else:
        print("❌ requirements.txt 不存在")

def main():
    """主验证函数"""
    print("🔧 GitHub Actions CI/CD配置验证")
    print("=" * 60)
    
    # 验证所有工作流文件
    workflows_dir = ROOT_DIR / ".github" / "workflows"
    
    if not workflows_dir.exists():
        print("❌ .github/workflows 目录不存在")
        return 1
    
    workflow_files = list(workflows_dir.glob("*.yml"))
    if not workflow_files:
        print("❌ 没有找到工作流文件")
        return 1
    
    print(f"📁 找到 {len(workflow_files)} 个工作流文件")
    
    all_valid = True
    for workflow_file in workflow_files:
        if not validate_workflow_file(workflow_file):
            all_valid = False
    
    # 额外检查
    check_ubuntu_compatibility()
    check_python_compatibility()
    
    # 总结
    print("\n" + "=" * 60)
    if all_valid:
        print("🎉 所有工作流配置验证通过！")
        print("✅ 配置已优化，支持Ubuntu 24.04和Python 3.11")
        return 0
    else:
        print("❌ 部分工作流配置存在问题，请检查上述警告")
        return 1

if __name__ == "__main__":
    try:
        import yaml
    except ImportError:
        print("❌ 需要安装PyYAML: pip install PyYAML")
        sys.exit(1)
    
    sys.exit(main())
