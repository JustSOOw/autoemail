#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试标签更新功能的脚本
"""

import sys
import os
import json
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root / "src"))

from controllers.email_controller import EmailController
from services.database_service import DatabaseService
from services.email_service import EmailService
from utils.config_manager import ConfigManager
from utils.logger import setup_logger

def test_tag_update():
    """测试标签更新功能"""
    
    # 设置日志
    logger = setup_logger(log_file=None, level="DEBUG")  # 不使用文件日志，只输出到控制台
    logger.info("开始测试标签更新功能")
    
    try:
        # 初始化服务
        config_file = project_root / "data" / "config.json"
        db_path = project_root / "data" / "email_manager.db"
        config_manager = ConfigManager(config_file)
        database_service = DatabaseService(db_path)

        # 获取配置
        config = config_manager.get_config()
        email_service = EmailService(config, database_service)
        
        # 初始化数据库
        database_service.init_database()
        
        # 创建EmailController
        email_controller = EmailController(
            config_manager=config_manager,
            database_service=database_service
        )
        
        # 1. 获取邮箱列表，使用现有邮箱进行测试
        logger.info("=== 步骤1: 获取邮箱列表 ===")
        email_controller.refreshEmailList()

        # 等待邮箱列表更新
        import time
        time.sleep(1)

        # 选择第一个邮箱进行测试
        if not email_controller._current_emails:
            logger.error("没有可用的邮箱进行测试")
            return False

        test_email = email_controller._current_emails[0]
        logger.info(f"选择测试邮箱: ID={test_email.id}, 地址={test_email.email_address}, 当前标签={test_email.tags}")
        
        # 3. 测试标签更新
        logger.info("=== 步骤3: 测试标签更新 ===")
        
        # 获取可用标签
        tag_query = "SELECT id, name FROM tags WHERE is_active = 1 LIMIT 2"
        tag_results = database_service.execute_query(tag_query)
        
        if not tag_results:
            logger.error("没有可用的标签进行测试")
            return False
            
        # 选择前两个标签进行测试
        test_tag_ids = []
        for row in tag_results:
            if isinstance(row, dict):
                test_tag_ids.append(row['id'])
            else:
                test_tag_ids.append(row[0])
        
        logger.info(f"选择测试标签IDs: {test_tag_ids}")
        
        # 调用更新方法
        update_result = email_controller.updateEmail(
            email_id=test_email.id,
            notes="更新后的备注信息",
            tag_ids=test_tag_ids
        )
        
        logger.info(f"更新结果: {update_result}")
        
        # 4. 验证更新结果
        logger.info("=== 步骤4: 验证更新结果 ===")
        
        # 从数据库直接查询验证
        verification_query = """
            SELECT e.id, e.notes, GROUP_CONCAT(t.name) as tag_names 
            FROM emails e 
            LEFT JOIN email_tags et ON e.id = et.email_id 
            LEFT JOIN tags t ON et.tag_id = t.id AND t.is_active = 1
            WHERE e.id = ?
            GROUP BY e.id
        """
        verification_result = database_service.execute_query(verification_query, (test_email.id,))
        
        if verification_result:
            row = verification_result[0]
            if isinstance(row, dict):
                actual_notes = row['notes']
                actual_tags = row['tag_names']
            else:
                actual_notes = row[1]
                actual_tags = row[2]
                
            logger.info(f"数据库验证结果:")
            logger.info(f"  备注: '{actual_notes}'")
            logger.info(f"  标签: '{actual_tags}'")
            
            # 检查结果
            update_data = json.loads(update_result)
            if update_data.get('success'):
                logger.info("✅ 标签更新功能测试成功!")
                return True
            else:
                logger.error(f"❌ 标签更新失败: {update_data.get('error')}")
                return False
        else:
            logger.error("❌ 无法验证更新结果")
            return False
            
    except Exception as e:
        logger.error(f"测试过程中发生错误: {e}")
        import traceback
        logger.error(f"详细错误信息: {traceback.format_exc()}")
        return False

if __name__ == "__main__":
    success = test_tag_update()
    sys.exit(0 if success else 1)
