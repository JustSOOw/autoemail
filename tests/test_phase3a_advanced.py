# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - Phase 3A 高级功能测试
测试标签系统、搜索筛选、数据导出、批量操作和安全机制
"""

import pytest
import tempfile
import json
from pathlib import Path
from datetime import datetime, timedelta

# 添加src目录到Python路径
import sys
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from models.email_model import EmailModel, EmailStatus, create_email_model
from models.tag_model import TagModel, create_tag_model
from models.config_model import ConfigModel, DomainConfig
from services.database_service import DatabaseService
from services.tag_service import TagService
from services.email_service import EmailService
from services.export_service import ExportService
from services.batch_service import BatchService
from utils.encryption import (
    EncryptionManager, SecureMemoryManager, LogSanitizer, 
    SecureConfigManager, sanitize_for_log
)


class TestPhase3AAdvanced:
    """Phase 3A 高级功能测试类"""

    @pytest.fixture
    def temp_db_path(self):
        """临时数据库路径"""
        with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
            db_path = Path(f.name)
        yield db_path
        if db_path.exists():
            db_path.unlink()

    @pytest.fixture
    def db_service(self, temp_db_path):
        """数据库服务实例"""
        service = DatabaseService(temp_db_path)
        service.init_database()
        yield service
        service.close()

    @pytest.fixture
    def test_config(self):
        """测试配置"""
        config = ConfigModel()
        config.domain_config = DomainConfig(domain="test-phase3a.com")
        return config

    @pytest.fixture
    def tag_service(self, db_service):
        """标签服务实例"""
        return TagService(db_service)

    @pytest.fixture
    def email_service(self, db_service, test_config):
        """邮箱服务实例"""
        return EmailService(test_config, db_service)

    @pytest.fixture
    def export_service(self, db_service):
        """导出服务实例"""
        return ExportService(db_service)

    @pytest.fixture
    def batch_service(self, db_service, test_config):
        """批量操作服务实例"""
        return BatchService(db_service, test_config)

    @pytest.fixture
    def sample_emails(self, email_service):
        """创建示例邮箱数据"""
        emails = []
        for i in range(10):
            email = email_service.create_email(
                prefix_type="custom",
                custom_prefix=f"test{i:02d}",
                tags=[f"tag{i%3}", "test"],
                notes=f"测试邮箱 {i}"
            )
            emails.append(email)
        return emails

    @pytest.fixture
    def sample_tags(self, tag_service):
        """创建示例标签数据"""
        tags = []
        tag_data = [
            {"name": "开发", "description": "开发环境", "color": "#3498db", "icon": "💻"},
            {"name": "测试", "description": "测试环境", "color": "#e74c3c", "icon": "🧪"},
            {"name": "生产", "description": "生产环境", "color": "#2ecc71", "icon": "🚀"},
        ]
        
        for data in tag_data:
            tag = tag_service.create_tag(**data)
            tags.append(tag)
        
        return tags

    # ==================== 标签系统高级功能测试 ====================

    def test_tag_advanced_operations(self, tag_service, sample_tags, sample_emails):
        """测试标签高级操作"""
        # 使用实际存在的邮箱ID
        email_id = sample_emails[0].id

        # 测试标签关联邮箱
        success = tag_service.add_tag_to_email(email_id, sample_tags[0].id)
        assert success

        # 测试批量添加标签
        result = tag_service.batch_add_tags_to_email(email_id, [tag.id for tag in sample_tags])
        assert result["success"] > 0
        
        # 测试标签使用详情
        details = tag_service.get_tag_usage_details(sample_tags[0].id)
        assert "tag" in details
        assert "usage" in details
        
        # 测试未使用标签
        unused_tags = tag_service.get_unused_tags()
        assert isinstance(unused_tags, list)

    def test_tag_pagination(self, tag_service, sample_tags):
        """测试标签分页功能"""
        result = tag_service.get_tags_with_pagination(
            page=1, 
            page_size=2, 
            keyword="测试",
            sort_by="name",
            sort_order="asc"
        )
        
        assert "tags" in result
        assert "pagination" in result
        assert result["pagination"]["page_size"] == 2
        assert result["pagination"]["current_page"] == 1

    def test_tag_export(self, tag_service, sample_tags):
        """测试标签导出功能"""
        # JSON导出
        json_data = tag_service.export_tags("json", include_usage=True)
        assert json_data
        assert "开发" in json_data
        
        # CSV导出
        csv_data = tag_service.export_tags("csv", include_usage=True)
        assert csv_data
        assert "name" in csv_data

    def test_tag_merge(self, tag_service, sample_tags):
        """测试标签合并功能"""
        # 创建额外标签用于合并
        extra_tag = tag_service.create_tag("临时标签", "用于合并测试")
        assert extra_tag
        
        # 合并标签
        success = tag_service.merge_tags(extra_tag.id, sample_tags[0].id, delete_source=True)
        assert success

    # ==================== 搜索和筛选功能测试 ====================

    def test_advanced_email_search(self, email_service, sample_emails):
        """测试高级邮箱搜索"""
        result = email_service.advanced_search_emails(
            keyword="test",
            domain="test-phase3a.com",
            tags=["test"],
            page=1,
            page_size=5,
            sort_by="created_at",
            sort_order="desc"
        )
        
        assert "emails" in result
        assert "pagination" in result
        assert len(result["emails"]) <= 5
        assert result["pagination"]["total_items"] > 0

    def test_email_search_by_multiple_tags(self, email_service, sample_emails):
        """测试多标签搜索"""
        # 包含任一标签
        emails = email_service.get_emails_by_multiple_tags(["tag0", "tag1"], match_all=False)
        assert len(emails) > 0
        
        # 包含所有标签
        emails = email_service.get_emails_by_multiple_tags(["test"], match_all=True)
        assert len(emails) > 0

    def test_email_search_by_date_range(self, email_service, sample_emails):
        """测试日期范围搜索"""
        today = datetime.now().strftime("%Y-%m-%d")
        yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
        
        emails = email_service.get_emails_by_date_range(yesterday, today)
        assert len(emails) > 0

    def test_email_statistics_by_period(self, email_service, sample_emails):
        """测试时间段统计"""
        stats = email_service.get_email_statistics_by_period("day", limit=7)
        assert isinstance(stats, list)
        
        if stats:
            assert "period" in stats[0]
            assert "total_count" in stats[0]

    # ==================== 数据导出功能测试 ====================

    def test_export_service_all_data(self, export_service, email_service, tag_service, sample_emails, sample_tags):
        """测试导出所有数据"""
        export_service.set_services(email_service, tag_service)
        
        # JSON导出
        json_data = export_service.export_all_data("json")
        assert json_data
        data = json.loads(json_data)
        assert "emails" in data
        assert "tags" in data
        assert "statistics" in data

    def test_export_with_templates(self, export_service, email_service, sample_emails):
        """测试模板导出"""
        export_service.set_services(email_service, None)
        
        # 简单模板
        simple_data = export_service.export_emails_with_template("simple")
        assert simple_data
        
        # 详细模板
        detailed_data = export_service.export_emails_with_template("detailed")
        assert detailed_data
        
        # 报告模板
        report_data = export_service.export_emails_with_template("report")
        assert report_data

    def test_advanced_email_export(self, email_service, sample_emails):
        """测试高级邮箱导出"""
        # JSON导出
        json_data = email_service.export_emails_advanced(
            format_type="json",
            fields=["id", "email_address", "domain", "status"],
            include_tags=True
        )
        assert json_data
        
        # CSV导出
        csv_data = email_service.export_emails_advanced(
            format_type="csv",
            fields=["id", "email_address", "domain"],
            include_tags=True
        )
        assert csv_data

    # ==================== 批量操作功能测试 ====================

    def test_batch_create_emails(self, batch_service):
        """测试批量创建邮箱"""
        result = batch_service.batch_create_emails(
            count=5,
            prefix_type="sequence",
            base_prefix="batch_test",
            tags=["批量测试"],
            notes="批量创建测试"
        )
        
        assert result["total"] == 5
        assert result["success"] > 0
        assert len(result["emails"]) == result["success"]

    def test_batch_update_emails(self, batch_service, sample_emails):
        """测试批量更新邮箱"""
        email_ids = [email.id for email in sample_emails[:3]]
        
        result = batch_service.batch_update_emails(
            email_ids,
            {"status": "inactive", "notes": "批量更新测试"}
        )
        
        assert result["total"] == 3
        assert result["success"] > 0

    def test_batch_delete_emails(self, batch_service, sample_emails):
        """测试批量删除邮箱"""
        email_ids = [email.id for email in sample_emails[-2:]]
        
        result = batch_service.batch_delete_emails(email_ids, hard_delete=False)
        
        assert result["total"] == 2
        assert result["success"] > 0

    def test_batch_apply_tags(self, batch_service, sample_emails, sample_tags):
        """测试批量应用标签"""
        email_ids = [email.id for email in sample_emails[:3]]
        tag_names = [tag.name for tag in sample_tags[:2]]
        
        result = batch_service.batch_apply_tags(email_ids, tag_names, "add")
        
        assert result["total_emails"] == 3
        assert result["success_emails"] > 0

    def test_batch_create_tags(self, batch_service):
        """测试批量创建标签"""
        tag_data_list = [
            {"name": "批量标签1", "description": "批量创建测试1", "color": "#ff0000"},
            {"name": "批量标签2", "description": "批量创建测试2", "color": "#00ff00"},
            {"name": "批量标签3", "description": "批量创建测试3", "color": "#0000ff"},
        ]
        
        result = batch_service.batch_create_tags(tag_data_list)
        
        assert result["total"] == 3
        assert result["success"] > 0

    def test_batch_import_emails(self, batch_service):
        """测试批量导入邮箱"""
        import_data = [
            {
                "email_address": "import1@test.com",
                "tags": ["导入测试"],
                "notes": "导入测试1",
                "status": "active"
            },
            {
                "email_address": "import2@test.com",
                "tags": ["导入测试"],
                "notes": "导入测试2",
                "status": "active"
            }
        ]
        
        result = batch_service.batch_import_emails_from_data(import_data, "skip")
        
        assert result["total"] == 2
        assert result["success"] > 0

    # ==================== 安全功能测试 ====================

    def test_encryption_manager(self):
        """测试加密管理器"""
        encryption_manager = EncryptionManager("test_password")

        # 测试加密解密
        original_data = "敏感数据测试"
        encrypted_data = encryption_manager.encrypt(original_data)
        assert encrypted_data != original_data
        assert encryption_manager.is_encrypted(encrypted_data)

        decrypted_data = encryption_manager.decrypt(encrypted_data)
        assert decrypted_data == original_data

    def test_secure_memory_manager(self):
        """测试安全内存管理器"""
        memory_manager = SecureMemoryManager()

        # 注册敏感变量
        memory_manager.register_sensitive_var("test_var")

        # 清理内存
        memory_manager.clear_sensitive_memory()

        # 安全删除字符串
        test_string = "敏感字符串"
        memory_manager.secure_delete_string(test_string)

    def test_log_sanitizer(self):
        """测试日志脱敏器"""
        sanitizer = LogSanitizer()

        # 测试消息脱敏
        sensitive_message = "password=secret123 token=abc123 email=test@example.com"
        sanitized = sanitizer.sanitize_log_message(sensitive_message)
        assert "secret123" not in sanitized
        assert "abc123" not in sanitized
        assert "***" in sanitized

        # 测试字典脱敏
        sensitive_dict = {
            "username": "testuser",
            "password": "secret123",
            "email": "test@example.com",
            "token": "abc123"
        }
        sanitized_dict = sanitizer.sanitize_dict(sensitive_dict)
        assert sanitized_dict["username"] == "testuser"
        assert sanitized_dict["password"] == "***"
        assert sanitized_dict["token"] == "***"

    def test_secure_config_manager(self):
        """测试安全配置管理器"""
        encryption_manager = EncryptionManager("test_password")
        config_manager = SecureConfigManager(encryption_manager)

        # 测试配置段加密
        config_data = {
            "database": {
                "host": "localhost",
                "password": "db_secret"
            },
            "api": {
                "key": "api_secret",
                "url": "https://api.example.com"
            }
        }

        # 加密敏感配置段
        encrypted_config = config_manager.encrypt_config_section(config_data.copy(), "database")
        assert encrypted_config["database"]["password"] != "db_secret"

        # 解密配置段
        decrypted_config = config_manager.decrypt_config_section(encrypted_config, "database")
        assert decrypted_config["database"]["password"] == "db_secret"

        # 安全记录配置
        safe_config = config_manager.secure_log_config(config_data)
        assert safe_config["database"]["password"] == "***"

    def test_sanitize_for_log_function(self):
        """测试日志脱敏便捷函数"""
        # 测试字符串脱敏
        sensitive_string = "password=secret123"
        sanitized = sanitize_for_log(sensitive_string)
        assert "secret123" not in sanitized

        # 测试字典脱敏
        sensitive_dict = {"password": "secret123", "username": "test"}
        sanitized = sanitize_for_log(sensitive_dict)
        assert "secret123" not in sanitized
        assert "test" in sanitized

    # ==================== 集成测试 ====================

    def test_integration_advanced_workflow(self, db_service, test_config):
        """测试高级功能集成工作流"""
        # 初始化所有服务
        tag_service = TagService(db_service)
        email_service = EmailService(test_config, db_service)
        export_service = ExportService(db_service)
        batch_service = BatchService(db_service, test_config)

        export_service.set_services(email_service, tag_service)

        # 1. 批量创建标签
        tag_data = [
            {"name": "集成测试1", "description": "集成测试标签1"},
            {"name": "集成测试2", "description": "集成测试标签2"}
        ]
        tag_result = batch_service.batch_create_tags(tag_data)
        assert tag_result["success"] == 2

        # 2. 批量创建邮箱
        email_result = batch_service.batch_create_emails(
            count=5,
            prefix_type="sequence",
            base_prefix="integration",
            tags=["集成测试1", "集成测试2"]
        )
        assert email_result["success"] == 5

        # 3. 高级搜索
        search_result = email_service.advanced_search_emails(
            keyword="integration",
            tags=["集成测试1"],
            page=1,
            page_size=10
        )
        assert len(search_result["emails"]) > 0

        # 4. 导出数据
        export_data = export_service.export_all_data("json")
        assert export_data

        # 5. 标签统计
        tag_stats = tag_service.get_tag_statistics()
        assert tag_stats["total_tags"] >= 2

        # 6. 邮箱统计
        email_stats = email_service.get_statistics()
        assert email_stats["total_emails"] >= 5

    def test_performance_batch_operations(self, batch_service):
        """测试批量操作性能"""
        import time

        # 测试大批量创建邮箱的性能
        start_time = time.time()

        result = batch_service.batch_create_emails(
            count=50,
            prefix_type="sequence",
            base_prefix="perf_test",
            tags=["性能测试"]
        )

        end_time = time.time()
        duration = end_time - start_time

        assert result["success"] == 50
        assert duration < 10  # 应该在10秒内完成

        print(f"批量创建50个邮箱耗时: {duration:.2f}秒")

    def test_error_handling(self, tag_service, email_service, batch_service):
        """测试错误处理"""
        # 测试创建重复标签
        tag1 = tag_service.create_tag("重复标签测试")
        assert tag1 is not None

        tag2 = tag_service.create_tag("重复标签测试")  # 应该失败
        assert tag2 is None

        # 测试批量操作错误处理
        result = batch_service.batch_update_emails(
            [99999],  # 不存在的邮箱ID
            {"status": "active"}
        )
        assert result["failed"] > 0
        assert len(result["errors"]) > 0

    def test_data_consistency(self, db_service, email_service, tag_service):
        """测试数据一致性"""
        # 创建邮箱和标签
        email = email_service.create_email(
            prefix_type="custom",
            custom_prefix="consistency_test",
            tags=["一致性测试"]
        )
        assert email is not None

        # 验证标签关联
        email_tags = tag_service.get_tags_by_email(email.id)
        assert len(email_tags) > 0
        assert any(tag.name == "一致性测试" for tag in email_tags)

        # 删除邮箱
        success = email_service.delete_email(email.id)
        assert success

        # 验证邮箱已被软删除
        deleted_email = email_service.get_email_by_id(email.id)
        assert deleted_email is None  # 软删除后应该查询不到


# ==================== 运行测试的主函数 ====================

def run_phase3a_tests():
    """运行Phase 3A所有测试"""
    import subprocess
    import sys

    try:
        print("🚀 开始运行Phase 3A高级功能测试...")

        # 运行测试
        result = subprocess.run([
            sys.executable, "-m", "pytest",
            __file__,
            "-v",
            "--tb=short"
        ], capture_output=True, text=True)

        print("📊 测试结果:")
        print(result.stdout)

        if result.stderr:
            print("⚠️ 警告信息:")
            print(result.stderr)

        if result.returncode == 0:
            print("✅ Phase 3A所有测试通过！")
            print("\n🎉 验收标准达成:")
            print("   • 标签系统高级功能正常工作")
            print("   • 搜索和筛选功能完整实现")
            print("   • 数据导出功能支持多种格式")
            print("   • 批量操作功能稳定可靠")
            print("   • 安全机制有效保护敏感数据")
            return True
        else:
            print("❌ 部分测试失败")
            return False

    except Exception as e:
        print(f"❌ 测试运行失败: {e}")
        return False


if __name__ == "__main__":
    success = run_phase3a_tests()
    sys.exit(0 if success else 1)
