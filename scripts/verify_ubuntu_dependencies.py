#!/usr/bin/env python3
"""
Ubuntu 22.04 系统依赖包验证脚本

此脚本用于验证GitHub Actions工作流中使用的系统依赖包
在Ubuntu 22.04环境中是否可用和正确。
"""

import subprocess
import sys
from typing import List, Dict, Tuple

# GitHub Actions工作流中使用的系统依赖包
DEPENDENCIES = {
    "pr-checks.yml": [
        "xvfb",
        "libgl1-mesa-dri", 
        "libegl1",
        "libxrandr2",
        "libxss1",
        "libxcursor1",
        "libxcomposite1",
        "libasound2",  # 修复后的包名（原为libasound2t64）
        "libxi6",
        "libxtst6"
    ],
    "develop-ci.yml": [
        "libgl1-mesa-glx",
        "libglib2.0-0",
        "libxkbcommon-x11-0",
        "libxcb-icccm4",
        "libxcb-image0",
        "libxcb-keysyms1",
        "libxcb-randr0",
        "libxcb-render-util0",
        "libxcb-xinerama0",
        "libxcb-xfixes0"
    ],
    "main-release.yml": [
        "libgl1-mesa-glx",
        "libglib2.0-0", 
        "libxkbcommon-x11-0",
        "libxcb-icccm4",
        "libxcb-image0",
        "libxcb-keysyms1",
        "libxcb-randr0",
        "libxcb-render-util0",
        "libxcb-xinerama0",
        "libxcb-xfixes0"
    ]
}

def check_package_availability(package: str) -> Tuple[bool, str]:
    """
    检查包是否在Ubuntu 22.04中可用
    
    Args:
        package: 包名
        
    Returns:
        (是否可用, 详细信息)
    """
    try:
        # 使用apt-cache search检查包是否存在
        result = subprocess.run(
            ["apt-cache", "show", package],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            # 提取包版本信息
            lines = result.stdout.split('\n')
            version = "未知版本"
            description = "无描述"
            
            for line in lines:
                if line.startswith("Version:"):
                    version = line.split(":", 1)[1].strip()
                elif line.startswith("Description:"):
                    description = line.split(":", 1)[1].strip()
                    break
                    
            return True, f"版本: {version}, 描述: {description}"
        else:
            return False, f"包不存在或不可用: {result.stderr.strip()}"
            
    except subprocess.TimeoutExpired:
        return False, "检查超时"
    except Exception as e:
        return False, f"检查失败: {str(e)}"

def verify_dependencies() -> Dict[str, List[Tuple[str, bool, str]]]:
    """
    验证所有工作流的依赖包
    
    Returns:
        验证结果字典
    """
    print("🔍 开始验证Ubuntu 22.04系统依赖包...")
    print("=" * 60)
    
    results = {}
    
    for workflow, packages in DEPENDENCIES.items():
        print(f"\n📋 检查 {workflow} 的依赖包:")
        print("-" * 40)
        
        workflow_results = []
        
        for package in packages:
            available, info = check_package_availability(package)
            workflow_results.append((package, available, info))
            
            status = "✅" if available else "❌"
            print(f"{status} {package:<20} - {info}")
            
        results[workflow] = workflow_results
    
    return results

def generate_summary(results: Dict[str, List[Tuple[str, bool, str]]]) -> None:
    """
    生成验证结果摘要
    
    Args:
        results: 验证结果
    """
    print("\n" + "=" * 60)
    print("📊 验证结果摘要")
    print("=" * 60)
    
    total_packages = 0
    available_packages = 0
    failed_packages = []
    
    for workflow, workflow_results in results.items():
        workflow_available = sum(1 for _, available, _ in workflow_results if available)
        workflow_total = len(workflow_results)
        
        total_packages += workflow_total
        available_packages += workflow_available
        
        print(f"\n{workflow}:")
        print(f"  ✅ 可用: {workflow_available}/{workflow_total}")
        
        # 收集失败的包
        for package, available, info in workflow_results:
            if not available:
                failed_packages.append((workflow, package, info))
    
    print(f"\n总体统计:")
    print(f"  📦 总包数: {total_packages}")
    print(f"  ✅ 可用包数: {available_packages}")
    print(f"  ❌ 不可用包数: {len(failed_packages)}")
    print(f"  📈 成功率: {available_packages/total_packages*100:.1f}%")
    
    if failed_packages:
        print(f"\n❌ 需要修复的包:")
        for workflow, package, info in failed_packages:
            print(f"  - {workflow}: {package} ({info})")
        return False
    else:
        print(f"\n🎉 所有依赖包都可用！")
        return True

def main():
    """主函数"""
    print("Ubuntu 22.04 系统依赖包验证工具")
    print("用于验证GitHub Actions工作流的系统依赖包")
    print()
    
    try:
        # 更新包缓存
        print("📦 更新包缓存...")
        subprocess.run(["sudo", "apt-get", "update"], check=True, capture_output=True)
        print("✅ 包缓存更新完成")
        
        # 验证依赖包
        results = verify_dependencies()
        
        # 生成摘要
        success = generate_summary(results)
        
        # 返回适当的退出码
        sys.exit(0 if success else 1)
        
    except subprocess.CalledProcessError as e:
        print(f"❌ 包缓存更新失败: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n⚠️ 用户中断验证过程")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 验证过程出错: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
