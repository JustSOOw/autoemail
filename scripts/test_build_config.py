#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
构建配置测试脚本
验证GitHub Actions自动打包发布流程的配置是否正确
"""

import os
import platform
import sys
from pathlib import Path

# 添加项目根目录到路径
ROOT_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT_DIR))

def test_icon_files():
    """测试图标文件是否存在"""
    print("🎨 测试应用图标文件...")
    
    icons_dir = ROOT_DIR / "src" / "resources" / "icons"
    
    required_icons = {
        "Windows主图标": icons_dir / "app.ico",
        "Windows小图标": icons_dir / "app16x16.ico", 
        "Linux图标": icons_dir / "app.png"
    }
    
    all_exist = True
    for name, icon_path in required_icons.items():
        if icon_path.exists():
            size = icon_path.stat().st_size
            print(f"✅ {name}: {icon_path} ({size} bytes)")
        else:
            print(f"❌ {name}: {icon_path} - 文件不存在")
            all_exist = False
    
    return all_exist

def test_build_script():
    """测试构建脚本配置"""
    print("\n🔧 测试构建脚本配置...")
    
    try:
        # 导入构建脚本
        sys.path.insert(0, str(ROOT_DIR / "scripts"))
        import build
        
        # 测试平台检测
        current_platform = build.get_current_platform()
        print(f"✅ 当前平台检测: {current_platform}")
        
        # 测试平台配置
        platform_config = build.get_platform_config(current_platform)
        print(f"✅ 平台配置: {platform_config}")
        
        # 测试架构检测
        current_arch = platform.machine().lower()
        if current_arch in ['amd64', 'x86_64']:
            arch = 'x86_64'
        elif current_arch in ['arm64', 'aarch64']:
            arch = 'arm64'
        else:
            arch = current_arch
        print(f"✅ 架构检测: {arch}")
        
        return True
        
    except Exception as e:
        print(f"❌ 构建脚本测试失败: {e}")
        return False

def test_github_actions_config():
    """测试GitHub Actions配置文件"""
    print("\n📋 测试GitHub Actions配置...")
    
    workflow_file = ROOT_DIR / ".github" / "workflows" / "main-release.yml"
    
    if not workflow_file.exists():
        print(f"❌ 工作流文件不存在: {workflow_file}")
        return False
    
    print(f"✅ 工作流文件存在: {workflow_file}")
    
    # 读取并检查关键配置
    try:
        with open(workflow_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 检查关键配置项
        checks = {
            "多平台支持": "matrix:" in content,
            "Windows支持": "windows-latest" in content,
            "Linux支持": "ubuntu-latest" in content,
            "架构配置": "arch:" in content,
            "图标验证": "检查应用图标文件" in content,
            "发布创建": "create-release" in content,
            "文档部署": "deploy-docs" in content
        }
        
        all_passed = True
        for check_name, passed in checks.items():
            if passed:
                print(f"✅ {check_name}: 配置正确")
            else:
                print(f"❌ {check_name}: 配置缺失")
                all_passed = False
        
        return all_passed
        
    except Exception as e:
        print(f"❌ 读取工作流文件失败: {e}")
        return False

def test_project_structure():
    """测试项目结构"""
    print("\n📁 测试项目结构...")
    
    required_paths = {
        "源码目录": ROOT_DIR / "src",
        "主程序": ROOT_DIR / "src" / "main.py",
        "资源目录": ROOT_DIR / "src" / "resources",
        "图标目录": ROOT_DIR / "src" / "resources" / "icons",
        "构建脚本": ROOT_DIR / "scripts" / "build.py",
        "依赖文件": ROOT_DIR / "requirements.txt",
        "GitHub Actions": ROOT_DIR / ".github" / "workflows"
    }
    
    all_exist = True
    for name, path in required_paths.items():
        if path.exists():
            print(f"✅ {name}: {path}")
        else:
            print(f"❌ {name}: {path} - 不存在")
            all_exist = False
    
    return all_exist

def main():
    """主测试函数"""
    print("🧪 GitHub Actions自动打包发布配置测试")
    print("=" * 60)
    
    tests = [
        ("项目结构", test_project_structure),
        ("图标文件", test_icon_files),
        ("构建脚本", test_build_script),
        ("GitHub Actions配置", test_github_actions_config)
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name}测试异常: {e}")
            results.append((test_name, False))
    
    # 输出测试结果总结
    print("\n" + "=" * 60)
    print("📊 测试结果总结:")
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {test_name}: {status}")
        if result:
            passed += 1
    
    print(f"\n总计: {passed}/{total} 项测试通过")
    
    if passed == total:
        print("🎉 所有测试通过！GitHub Actions配置已就绪。")
        return 0
    else:
        print("⚠️  部分测试失败，请检查上述问题。")
        return 1

if __name__ == "__main__":
    sys.exit(main())
