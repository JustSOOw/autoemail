#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 简化验证脚本
"""

import sys
import tempfile
from pathlib import Path

# 添加src目录到Python路径
current_dir = Path(__file__).parent.parent
sys.path.insert(0, str(current_dir / "src"))

from models.email_model import create_email_model
from models.config_model import ConfigModel
from services.database_service import DatabaseService
from services.email_generator import EmailGenerator
from services.email_service import EmailService
from utils.logger import setup_logger, get_logger

def main():
    """主验证函数"""
    setup_logger(level='INFO')
    logger = get_logger(__name__)
    
    print("开始Phase 1A功能验证")
    print("="*50)
    
    # 创建临时数据库
    with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
        db_path = Path(f.name)
    
    try:
        results = {}
        
        # 1. 验证数据库初始化
        print("1. 验证数据库初始化...")
        db_service = DatabaseService(db_path)
        if db_service.init_database():
            results["database_init"] = True
            print("✓ 数据库初始化成功")
        else:
            results["database_init"] = False
            print("✗ 数据库初始化失败")
        
        # 2. 验证邮箱模型
        print("2. 验证邮箱模型...")
        try:
            email = create_email_model(
                email_address="test@example.com",
                tags=["测试"],
                notes="验证测试"
            )
            assert email.email_address == "test@example.com"
            assert email.domain == "example.com"
            assert "测试" in email.tags
            
            results["email_model"] = True
            print("✓ 邮箱模型验证通过")
        except Exception as e:
            results["email_model"] = False
            print(f"✗ 邮箱模型验证失败: {e}")
        
        # 3. 验证配置模型
        print("3. 验证配置模型...")
        try:
            config = ConfigModel()
            config.domain_config.domain = "test.example.com"
            
            errors = config.validate_config()
            assert "domain" not in errors
            
            results["config_model"] = True
            print("✓ 配置模型验证通过")
        except Exception as e:
            results["config_model"] = False
            print(f"✗ 配置模型验证失败: {e}")
        
        # 4. 验证邮箱生成器
        print("4. 验证邮箱生成器...")
        try:
            config = ConfigModel()
            config.domain_config.domain = "test.example.com"
            
            generator = EmailGenerator(config)
            email1 = generator.generate_email(prefix_type="random_name")
            assert "@test.example.com" in email1
            assert generator.validate_email_format(email1)
            
            results["email_generator"] = True
            print("✓ 邮箱生成器验证通过")
        except Exception as e:
            results["email_generator"] = False
            print(f"✗ 邮箱生成器验证失败: {e}")
        
        # 5. 验证邮箱服务
        print("5. 验证邮箱服务...")
        try:
            config = ConfigModel()
            config.domain_config.domain = "test.example.com"
            
            email_service = EmailService(config, db_service)
            
            email = email_service.create_email(
                prefix_type="custom",
                custom_prefix="test",
                tags=["验证测试"]
            )
            assert email.id is not None
            
            retrieved_email = email_service.get_email_by_id(email.id)
            assert retrieved_email is not None
            
            results["email_service"] = True
            print("✓ 邮箱服务验证通过")
        except Exception as e:
            results["email_service"] = False
            print(f"✗ 邮箱服务验证失败: {e}")
        
        # 输出结果
        print("\n" + "="*50)
        print("验证结果:")
        print("="*50)
        
        passed_count = sum(results.values())
        total_count = len(results)
        
        for test_name, passed in results.items():
            status = "✓ 通过" if passed else "✗ 失败"
            print(f"{test_name:20} : {status}")
        
        print("-"*50)
        print(f"总计: {passed_count}/{total_count} 项验证通过")
        
        if passed_count == total_count:
            print("🎉 Phase 1A 所有功能验证通过！")
            return True
        else:
            print(f"❌ 有 {total_count - passed_count} 项验证失败")
            return False
        
    except Exception as e:
        print(f"验证过程中发生异常: {e}")
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
