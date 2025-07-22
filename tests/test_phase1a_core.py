# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - Phase 1A 核心功能测试
测试后端核心功能的完整性和正确性
"""

import pytest
import tempfile
from pathlib import Path
from datetime import datetime

# 添加src目录到Python路径
import sys
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from models.email_model import EmailModel, VerificationStatus, VerificationMethod, create_email_model
from models.config_model import ConfigModel, DomainConfig, IMAPConfig, TempMailConfig
from services.database_service import DatabaseService
from services.email_generator import EmailGenerator
from services.email_service import EmailService
from services.config_service import ConfigService
from utils.database_validator import DatabaseValidator
from utils.encryption import EncryptionManager


class TestPhase1ACore:
    """Phase 1A 核心功能测试类"""

    @pytest.fixture
    def temp_db_path(self):
        """创建临时数据库路径"""
        with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
            db_path = Path(f.name)
        yield db_path
        # 清理
        if db_path.exists():
            db_path.unlink()

    @pytest.fixture
    def db_service(self, temp_db_path):
        """创建数据库服务实例"""
        service = DatabaseService(temp_db_path)
        service.init_database()
        yield service
        # 清理：关闭数据库连接
        service.close()

    @pytest.fixture
    def test_config(self):
        """创建测试配置"""
        config = ConfigModel()
        config.domain_config.domain = "test.example.com"
        config.tempmail_config.username = "testuser"
        config.tempmail_config.epin = "testpin"
        config.tempmail_config.extension = "@mailto.plus"
        return config

    def test_database_initialization(self, db_service):
        """测试数据库初始化"""
        # 验证数据库文件存在
        assert db_service.db_path.exists()
        
        # 验证表结构
        tables = ["emails", "tags", "email_tags", "configurations", "operation_logs"]
        for table in tables:
            table_info = db_service.get_table_info(table)
            assert len(table_info) > 0, f"表 {table} 不存在或没有列"
        
        # 验证统计信息
        stats = db_service.get_database_stats()
        assert "emails_count" in stats
        assert "tags_count" in stats

    def test_database_validation(self, db_service):
        """测试数据库验证"""
        validator = DatabaseValidator(db_service)
        results = validator.validate_database()
        
        assert results["overall_status"] in ["success", "warning"]
        assert "tables" in results
        assert "emails" in results["tables"]
        assert results["tables"]["emails"]["exists"]

    def test_email_model_creation(self):
        """测试邮箱模型创建"""
        # 测试基本创建
        email = create_email_model(
            email_address="test@example.com",
            tags=["测试", "开发"],
            notes="测试邮箱"
        )
        
        assert email.email_address == "test@example.com"
        assert email.domain == "example.com"
        assert email.prefix == "test"
        assert "测试" in email.tags
        assert email.notes == "测试邮箱"
        assert email.verification_status == VerificationStatus.PENDING

    def test_email_model_serialization(self):
        """测试邮箱模型序列化"""
        email = create_email_model("test@example.com")
        
        # 测试转换为字典
        email_dict = email.to_dict()
        assert email_dict["email_address"] == "test@example.com"
        assert email_dict["verification_status"] == "pending"
        
        # 测试从字典创建
        email2 = EmailModel.from_dict(email_dict)
        assert email2.email_address == email.email_address
        assert email2.verification_status == email.verification_status
        
        # 测试JSON序列化
        json_str = email.to_json()
        email3 = EmailModel.from_json(json_str)
        assert email3.email_address == email.email_address

    def test_config_model_validation(self):
        """测试配置模型验证"""
        config = ConfigModel()
        
        # 测试空配置验证
        errors = config.validate_config()
        assert "domain" in errors  # 域名为空应该有错误
        
        # 设置域名
        config.domain_config.domain = "test.example.com"
        errors = config.validate_config()
        assert "domain" not in errors  # 域名设置后应该没有错误

    def test_config_encryption(self):
        """测试配置加密"""
        config = ConfigModel()
        config.imap_config.password = "secret_password"
        config.tempmail_config.epin = "secret_epin"
        
        # 测试加密
        config.encrypt_sensitive_data("test_master_password")
        
        # 验证数据已加密（不等于原始值）
        assert config.imap_config.password != "secret_password"
        assert config.tempmail_config.epin != "secret_epin"
        
        # 测试解密
        config.decrypt_sensitive_data("test_master_password")
        assert config.imap_config.password == "secret_password"
        assert config.tempmail_config.epin == "secret_epin"

    def test_email_generator(self, test_config):
        """测试邮箱生成器"""
        generator = EmailGenerator(test_config)
        
        # 测试生成随机名字邮箱
        email1 = generator.generate_email(prefix_type="random_name")
        assert "@test.example.com" in email1
        assert generator.validate_email_format(email1)
        
        # 测试生成随机字符串邮箱
        email2 = generator.generate_email(prefix_type="random_string")
        assert "@test.example.com" in email2
        assert generator.validate_email_format(email2)
        
        # 测试自定义前缀
        email3 = generator.generate_email(
            prefix_type="custom", 
            custom_prefix="mytest"
        )
        assert "mytest" in email3
        assert "@test.example.com" in email3
        
        # 测试批量生成
        emails = generator.generate_batch_emails(5)
        assert len(emails) == 5
        assert all("@test.example.com" in email for email in emails)

    def test_email_service_basic_operations(self, db_service, test_config):
        """测试邮箱服务基本操作"""
        email_service = EmailService(test_config, db_service)
        
        # 测试创建邮箱
        email = email_service.create_email(
            prefix_type="custom",
            custom_prefix="test",
            tags=["测试"],
            notes="测试邮箱"
        )
        
        assert email.id is not None
        assert "test" in email.email_address
        assert "@test.example.com" in email.email_address
        
        # 测试根据ID获取邮箱
        retrieved_email = email_service.get_email_by_id(email.id)
        assert retrieved_email is not None
        assert retrieved_email.email_address == email.email_address
        
        # 测试搜索邮箱
        emails = email_service.search_emails(keyword="test")
        assert len(emails) > 0
        assert any(email.email_address == retrieved_email.email_address for email in emails)
        
        # 测试删除邮箱
        success = email_service.delete_email(email.id)
        assert success
        
        # 验证邮箱已被软删除
        deleted_email = email_service.get_email_by_id(email.id)
        assert deleted_email is None or not deleted_email.is_active

    def test_config_service(self, db_service):
        """测试配置服务"""
        config_service = ConfigService(db_service)
        
        # 创建测试配置
        config = ConfigModel()
        config.domain_config.domain = "test.example.com"
        config.verification_method = "tempmail"
        
        # 测试保存配置
        success = config_service.save_config(config)
        assert success
        
        # 测试加载配置
        loaded_config = config_service.load_config()
        assert loaded_config.domain_config.domain == "test.example.com"
        assert loaded_config.verification_method == "tempmail"
        
        # 测试设置配置值
        success = config_service.set_config_value("domain_config.domain", "new.example.com")
        assert success
        
        # 验证配置值已更新
        value = config_service.get_config_value("domain_config.domain")
        assert value == "new.example.com"

    def test_encryption_manager(self):
        """测试加密管理器"""
        # 测试基本加密解密
        manager = EncryptionManager("test_password")
        
        original_data = "sensitive_information"
        encrypted_data = manager.encrypt(original_data)
        decrypted_data = manager.decrypt(encrypted_data)
        
        assert encrypted_data != original_data
        assert decrypted_data == original_data
        
        # 测试字典加密
        data_dict = {
            "username": "user",
            "password": "secret",
            "token": "abc123"
        }
        
        encrypted_dict = manager.encrypt_dict(data_dict, ["password", "token"])
        assert encrypted_dict["username"] == "user"  # 未加密
        assert encrypted_dict["password"] != "secret"  # 已加密
        assert encrypted_dict["token"] != "abc123"  # 已加密
        
        decrypted_dict = manager.decrypt_dict(encrypted_dict, ["password", "token"])
        assert decrypted_dict["password"] == "secret"
        assert decrypted_dict["token"] == "abc123"

    def test_email_service_statistics(self, db_service, test_config):
        """测试邮箱服务统计功能"""
        email_service = EmailService(test_config, db_service)
        
        # 创建一些测试邮箱
        for i in range(3):
            email_service.create_email(
                prefix_type="custom",
                custom_prefix=f"test{i}",
                tags=["测试"]
            )
        
        # 获取统计信息
        stats = email_service.get_statistics()
        
        assert "total_emails" in stats
        assert stats["total_emails"] >= 3
        assert "by_status" in stats
        assert "by_domain" in stats

    def test_email_service_export(self, db_service, test_config):
        """测试邮箱服务导出功能"""
        email_service = EmailService(test_config, db_service)
        
        # 创建测试邮箱
        email_service.create_email(
            prefix_type="custom",
            custom_prefix="export_test",
            tags=["导出测试"]
        )
        
        # 测试JSON导出
        json_data = email_service.export_emails(format_type="json")
        assert "export_test" in json_data
        
        # 测试CSV导出
        csv_data = email_service.export_emails(format_type="csv")
        assert "export_test" in csv_data
        assert "邮箱地址" in csv_data  # CSV标题

    def test_integration_workflow(self, db_service, test_config):
        """测试完整的集成工作流"""
        # 1. 初始化服务
        config_service = ConfigService(db_service)
        email_service = EmailService(test_config, db_service)
        
        # 2. 保存配置
        config_service.save_config(test_config)
        
        # 3. 创建邮箱
        email = email_service.create_email(
            prefix_type="random_name",
            tags=["集成测试"],
            notes="完整工作流测试"
        )
        
        # 4. 验证邮箱已保存
        assert email.id is not None
        
        # 5. 搜索邮箱
        found_emails = email_service.search_emails(tags=["集成测试"])
        assert len(found_emails) > 0
        
        # 6. 添加标签
        success = email_service.add_email_tag(email.id, "新标签")
        assert success
        
        # 7. 获取统计信息
        stats = email_service.get_statistics()
        assert stats["total_emails"] > 0
        
        # 8. 导出数据
        exported_data = email_service.export_emails()
        assert email.email_address in exported_data


if __name__ == "__main__":
    # 运行测试
    pytest.main([__file__, "-v"])
