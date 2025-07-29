#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - Phase 3A 功能验证脚本
验证高级后端功能的完整性和正确性
"""

import sys
import tempfile
from pathlib import Path
from datetime import datetime

# 添加src目录到Python路径
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

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


def test_tag_advanced_features(tag_service: TagService) -> bool:
    """测试标签高级功能"""
    try:
        print("🏷️ 测试标签高级功能...")
        
        # 1. 创建测试标签
        tag1 = tag_service.create_tag("Phase3A测试", "高级功能测试标签", "#e74c3c", "🧪")
        assert tag1 is not None, "创建标签失败"
        print(f"✅ 创建标签成功: {tag1.name}")
        
        # 2. 测试标签分页
        result = tag_service.get_tags_with_pagination(page=1, page_size=5)
        assert "tags" in result, "标签分页失败"
        assert "pagination" in result, "分页信息缺失"
        print(f"✅ 标签分页成功，共 {result['pagination']['total_items']} 个标签")
        
        # 3. 测试标签导出
        json_data = tag_service.export_tags("json", include_usage=True)
        assert json_data, "标签JSON导出失败"
        print("✅ 标签JSON导出成功")
        
        csv_data = tag_service.export_tags("csv", include_usage=True)
        assert csv_data, "标签CSV导出失败"
        print("✅ 标签CSV导出成功")
        
        # 4. 测试标签统计
        stats = tag_service.get_tag_statistics()
        assert stats.get("total_tags", 0) > 0, "标签统计失败"
        print(f"✅ 标签统计成功，总标签数: {stats['total_tags']}")
        
        return True
        
    except Exception as e:
        print(f"❌ 标签高级功能测试失败: {e}")
        return False


def test_email_search_features(email_service: EmailService) -> bool:
    """测试邮箱搜索功能"""
    try:
        print("🔍 测试邮箱搜索功能...")
        
        # 1. 创建测试邮箱
        email1 = email_service.create_email(
            prefix_type="custom",
            custom_prefix="search_test1",
            tags=["搜索测试", "Phase3A"],
            notes="搜索功能测试邮箱1"
        )
        assert email1 is not None, "创建测试邮箱失败"
        
        email2 = email_service.create_email(
            prefix_type="custom",
            custom_prefix="search_test2",
            tags=["搜索测试"],
            notes="搜索功能测试邮箱2"
        )
        assert email2 is not None, "创建测试邮箱失败"
        print("✅ 创建测试邮箱成功")
        
        # 2. 测试高级搜索
        search_result = email_service.advanced_search_emails(
            keyword="search_test",
            tags=["搜索测试"],
            page=1,
            page_size=10,
            sort_by="created_at",
            sort_order="desc"
        )
        assert len(search_result["emails"]) >= 2, "高级搜索结果不正确"
        print(f"✅ 高级搜索成功，找到 {len(search_result['emails'])} 个邮箱")
        
        # 3. 测试多标签搜索
        multi_tag_emails = email_service.get_emails_by_multiple_tags(
            ["搜索测试", "Phase3A"], 
            match_all=False
        )
        assert len(multi_tag_emails) >= 2, "多标签搜索失败"
        print(f"✅ 多标签搜索成功，找到 {len(multi_tag_emails)} 个邮箱")
        
        # 4. 测试日期范围搜索
        today = datetime.now().strftime("%Y-%m-%d")
        date_emails = email_service.get_emails_by_date_range(today, today)
        assert len(date_emails) >= 2, "日期范围搜索失败"
        print(f"✅ 日期范围搜索成功，找到 {len(date_emails)} 个邮箱")
        
        # 5. 测试统计功能
        stats = email_service.get_email_statistics_by_period("day", limit=7)
        assert isinstance(stats, list), "统计功能失败"
        print("✅ 邮箱统计功能正常")
        
        return True
        
    except Exception as e:
        print(f"❌ 邮箱搜索功能测试失败: {e}")
        return False


def test_export_features(export_service: ExportService, email_service: EmailService, tag_service: TagService) -> bool:
    """测试数据导出功能"""
    try:
        print("📤 测试数据导出功能...")
        
        # 设置服务依赖
        export_service.set_services(email_service, tag_service)
        
        # 1. 测试全量数据导出
        json_data = export_service.export_all_data("json")
        assert json_data, "JSON全量导出失败"
        print("✅ JSON全量数据导出成功")
        
        csv_data = export_service.export_all_data("csv")
        assert csv_data, "CSV全量导出失败"
        print("✅ CSV全量数据导出成功")
        
        # 2. 测试模板导出
        simple_data = export_service.export_emails_with_template("simple")
        assert simple_data, "简单模板导出失败"
        print("✅ 简单模板导出成功")
        
        detailed_data = export_service.export_emails_with_template("detailed")
        assert detailed_data, "详细模板导出失败"
        print("✅ 详细模板导出成功")
        
        report_data = export_service.export_emails_with_template("report")
        assert report_data, "报告模板导出失败"
        print("✅ 报告模板导出成功")
        
        # 3. 测试高级邮箱导出
        advanced_json = email_service.export_emails_advanced(
            format_type="json",
            fields=["id", "email_address", "domain", "status"],
            include_tags=True
        )
        assert advanced_json, "高级JSON导出失败"
        print("✅ 高级JSON导出成功")
        
        return True
        
    except Exception as e:
        print(f"❌ 数据导出功能测试失败: {e}")
        return False


def test_batch_operations(batch_service: BatchService) -> bool:
    """测试批量操作功能"""
    try:
        print("⚡ 测试批量操作功能...")
        
        # 1. 批量创建邮箱
        email_result = batch_service.batch_create_emails(
            count=5,
            prefix_type="sequence",
            base_prefix="batch_test",
            tags=["批量测试", "Phase3A"],
            notes="批量创建测试"
        )
        assert email_result["success"] == 5, f"批量创建邮箱失败: {email_result}"
        print(f"✅ 批量创建邮箱成功，创建了 {email_result['success']} 个邮箱")
        
        # 2. 批量创建标签
        tag_data = [
            {"name": "批量标签1", "description": "批量创建测试1", "color": "#ff0000"},
            {"name": "批量标签2", "description": "批量创建测试2", "color": "#00ff00"},
            {"name": "批量标签3", "description": "批量创建测试3", "color": "#0000ff"},
        ]
        tag_result = batch_service.batch_create_tags(tag_data)
        assert tag_result["success"] == 3, f"批量创建标签失败: {tag_result}"
        print(f"✅ 批量创建标签成功，创建了 {tag_result['success']} 个标签")
        
        # 3. 批量更新邮箱
        email_ids = [email.id for email in email_result["emails"][:3]]
        update_result = batch_service.batch_update_emails(
            email_ids,
            {"status": "inactive", "notes": "批量更新测试"}
        )
        assert update_result["success"] == 3, f"批量更新邮箱失败: {update_result}"
        print(f"✅ 批量更新邮箱成功，更新了 {update_result['success']} 个邮箱")
        
        # 4. 批量应用标签
        tag_names = ["批量标签1", "批量标签2"]
        tag_apply_result = batch_service.batch_apply_tags(email_ids, tag_names, "add")
        assert tag_apply_result["success_emails"] == 3, f"批量应用标签失败: {tag_apply_result}"
        print(f"✅ 批量应用标签成功，为 {tag_apply_result['success_emails']} 个邮箱应用了标签")
        
        # 5. 批量导入邮箱
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
        import_result = batch_service.batch_import_emails_from_data(import_data, "skip")
        assert import_result["success"] == 2, f"批量导入邮箱失败: {import_result}"
        print(f"✅ 批量导入邮箱成功，导入了 {import_result['success']} 个邮箱")
        
        return True
        
    except Exception as e:
        print(f"❌ 批量操作功能测试失败: {e}")
        return False


def test_security_features() -> bool:
    """测试安全功能"""
    try:
        print("🔒 测试安全功能...")
        
        # 1. 测试加密管理器
        encryption_manager = EncryptionManager("test_password_phase3a")
        original_data = "敏感数据测试Phase3A"
        encrypted_data = encryption_manager.encrypt(original_data)
        assert encrypted_data != original_data, "数据加密失败"
        
        decrypted_data = encryption_manager.decrypt(encrypted_data)
        assert decrypted_data == original_data, "数据解密失败"
        print("✅ 加密解密功能正常")
        
        # 2. 测试日志脱敏
        sanitizer = LogSanitizer()
        sensitive_message = "password=secret123 token=abc123 email=test@example.com"
        sanitized = sanitizer.sanitize_log_message(sensitive_message)
        assert "secret123" not in sanitized, "日志脱敏失败"
        assert "***" in sanitized, "脱敏标记缺失"
        print("✅ 日志脱敏功能正常")
        
        # 3. 测试安全配置管理
        config_manager = SecureConfigManager(encryption_manager)
        config_data = {
            "database": {
                "host": "localhost",
                "password": "db_secret"
            }
        }
        
        encrypted_config = config_manager.encrypt_config_section(config_data.copy(), "database")
        assert encrypted_config["database"]["password"] != "db_secret", "配置加密失败"
        
        decrypted_config = config_manager.decrypt_config_section(encrypted_config, "database")
        assert decrypted_config["database"]["password"] == "db_secret", "配置解密失败"
        print("✅ 安全配置管理功能正常")
        
        # 4. 测试内存管理
        memory_manager = SecureMemoryManager()
        memory_manager.register_sensitive_var("test_var")
        memory_manager.clear_sensitive_memory()
        print("✅ 安全内存管理功能正常")
        
        # 5. 测试便捷函数
        sanitized_log = sanitize_for_log({"password": "secret", "username": "test"})
        assert "secret" not in sanitized_log, "便捷脱敏函数失败"
        print("✅ 便捷安全函数正常")
        
        return True
        
    except Exception as e:
        print(f"❌ 安全功能测试失败: {e}")
        return False


def main() -> bool:
    """主测试函数"""
    try:
        print("🚀 开始Phase 3A高级功能验证...")
        print("=" * 60)
        
        # 创建临时数据库
        with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
            db_path = Path(f.name)
        
        try:
            # 初始化服务
            db_service = DatabaseService(db_path)
            db_service.init_database()
            
            config = ConfigModel()
            config.domain_config = DomainConfig(domain="phase3a-test.com")
            
            tag_service = TagService(db_service)
            email_service = EmailService(config, db_service)
            export_service = ExportService(db_service)
            batch_service = BatchService(db_service, config)
            
            # 运行测试
            test_results = []
            
            # 1. 标签高级功能测试
            test_results.append(("标签高级功能", test_tag_advanced_features(tag_service)))
            
            # 2. 邮箱搜索功能测试
            test_results.append(("邮箱搜索功能", test_email_search_features(email_service)))
            
            # 3. 数据导出功能测试
            test_results.append(("数据导出功能", test_export_features(export_service, email_service, tag_service)))
            
            # 4. 批量操作功能测试
            test_results.append(("批量操作功能", test_batch_operations(batch_service)))
            
            # 5. 安全功能测试
            test_results.append(("安全功能", test_security_features()))
            
            # 统计结果
            print("\n" + "=" * 60)
            print("📊 Phase 3A 功能验证结果:")
            print("=" * 60)
            
            passed = 0
            total = len(test_results)
            
            for test_name, result in test_results:
                status = "✅ 通过" if result else "❌ 失败"
                print(f"{test_name:<20}: {status}")
                if result:
                    passed += 1
            
            print(f"\n总计: {passed}/{total} 项测试通过")
            
            if passed == total:
                print("\n🎉 Phase 3A 所有功能验证通过！")
                print("\n✅ 验收标准达成:")
                print("   • 标签系统的完整后端逻辑实现完成")
                print("   • 搜索和筛选功能的后端查询接口正常工作")
                print("   • 数据导出功能支持CSV/JSON格式")
                print("   • 批量操作的后端接口稳定可靠")
                print("   • 配置文件加密和敏感数据保护机制有效")
                print("   • 所有功能符合安全性设计要求")
                return True
            else:
                print(f"\n❌ 有 {total - passed} 项功能验证失败")
                return False
                
        finally:
            try:
                db_service.close()
                if db_path.exists():
                    db_path.unlink()
            except:
                pass
        
    except Exception as e:
        print(f"❌ Phase 3A功能验证过程中发生错误: {e}")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
