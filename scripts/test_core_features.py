#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 简化版本测试脚本
测试简化后的邮箱管理功能
"""

import sys
import tempfile
from pathlib import Path

# 添加src目录到Python路径
current_dir = Path(__file__).parent.parent
sys.path.insert(0, str(current_dir / "src"))

from models.email_model import EmailModel, EmailStatus, create_email_model
from models.config_model import ConfigModel
from services.database_service import DatabaseService
from services.email_generator import EmailGenerator
from services.email_service import EmailService
from utils.logger import setup_logger, get_logger


def main():
    """主测试函数"""
    setup_logger(level='INFO')
    logger = get_logger(__name__)
    
    print("开始简化版本功能测试")
    print("="*50)
    
    # 创建临时数据库
    with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
        db_path = Path(f.name)
    
    try:
        results = {}
        
        # 1. 初始化数据库
        print("1. 初始化数据库...")
        db_service = DatabaseService(db_path)
        if db_service.init_database():
            results["database_init"] = True
            print("✓ 数据库初始化成功")
        else:
            results["database_init"] = False
            print("✗ 数据库初始化失败")
            return False
        
        # 2. 测试配置和邮箱生成器
        print("2. 测试邮箱生成器...")
        try:
            config = ConfigModel()
            config.domain_config.domain = "test.example.com"
            
            generator = EmailGenerator(config)
            email_address = generator.generate_email(prefix_type="random_name")
            assert "@test.example.com" in email_address
            assert generator.validate_email_format(email_address)
            
            results["email_generator"] = True
            print("✓ 邮箱生成器测试通过")
        except Exception as e:
            results["email_generator"] = False
            print(f"✗ 邮箱生成器测试失败: {e}")
        
        # 3. 测试简化邮箱模型
        print("3. 测试简化邮箱模型...")
        try:
            email = create_email_model(
                email_address="test@example.com",
                tags=["测试", "简化版"],
                notes="这是一个测试邮箱"
            )
            
            assert email.email_address == "test@example.com"
            assert email.domain == "example.com"
            assert email.prefix == "test"
            assert "测试" in email.tags
            assert email.status == EmailStatus.ACTIVE
            
            # 测试序列化
            email_dict = email.to_dict()
            email2 = EmailModel.from_dict(email_dict)
            assert email2.email_address == email.email_address
            
            results["email_model"] = True
            print("✓ 简化邮箱模型测试通过")
        except Exception as e:
            results["email_model"] = False
            print(f"✗ 简化邮箱模型测试失败: {e}")
        
        # 4. 测试简化邮箱服务
        print("4. 测试简化邮箱服务...")
        try:
            config = ConfigModel()
            config.domain_config.domain = "simple.test.com"
            
            email_service = EmailService(config, db_service)
            
            # 创建邮箱
            email = email_service.create_email(
                prefix_type="custom",
                custom_prefix="simple_test",
                tags=["简化测试"],
                notes="简化版本测试邮箱"
            )
            assert email.id is not None
            assert "simple_test" in email.email_address
            assert "@simple.test.com" in email.email_address
            
            # 获取邮箱
            retrieved_email = email_service.get_email_by_id(email.id)
            assert retrieved_email is not None
            assert retrieved_email.email_address == email.email_address
            
            # 搜索邮箱
            emails = email_service.search_emails(keyword="simple_test")
            assert len(emails) > 0
            
            # 添加标签
            success = email_service.add_email_tag(email.id, "新标签")
            assert success
            
            # 更新邮箱
            email.notes = "更新后的备注"
            success = email_service.update_email(email)
            assert success
            
            # 获取统计信息
            stats = email_service.get_statistics()
            assert "total_emails" in stats
            assert stats["total_emails"] > 0
            
            results["email_service"] = True
            print("✓ 简化邮箱服务测试通过")
        except Exception as e:
            results["email_service"] = False
            print(f"✗ 简化邮箱服务测试失败: {e}")
        
        # 5. 测试批量操作
        print("5. 测试批量操作...")
        try:
            # 批量创建邮箱
            for i in range(3):
                email_service.create_email(
                    prefix_type="custom",
                    custom_prefix=f"batch_{i}",
                    tags=["批量测试"],
                    notes=f"批量创建的第{i+1}个邮箱"
                )
            
            # 搜索批量创建的邮箱
            batch_emails = email_service.search_emails(tags=["批量测试"])
            assert len(batch_emails) >= 3
            
            # 测试导出功能
            json_data = email_service.export_emails(format_type="json")
            assert "batch_" in json_data
            
            csv_data = email_service.export_emails(format_type="csv")
            assert "batch_" in csv_data
            assert "邮箱地址" in csv_data
            
            results["batch_operations"] = True
            print("✓ 批量操作测试通过")
        except Exception as e:
            results["batch_operations"] = False
            print(f"✗ 批量操作测试失败: {e}")
        
        # 6. 测试邮箱状态管理
        print("6. 测试邮箱状态管理...")
        try:
            # 创建测试邮箱
            test_email = email_service.create_email(
                prefix_type="custom",
                custom_prefix="status_test",
                notes="状态测试邮箱"
            )
            
            # 测试状态变更
            test_email.archive()
            assert test_email.status == EmailStatus.ARCHIVED
            
            test_email.activate()
            assert test_email.status == EmailStatus.ACTIVE
            
            test_email.deactivate()
            assert test_email.status == EmailStatus.INACTIVE
            
            # 更新到数据库
            success = email_service.update_email(test_email)
            assert success
            
            # 验证状态已保存
            retrieved = email_service.get_email_by_id(test_email.id)
            assert retrieved.status == EmailStatus.INACTIVE
            
            results["status_management"] = True
            print("✓ 邮箱状态管理测试通过")
        except Exception as e:
            results["status_management"] = False
            print(f"✗ 邮箱状态管理测试失败: {e}")
        
        # 输出测试结果
        print("\n" + "="*50)
        print("简化版本功能测试结果:")
        print("="*50)
        
        passed_count = sum(results.values())
        total_count = len(results)
        
        for test_name, passed in results.items():
            status = "✓ 通过" if passed else "✗ 失败"
            print(f"{test_name:20} : {status}")
        
        print("-"*50)
        print(f"总计: {passed_count}/{total_count} 项测试通过")
        
        if passed_count == total_count:
            print("🎉 简化版本所有功能测试通过！")
            print("\n核心功能说明:")
            print("- ✅ 邮箱地址生成（基于域名和时间戳）")
            print("- ✅ 邮箱存储和管理（增删改查）")
            print("- ✅ 标签分类系统")
            print("- ✅ 状态管理（活跃/非活跃/归档）")
            print("- ✅ 搜索和过滤功能")
            print("- ✅ 数据导出（JSON/CSV）")
            print("- ✅ 统计信息")
            print("\n这是一个专注于邮箱管理的简单工具，无需复杂的验证功能！")
            return True
        else:
            print(f"❌ 有 {total_count - passed_count} 项测试失败")
            return False
        
    except Exception as e:
        print(f"测试过程中发生异常: {e}")
        return False
    
    finally:
        try:
            db_service.close()
            if db_path.exists():
                db_path.unlink()
        except:
            pass


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
