#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 基础功能测试
测试核心模块的基本功能
"""

import sys
import unittest
import tempfile
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root / "src"))

from models.email_model import EmailModel, VerificationStatus, VerificationMethod
from models.config_model import ConfigModel
from models.tag_model import TagModel
from services.database_service import DatabaseService
from utils.config_manager import ConfigManager


class TestEmailModel(unittest.TestCase):
    """测试邮箱数据模型"""
    
    def test_email_model_creation(self):
        """测试邮箱模型创建"""
        email = EmailModel(
            email_address="test@example.com",
            notes="测试邮箱"
        )
        
        self.assertEqual(email.email_address, "test@example.com")
        self.assertEqual(email.domain, "example.com")
        self.assertEqual(email.prefix, "test")
        self.assertEqual(email.notes, "测试邮箱")
        self.assertEqual(email.verification_status, VerificationStatus.PENDING)
        self.assertIsNotNone(email.created_at)
    
    def test_email_model_tags(self):
        """测试邮箱标签功能"""
        email = EmailModel(email_address="test@example.com")
        
        # 添加标签
        self.assertTrue(email.add_tag("测试用"))
        self.assertTrue(email.add_tag("开发用"))
        self.assertFalse(email.add_tag("测试用"))  # 重复添加
        
        # 检查标签
        self.assertTrue(email.has_tag("测试用"))
        self.assertTrue(email.has_tag("开发用"))
        self.assertFalse(email.has_tag("生产用"))
        
        # 移除标签
        self.assertTrue(email.remove_tag("测试用"))
        self.assertFalse(email.has_tag("测试用"))
        self.assertFalse(email.remove_tag("不存在的标签"))
    
    def test_email_model_serialization(self):
        """测试邮箱模型序列化"""
        email = EmailModel(
            email_address="test@example.com",
            tags=["测试用", "开发用"],
            notes="测试邮箱"
        )
        
        # 转换为字典
        email_dict = email.to_dict()
        self.assertIsInstance(email_dict, dict)
        self.assertEqual(email_dict['email_address'], "test@example.com")
        self.assertEqual(email_dict['tags'], ["测试用", "开发用"])
        
        # 从字典创建
        email2 = EmailModel.from_dict(email_dict)
        self.assertEqual(email2.email_address, email.email_address)
        self.assertEqual(email2.tags, email.tags)
        self.assertEqual(email2.notes, email.notes)
        
        # JSON序列化
        json_str = email.to_json()
        self.assertIsInstance(json_str, str)
        
        email3 = EmailModel.from_json(json_str)
        self.assertEqual(email3.email_address, email.email_address)


class TestConfigModel(unittest.TestCase):
    """测试配置数据模型"""
    
    def test_config_model_creation(self):
        """测试配置模型创建"""
        config = ConfigModel()
        
        self.assertIsNotNone(config.domain_config)
        self.assertIsNotNone(config.imap_config)
        self.assertIsNotNone(config.tempmail_config)
        self.assertIsNotNone(config.security_config)
        self.assertIsNotNone(config.system_config)
    
    def test_config_validation(self):
        """测试配置验证"""
        config = ConfigModel()
        
        # 空配置应该有错误
        errors = config.validate_config()
        self.assertIn("domain", errors)
        
        # 设置域名
        config.domain_config.domain = "example.com"
        config.verification_method = "tempmail"
        config.tempmail_config.username = "test"
        config.tempmail_config.epin = "123456"
        
        errors = config.validate_config()
        self.assertEqual(len(errors), 0)  # 应该没有错误
    
    def test_config_serialization(self):
        """测试配置序列化"""
        config = ConfigModel()
        config.domain_config.domain = "example.com"
        
        # 转换为字典
        config_dict = config.to_dict()
        self.assertIsInstance(config_dict, dict)
        self.assertEqual(config_dict['domain_config']['domain'], "example.com")
        
        # 从字典创建
        config2 = ConfigModel.from_dict(config_dict)
        self.assertEqual(config2.domain_config.domain, config.domain_config.domain)


class TestTagModel(unittest.TestCase):
    """测试标签数据模型"""
    
    def test_tag_model_creation(self):
        """测试标签模型创建"""
        tag = TagModel(
            name="测试标签",
            color="#ff0000",
            icon="🏷️",
            description="这是一个测试标签"
        )
        
        self.assertEqual(tag.name, "测试标签")
        self.assertEqual(tag.color, "#ff0000")
        self.assertEqual(tag.icon, "🏷️")
        self.assertEqual(tag.description, "这是一个测试标签")
        self.assertIsNotNone(tag.created_at)
    
    def test_tag_color_validation(self):
        """测试标签颜色验证"""
        # 有效颜色
        tag1 = TagModel(name="测试", color="#ff0000")
        self.assertEqual(tag1.color, "#ff0000")
        
        # 无效颜色，应该使用默认颜色
        tag2 = TagModel(name="测试", color="invalid")
        self.assertEqual(tag2.color, "#3498db")  # 默认颜色
    
    def test_tag_serialization(self):
        """测试标签序列化"""
        tag = TagModel(name="测试标签", color="#ff0000")
        
        # 转换为字典
        tag_dict = tag.to_dict()
        self.assertIsInstance(tag_dict, dict)
        self.assertEqual(tag_dict['name'], "测试标签")
        
        # 从字典创建
        tag2 = TagModel.from_dict(tag_dict)
        self.assertEqual(tag2.name, tag.name)
        self.assertEqual(tag2.color, tag.color)


class TestDatabaseService(unittest.TestCase):
    """测试数据库服务"""
    
    def setUp(self):
        """测试前准备"""
        # 创建临时数据库文件
        self.temp_dir = tempfile.mkdtemp()
        self.db_path = Path(self.temp_dir) / "test.db"
        self.db_service = DatabaseService(self.db_path)
    
    def tearDown(self):
        """测试后清理"""
        self.db_service.close()
        # 清理临时文件
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def test_database_initialization(self):
        """测试数据库初始化"""
        result = self.db_service.init_database()
        self.assertTrue(result)
        self.assertTrue(self.db_path.exists())
    
    def test_database_operations(self):
        """测试数据库基本操作"""
        # 初始化数据库
        self.db_service.init_database()
        
        # 插入测试数据
        result = self.db_service.execute_update(
            "INSERT INTO emails (email_address, domain, prefix) VALUES (?, ?, ?)",
            ("test@example.com", "example.com", "test")
        )
        self.assertEqual(result, 1)
        
        # 查询数据
        emails = self.db_service.execute_query(
            "SELECT * FROM emails WHERE email_address = ?",
            ("test@example.com",)
        )
        self.assertEqual(len(emails), 1)
        self.assertEqual(emails[0]['email_address'], "test@example.com")
    
    def test_database_stats(self):
        """测试数据库统计信息"""
        self.db_service.init_database()
        
        stats = self.db_service.get_database_stats()
        self.assertIsInstance(stats, dict)
        self.assertIn('emails_count', stats)
        self.assertIn('tags_count', stats)
        self.assertIn('file_size', stats)


class TestConfigManager(unittest.TestCase):
    """测试配置管理器"""
    
    def setUp(self):
        """测试前准备"""
        self.temp_dir = tempfile.mkdtemp()
        self.config_file = Path(self.temp_dir) / "test_config.json"
        self.config_manager = ConfigManager(self.config_file)
    
    def tearDown(self):
        """测试后清理"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def test_config_manager_creation(self):
        """测试配置管理器创建"""
        self.assertIsNotNone(self.config_manager)
        self.assertTrue(self.config_file.exists())
    
    def test_config_save_load(self):
        """测试配置保存和加载"""
        # 更新配置
        updates = {
            'domain_config': {
                'domain': 'test.example.com'
            },
            'verification_method': 'tempmail'
        }
        
        result = self.config_manager.update_config(updates)
        self.assertTrue(result)
        
        # 重新加载配置
        config = self.config_manager.load_config()
        self.assertEqual(config.domain_config.domain, 'test.example.com')
        self.assertEqual(config.verification_method, 'tempmail')


def run_tests():
    """运行所有测试"""
    # 创建测试套件
    test_suite = unittest.TestSuite()
    
    # 添加测试类
    test_classes = [
        TestEmailModel,
        TestConfigModel,
        TestTagModel,
        TestDatabaseService,
        TestConfigManager
    ]
    
    for test_class in test_classes:
        tests = unittest.TestLoader().loadTestsFromTestCase(test_class)
        test_suite.addTests(tests)
    
    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)
    
    return result.wasSuccessful()


if __name__ == "__main__":
    print("=" * 60)
    print("域名邮箱管理器 - 基础功能测试")
    print("=" * 60)
    
    success = run_tests()
    
    if success:
        print("\n✅ 所有测试通过！")
        sys.exit(0)
    else:
        print("\n❌ 部分测试失败！")
        sys.exit(1)
