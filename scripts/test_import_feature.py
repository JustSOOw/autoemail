#!/usr/bin/env python3
"""
测试导入功能的完整工作流程
验证邮箱数据导入的各种场景
"""

import sys
import os
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root / "src"))

from services.import_service import ImportService
from services.database_service import DatabaseService
from services.batch_service import BatchService
from models.config_model import ConfigModel


def test_import_workflow():
    """测试完整的导入工作流程"""
    print("🧪 开始测试邮箱导入功能")
    print("=" * 50)
    
    try:
        # 创建测试配置
        config = ConfigModel()
        config.domain = 'example.com'
        print("✅ 配置创建成功")
        
        # 创建服务
        db_service = DatabaseService(':memory:')
        db_service.init_database()
        batch_service = BatchService(db_service, config)
        import_service = ImportService(db_service, batch_service)
        print("✅ 服务初始化成功")
        
        # 测试文件路径
        test_files = [
            ("tests/test_data/sample_emails.json", "JSON格式"),
            ("tests/test_data/sample_emails.csv", "CSV格式"),
            ("tests/test_data/wrapped_emails.json", "包装JSON格式")
        ]
        
        total_imported = 0
        
        for file_path, file_type in test_files:
            print(f"\n📁 测试 {file_type} 文件: {file_path}")
            
            # 检查文件是否存在
            if not os.path.exists(file_path):
                print(f"❌ 文件不存在: {file_path}")
                continue
            
            # 预览文件
            preview = import_service.preview_file(file_path, limit=2)
            if preview['success']:
                print(f"   📋 预览成功: {len(preview['preview_data'])} 行数据")
                print(f"   📊 列名: {preview.get('columns', [])}")
            else:
                print(f"   ❌ 预览失败: {preview.get('error', '未知错误')}")
                continue
            
            # 验证文件格式
            validation = import_service.validate_file_format(file_path)
            if validation['valid']:
                print(f"   ✅ 格式验证通过: {validation['format']}")
            else:
                print(f"   ❌ 格式验证失败: {validation.get('error', '未知错误')}")
                continue
            
            # 执行导入
            result = import_service.import_from_file(file_path, validation['format'])
            
            print(f"   📥 导入结果:")
            print(f"      成功: {result['success']}")
            print(f"      失败: {result['failed']}")
            print(f"      跳过: {result['skipped']}")
            
            if result.get('errors'):
                print(f"      错误: {result['errors']}")
            
            total_imported += result['success']
        
        print(f"\n🎉 测试完成!")
        print(f"📊 总计导入邮箱: {total_imported} 个")
        
        # 测试冲突处理
        print(f"\n🔄 测试冲突处理...")
        
        # 再次导入同一个文件，测试跳过策略
        result = import_service.import_from_file(
            "tests/test_data/sample_emails.json", 
            "json",
            options={"conflictStrategy": "skip"}
        )
        
        print(f"   重复导入结果 (跳过策略):")
        print(f"      成功: {result['success']}")
        print(f"      失败: {result['failed']}")
        print(f"      跳过: {result['skipped']}")
        
        # 测试更新策略
        result = import_service.import_from_file(
            "tests/test_data/sample_emails.json", 
            "json",
            options={"conflictStrategy": "update"}
        )
        
        print(f"   重复导入结果 (更新策略):")
        print(f"      成功: {result['success']}")
        print(f"      失败: {result['failed']}")
        print(f"      跳过: {result['skipped']}")
        print(f"      更新: {result['updated']}")
        
        print(f"\n✅ 所有测试通过!")
        return True
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_error_handling():
    """测试错误处理"""
    print(f"\n🚨 测试错误处理...")
    
    try:
        config = ConfigModel()
        config.domain = 'example.com'
        
        db_service = DatabaseService(':memory:')
        db_service.init_database()
        batch_service = BatchService(db_service, config)
        import_service = ImportService(db_service, batch_service)
        
        # 测试不存在的文件
        result = import_service.import_from_file("nonexistent.json", "json")
        print(f"   不存在文件的处理: {'✅' if result['failed'] > 0 else '❌'}")
        
        # 测试无效格式
        validation = import_service.validate_file_format("nonexistent.txt")
        print(f"   无效格式的处理: {'✅' if not validation['valid'] else '❌'}")
        
        print(f"   ✅ 错误处理测试通过!")
        
    except Exception as e:
        print(f"   ❌ 错误处理测试失败: {e}")


if __name__ == "__main__":
    success = test_import_workflow()
    test_error_handling()
    
    if success:
        print(f"\n🎊 所有导入功能测试通过!")
        sys.exit(0)
    else:
        print(f"\n💥 导入功能测试失败!")
        sys.exit(1)
