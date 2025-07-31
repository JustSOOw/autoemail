#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
数据持久化测试脚本
测试域名配置保存和邮箱数据显示功能
"""

import sys
import os
import sqlite3
from datetime import datetime
from pathlib import Path

# 添加项目根目录到Python路径
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

try:
    from services.database_service import DatabaseService
    from services.config_service import ConfigService
    from services.email_service import EmailService
    from utils.config_manager import ConfigManager
    from models.config_model import ConfigModel
    from utils.logger import get_logger
except ImportError as e:
    print(f"导入错误: {e}")
    print("尝试备用导入方式...")
    from src.services.database_service import DatabaseService
    from src.services.config_service import ConfigService
    from src.services.email_service import EmailService
    from src.utils.config_manager import ConfigManager
    from src.models.config_model import ConfigModel
    from src.utils.logger import get_logger

def test_domain_persistence():
    """测试域名配置持久化"""
    print("🔧 测试域名配置持久化...")

    try:
        # 初始化服务
        db_path = Path("data/autoemail.db")
        db_path.parent.mkdir(parents=True, exist_ok=True)
        db_service = DatabaseService(db_path)
        # 初始化数据库表
        db_service.init_database()
        config_service = ConfigService(db_service)
        config_file = Path("config/app_config.json")
        config_file.parent.mkdir(parents=True, exist_ok=True)
        config_manager = ConfigManager(config_file)
        
        test_domain = "test-domain.com"
        
        # 测试1：通过ConfigService保存域名
        print(f"1. 通过ConfigService保存域名: {test_domain}")
        success = config_service.update_domain_config(test_domain)
        print(f"   保存结果: {'成功' if success else '失败'}")
        
        # 测试2：通过ConfigService读取域名
        print("2. 通过ConfigService读取域名")
        saved_domain = config_service.get_config_value("domain_config.domain", "")
        print(f"   读取结果: {saved_domain}")
        print(f"   匹配结果: {'✅ 匹配' if saved_domain == test_domain else '❌ 不匹配'}")
        
        # 测试3：直接查询数据库
        print("3. 直接查询数据库")
        query = "SELECT config_key, config_value FROM configurations WHERE config_key LIKE '%domain%'"
        results = db_service.execute_query(query)
        print(f"   数据库记录数: {len(results) if results else 0}")
        if results:
            for row in results:
                print(f"   {row['config_key']}: {row['config_value']}")
        
        # 测试4：通过ConfigManager保存和读取
        print("4. 通过ConfigManager保存和读取")
        config = config_manager.get_config()
        config.set_domain(test_domain)
        save_success = config_manager.save_config()
        print(f"   ConfigManager保存结果: {'成功' if save_success else '失败'}")
        
        # 重新加载配置
        config_manager._config = None  # 清除缓存
        reloaded_config = config_manager.get_config()
        reloaded_domain = reloaded_config.get_domain()
        print(f"   ConfigManager读取结果: {reloaded_domain}")
        print(f"   匹配结果: {'✅ 匹配' if reloaded_domain == test_domain else '❌ 不匹配'}")
        
        return saved_domain == test_domain and reloaded_domain == test_domain
        
    except Exception as e:
        print(f"❌ 域名持久化测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_email_persistence():
    """测试邮箱数据持久化"""
    print("\n📧 测试邮箱数据持久化...")

    try:
        # 初始化服务
        db_path = Path("data/autoemail.db")
        db_path.parent.mkdir(parents=True, exist_ok=True)
        db_service = DatabaseService(db_path)
        # 初始化数据库表
        db_service.init_database()
        config_file = Path("config/app_config.json")
        config_file.parent.mkdir(parents=True, exist_ok=True)
        config_manager = ConfigManager(config_file)
        config = config_manager.get_config()
        
        # 设置测试域名
        config.set_domain("test-email.com")
        
        email_service = EmailService(config=config, db_service=db_service)
        
        # 测试1：创建邮箱
        print("1. 创建测试邮箱")
        email_model = email_service.create_email(
            prefix_type="random_name",
            tags=["测试标签"],
            notes="测试邮箱"
        )
        print(f"   创建的邮箱: {email_model.email_address}")
        print(f"   邮箱ID: {email_model.id}")
        
        # 测试2：查询邮箱列表
        print("2. 查询邮箱列表")
        from src.models.email_model import EmailStatus
        emails = email_service.get_emails_by_status(EmailStatus.ACTIVE, limit=10)
        print(f"   活跃邮箱数量: {len(emails)}")
        
        # 如果没有活跃邮箱，尝试查询所有邮箱
        if not emails:
            print("   未找到活跃邮箱，查询所有邮箱...")
            emails = email_service.search_emails(limit=10)
            print(f"   所有邮箱数量: {len(emails)}")
        
        # 测试3：直接查询数据库
        print("3. 直接查询数据库")
        query = "SELECT COUNT(*) as count FROM emails WHERE is_active = 1"
        result = db_service.execute_query(query, fetch_one=True)
        db_count = result['count'] if result else 0
        print(f"   数据库中活跃邮箱数量: {db_count}")
        
        # 显示邮箱详情
        if emails:
            print("4. 邮箱详情:")
            for i, email in enumerate(emails[:3]):  # 只显示前3个
                print(f"   [{i+1}] {email.email_address}")
                print(f"       域名: {email.domain}")
                print(f"       状态: {email.status}")
                print(f"       创建时间: {email.created_at}")
                print(f"       标签: {email.tags}")
        
        return len(emails) > 0
        
    except Exception as e:
        print(f"❌ 邮箱持久化测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_database_tables():
    """测试数据库表结构"""
    print("\n🗄️ 测试数据库表结构...")

    try:
        db_path = Path("data/autoemail.db")
        db_path.parent.mkdir(parents=True, exist_ok=True)
        db_service = DatabaseService(db_path)
        # 初始化数据库表
        db_service.init_database()
        
        # 检查表是否存在
        tables = ['emails', 'tags', 'email_tags', 'configurations']
        for table in tables:
            query = f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table}'"
            result = db_service.execute_query(query, fetch_one=True)
            exists = result is not None
            print(f"   表 {table}: {'✅ 存在' if exists else '❌ 不存在'}")
            
            if exists:
                # 获取表结构
                info = db_service.get_table_info(table)
                print(f"     字段数: {len(info)}")
        
        return True
        
    except Exception as e:
        print(f"❌ 数据库表结构测试失败: {e}")
        return False

def main():
    """主测试函数"""
    print("🧪 数据持久化测试开始")
    print("=" * 50)
    
    # 测试数据库表结构
    db_test = test_database_tables()
    
    # 测试域名持久化
    domain_test = test_domain_persistence()
    
    # 测试邮箱持久化
    email_test = test_email_persistence()
    
    print("\n" + "=" * 50)
    print("🧪 测试结果汇总:")
    print(f"   数据库表结构: {'✅ 通过' if db_test else '❌ 失败'}")
    print(f"   域名持久化: {'✅ 通过' if domain_test else '❌ 失败'}")
    print(f"   邮箱持久化: {'✅ 通过' if email_test else '❌ 失败'}")
    
    all_passed = db_test and domain_test and email_test
    print(f"\n总体结果: {'🎉 全部通过' if all_passed else '⚠️ 存在问题'}")
    
    return 0 if all_passed else 1

if __name__ == "__main__":
    sys.exit(main())
