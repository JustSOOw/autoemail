#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2A 功能测试脚本
测试核心业务逻辑与数据持久化功能
"""

import sys
import tempfile
from pathlib import Path

# 添加src目录到Python路径
current_dir = Path(__file__).parent.parent
sys.path.insert(0, str(current_dir / "src"))

from models.email_model import EmailModel, EmailStatus, create_email_model
from models.config_model import ConfigModel
from models.tag_model import TagModel, create_tag_model
from services.database_service import DatabaseService
from services.email_service import EmailService
from services.config_service import ConfigService
from services.tag_service import TagService
from utils.logger import setup_logger, get_logger


def print_separator(title: str):
    """打印分隔符"""
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)


def test_email_service(email_service: EmailService) -> bool:
    """测试邮箱服务功能"""
    try:
        print("📧 测试邮箱服务功能...")
        
        # 1. 创建邮箱
        email1 = email_service.create_email(
            prefix_type="random_name",
            tags=["测试", "Phase2A"],
            notes="Phase 2A 测试邮箱"
        )
        assert email1 is not None, "创建邮箱失败"
        print(f"✅ 创建邮箱成功: {email1.email_address}")
        
        # 2. 根据ID获取邮箱
        retrieved_email = email_service.get_email_by_id(email1.id)
        assert retrieved_email is not None, "根据ID获取邮箱失败"
        assert retrieved_email.email_address == email1.email_address, "邮箱地址不匹配"
        print("✅ 根据ID获取邮箱成功")
        
        # 3. 搜索邮箱
        search_results = email_service.search_emails(keyword="Phase2A")
        assert len(search_results) > 0, "搜索邮箱失败"
        print(f"✅ 搜索邮箱成功，找到 {len(search_results)} 个结果")
        
        # 4. 更新邮箱状态
        email1.archive()
        update_success = email_service.update_email(email1)
        assert update_success, "更新邮箱状态失败"
        print("✅ 更新邮箱状态成功")
        
        # 5. 批量创建邮箱
        batch_emails = email_service.batch_create_emails(
            count=3,
            prefix_type="sequence",
            base_prefix="batch_test",
            tags=["批量测试"],
            notes="批量创建测试"
        )
        assert len(batch_emails) == 3, "批量创建邮箱失败"
        print(f"✅ 批量创建邮箱成功，创建了 {len(batch_emails)} 个邮箱")
        
        # 6. 获取统计信息
        stats = email_service.get_statistics()
        assert stats.get("total_emails", 0) > 0, "获取统计信息失败"
        print(f"✅ 获取统计信息成功，总邮箱数: {stats.get('total_emails', 0)}")
        
        # 7. 导出数据
        json_data = email_service.export_emails(format_type="json")
        assert len(json_data) > 0, "导出JSON数据失败"
        print("✅ 导出JSON数据成功")
        
        csv_data = email_service.export_emails(format_type="csv")
        assert len(csv_data) > 0, "导出CSV数据失败"
        print("✅ 导出CSV数据成功")
        
        return True
        
    except Exception as e:
        print(f"❌ 邮箱服务测试失败: {e}")
        return False


def test_config_service(config_service: ConfigService) -> bool:
    """测试配置服务功能"""
    try:
        print("⚙️ 测试配置服务功能...")
        
        # 1. 加载默认配置
        config = config_service.load_config()
        assert config is not None, "加载配置失败"
        print("✅ 加载默认配置成功")
        
        # 2. 更新域名配置
        success = config_service.update_domain_config("test-domain.com", True)
        assert success, "更新域名配置失败"
        print("✅ 更新域名配置成功")
        
        # 3. 设置配置值
        success = config_service.set_config_value("test.key", "test_value")
        assert success, "设置配置值失败"
        print("✅ 设置配置值成功")
        
        # 4. 获取配置值
        value = config_service.get_config_value("test.key")
        assert value == "test_value", "获取配置值失败"
        print("✅ 获取配置值成功")
        
        # 5. 获取配置摘要
        summary = config_service.get_config_summary()
        assert isinstance(summary, dict), "获取配置摘要失败"
        print("✅ 获取配置摘要成功")
        
        # 6. 导出配置
        exported_config = config_service.export_config()
        assert len(exported_config) > 0, "导出配置失败"
        print("✅ 导出配置成功")
        
        # 7. 验证配置
        errors = config_service.validate_config(config)
        assert isinstance(errors, dict), "验证配置失败"
        print("✅ 验证配置成功")
        
        return True
        
    except Exception as e:
        print(f"❌ 配置服务测试失败: {e}")
        return False


def test_tag_service(tag_service: TagService) -> bool:
    """测试标签服务功能"""
    try:
        print("🏷️ 测试标签服务功能...")
        
        # 1. 创建标签
        tag1 = tag_service.create_tag(
            name="Phase2A测试",
            description="Phase 2A 功能测试标签",
            color="#e74c3c",
            icon="🧪"
        )
        assert tag1 is not None, "创建标签失败"
        print(f"✅ 创建标签成功: {tag1.name}")
        
        # 2. 根据ID获取标签
        retrieved_tag = tag_service.get_tag_by_id(tag1.id)
        assert retrieved_tag is not None, "根据ID获取标签失败"
        assert retrieved_tag.name == tag1.name, "标签名称不匹配"
        print("✅ 根据ID获取标签成功")
        
        # 3. 根据名称获取标签
        tag_by_name = tag_service.get_tag_by_name(tag1.name)
        assert tag_by_name is not None, "根据名称获取标签失败"
        print("✅ 根据名称获取标签成功")
        
        # 4. 获取所有标签
        all_tags = tag_service.get_all_tags()
        assert len(all_tags) > 0, "获取所有标签失败"
        print(f"✅ 获取所有标签成功，共 {len(all_tags)} 个标签")
        
        # 5. 搜索标签
        search_results = tag_service.search_tags("Phase2A")
        assert len(search_results) > 0, "搜索标签失败"
        print(f"✅ 搜索标签成功，找到 {len(search_results)} 个结果")
        
        # 6. 更新标签
        tag1.description = "更新后的描述"
        update_success = tag_service.update_tag(tag1)
        assert update_success, "更新标签失败"
        print("✅ 更新标签成功")
        
        # 7. 批量创建标签
        batch_tag_data = [
            {"name": "批量测试1", "description": "批量创建测试1", "color": "#3498db"},
            {"name": "批量测试2", "description": "批量创建测试2", "color": "#2ecc71"},
            {"name": "批量测试3", "description": "批量创建测试3", "color": "#f39c12"}
        ]
        batch_tags = tag_service.batch_create_tags(batch_tag_data)
        assert len(batch_tags) == 3, "批量创建标签失败"
        print(f"✅ 批量创建标签成功，创建了 {len(batch_tags)} 个标签")
        
        # 8. 获取标签统计
        stats = tag_service.get_tag_statistics()
        assert stats.get("total_tags", 0) > 0, "获取标签统计失败"
        print(f"✅ 获取标签统计成功，总标签数: {stats.get('total_tags', 0)}")
        
        return True
        
    except Exception as e:
        print(f"❌ 标签服务测试失败: {e}")
        return False


def test_database_service(db_service: DatabaseService) -> bool:
    """测试数据库服务功能"""
    try:
        print("🗄️ 测试数据库服务功能...")
        
        # 1. 获取数据库统计
        stats = db_service.get_database_stats()
        assert isinstance(stats, dict), "获取数据库统计失败"
        print("✅ 获取数据库统计成功")
        
        # 2. 获取连接信息
        conn_info = db_service.get_connection_info()
        assert isinstance(conn_info, dict), "获取连接信息失败"
        print("✅ 获取连接信息成功")
        
        # 3. 检查数据库完整性
        integrity = db_service.check_database_integrity()
        assert integrity.get("status") == "ok", f"数据库完整性检查失败: {integrity}"
        print("✅ 数据库完整性检查通过")
        
        # 4. 优化数据库
        optimize_success = db_service.optimize_database()
        assert optimize_success, "数据库优化失败"
        print("✅ 数据库优化成功")
        
        return True
        
    except Exception as e:
        print(f"❌ 数据库服务测试失败: {e}")
        return False


def main():
    """主测试函数"""
    setup_logger(level='INFO')
    logger = get_logger(__name__)
    
    print_separator("Phase 2A 功能测试")
    print("测试核心业务逻辑与数据持久化功能")
    
    # 创建临时数据库
    with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
        db_path = Path(f.name)
    
    test_results = []
    
    try:
        # 初始化服务
        print_separator("初始化服务")
        
        db_service = DatabaseService(db_path)
        db_service.init_database()
        print("✅ 数据库服务初始化完成")
        
        config = ConfigModel()
        config.domain_config.domain = "phase2a-test.com"
        
        email_service = EmailService(config, db_service)
        config_service = ConfigService(db_service)
        tag_service = TagService(db_service)
        print("✅ 所有服务初始化完成")
        
        # 运行测试
        print_separator("运行功能测试")
        
        test_results.append(("EmailService", test_email_service(email_service)))
        test_results.append(("ConfigService", test_config_service(config_service)))
        test_results.append(("TagService", test_tag_service(tag_service)))
        test_results.append(("DatabaseService", test_database_service(db_service)))
        
        # 输出测试结果
        print_separator("测试结果汇总")
        
        passed = 0
        total = len(test_results)
        
        for service_name, result in test_results:
            status = "✅ 通过" if result else "❌ 失败"
            print(f"{service_name:<20}: {status}")
            if result:
                passed += 1
        
        print(f"\n总计: {passed}/{total} 项测试通过")
        
        if passed == total:
            print("🎉 Phase 2A 所有功能测试通过！")
            print("\n✅ 验收标准达成:")
            print("   • 可以成功生成域名邮箱并保存到数据库")
            print("   • 配置可以正确保存和加载，并能通过API进行管理")
            print("   • 邮箱和标签记录可以正确存储、查询和更新")
            print("   • 数据库操作稳定，性能良好")
            return True
        else:
            print(f"❌ 有 {total - passed} 项测试失败")
            return False
        
    except Exception as e:
        print(f"❌ 测试过程中发生错误: {e}")
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
