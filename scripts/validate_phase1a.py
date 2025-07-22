#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - Phase 1A 功能验证脚本
验证后端核心功能的完整性和正确性
"""

import sys
import tempfile
from pathlib import Path

# 添加src目录到Python路径
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from models.email_model import EmailModel, VerificationStatus, create_email_model
from models.config_model import ConfigModel
from services.database_service import DatabaseService
from services.email_generator import EmailGenerator
from services.email_service import EmailService
from services.config_service import ConfigService
from utils.database_validator import DatabaseValidator
from utils.encryption import EncryptionManager
from utils.logger import get_logger


def main():
    """主验证函数"""
    logger = get_logger(__name__)
    logger.info("开始Phase 1A功能验证")
    
    # 创建临时数据库
    with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
        db_path = Path(f.name)
    
    try:
        # 验证结果
        results = {
            "database_init": False,
            "database_validation": False,
            "email_model": False,
            "config_model": False,
            "encryption": False,
            "email_generator": False,
            "email_service": False,
            "config_service": False,
            "integration": False
        }
        
        # 1. 验证数据库初始化
        logger.info("1. 验证数据库初始化...")
        db_service = DatabaseService(db_path)
        if db_service.init_database():
            results["database_init"] = True
            logger.info("✓ 数据库初始化成功")
        else:
            logger.error("✗ 数据库初始化失败")
            return False
        
        # 2. 验证数据库结构
        logger.info("2. 验证数据库结构...")
        validator = DatabaseValidator(db_service)
        validation_results = validator.validate_database()
        if validation_results["overall_status"] in ["success", "warning"]:
            results["database_validation"] = True
            logger.info("✓ 数据库结构验证通过")
        else:
            logger.error("✗ 数据库结构验证失败")
            logger.error(f"错误: {validation_results.get('errors', [])}")
        
        # 3. 验证邮箱模型
        logger.info("3. 验证邮箱模型...")
        try:
            email = create_email_model(
                email_address="test@example.com",
                tags=["测试"],
                notes="验证测试"
            )
            assert email.email_address == "test@example.com"
            assert email.domain == "example.com"
            assert email.prefix == "test"
            assert "测试" in email.tags
            
            # 测试序列化
            email_dict = email.to_dict()
            email2 = EmailModel.from_dict(email_dict)
            assert email2.email_address == email.email_address
            
            results["email_model"] = True
            logger.info("✓ 邮箱模型验证通过")
        except Exception as e:
            logger.error(f"✗ 邮箱模型验证失败: {e}")
        
        # 4. 验证配置模型
        logger.info("4. 验证配置模型...")
        try:
            config = ConfigModel()
            config.domain_config.domain = "test.example.com"
            config.tempmail_config.username = "testuser"
            config.tempmail_config.epin = "testpin"
            
            # 测试配置验证
            errors = config.validate_config()
            assert "domain" not in errors  # 域名已设置，不应该有错误
            
            # 测试序列化
            config_dict = config.to_dict()
            config2 = ConfigModel.from_dict(config_dict)
            assert config2.domain_config.domain == config.domain_config.domain
            
            results["config_model"] = True
            logger.info("✓ 配置模型验证通过")
        except Exception as e:
            logger.error(f"✗ 配置模型验证失败: {e}")
        
        # 5. 验证加密功能
        logger.info("5. 验证加密功能...")
        try:
            manager = EncryptionManager("test_password")
            
            original_data = "sensitive_information"
            encrypted_data = manager.encrypt(original_data)
            decrypted_data = manager.decrypt(encrypted_data)
            
            assert encrypted_data != original_data
            assert decrypted_data == original_data
            
            results["encryption"] = True
            logger.info("✓ 加密功能验证通过")
        except Exception as e:
            logger.error(f"✗ 加密功能验证失败: {e}")
        
        # 6. 验证邮箱生成器
        logger.info("6. 验证邮箱生成器...")
        try:
            config = ConfigModel()
            config.domain_config.domain = "test.example.com"
            
            generator = EmailGenerator(config)
            
            # 测试生成邮箱
            email1 = generator.generate_email(prefix_type="random_name")
            assert "@test.example.com" in email1
            assert generator.validate_email_format(email1)
            
            # 测试自定义前缀
            email2 = generator.generate_email(
                prefix_type="custom", 
                custom_prefix="mytest"
            )
            assert "mytest" in email2
            
            # 测试批量生成
            emails = generator.generate_batch_emails(3)
            assert len(emails) == 3
            
            results["email_generator"] = True
            logger.info("✓ 邮箱生成器验证通过")
        except Exception as e:
            logger.error(f"✗ 邮箱生成器验证失败: {e}")
        
        # 7. 验证邮箱服务
        logger.info("7. 验证邮箱服务...")
        try:
            config = ConfigModel()
            config.domain_config.domain = "test.example.com"
            
            email_service = EmailService(config, db_service)
            
            # 创建邮箱
            email = email_service.create_email(
                prefix_type="custom",
                custom_prefix="test",
                tags=["验证测试"],
                notes="服务验证"
            )
            assert email.id is not None
            
            # 获取邮箱
            retrieved_email = email_service.get_email_by_id(email.id)
            assert retrieved_email is not None
            assert retrieved_email.email_address == email.email_address
            
            # 搜索邮箱
            emails = email_service.search_emails(keyword="test")
            assert len(emails) > 0
            
            # 获取统计信息
            stats = email_service.get_statistics()
            assert "total_emails" in stats
            
            results["email_service"] = True
            logger.info("✓ 邮箱服务验证通过")
        except Exception as e:
            logger.error(f"✗ 邮箱服务验证失败: {e}")
        
        # 8. 验证配置服务
        logger.info("8. 验证配置服务...")
        try:
            config_service = ConfigService(db_service)
            
            config = ConfigModel()
            config.domain_config.domain = "test.example.com"
            config.verification_method = "tempmail"
            
            # 保存配置
            success = config_service.save_config(config)
            assert success
            
            # 加载配置
            loaded_config = config_service.load_config()
            assert loaded_config.domain_config.domain == "test.example.com"
            
            # 设置配置值
            success = config_service.set_config_value("domain_config.domain", "new.example.com")
            assert success
            
            # 验证配置值
            value = config_service.get_config_value("domain_config.domain")
            assert value == "new.example.com"
            
            results["config_service"] = True
            logger.info("✓ 配置服务验证通过")
        except Exception as e:
            logger.error(f"✗ 配置服务验证失败: {e}")
        
        # 9. 验证集成功能
        logger.info("9. 验证集成功能...")
        try:
            # 完整工作流测试
            config = ConfigModel()
            config.domain_config.domain = "integration.test.com"
            
            config_service = ConfigService(db_service)
            email_service = EmailService(config, db_service)
            
            # 保存配置
            config_service.save_config(config)
            
            # 创建邮箱
            email = email_service.create_email(
                prefix_type="random_name",
                tags=["集成测试"],
                notes="完整工作流验证"
            )
            
            # 添加标签
            email_service.add_email_tag(email.id, "新标签")
            
            # 导出数据
            exported_data = email_service.export_emails()
            assert email.email_address in exported_data
            
            results["integration"] = True
            logger.info("✓ 集成功能验证通过")
        except Exception as e:
            logger.error(f"✗ 集成功能验证失败: {e}")
        
        # 输出验证结果
        logger.info("\n" + "="*60)
        logger.info("Phase 1A 功能验证结果:")
        logger.info("="*60)
        
        passed_count = sum(results.values())
        total_count = len(results)
        
        for test_name, passed in results.items():
            status = "✓ 通过" if passed else "✗ 失败"
            logger.info(f"{test_name:20} : {status}")
        
        logger.info("-"*60)
        logger.info(f"总计: {passed_count}/{total_count} 项验证通过")
        
        if passed_count == total_count:
            logger.info("🎉 Phase 1A 所有功能验证通过！")
            return True
        else:
            logger.error(f"❌ 有 {total_count - passed_count} 项验证失败")
            return False
        
    except Exception as e:
        logger.error(f"验证过程中发生异常: {e}")
        return False
    
    finally:
        # 清理
        try:
            db_service.close()
            if db_path.exists():
                db_path.unlink()
        except:
            pass


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
