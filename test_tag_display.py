#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试标签显示功能的脚本
"""

import sys
import os
import json
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root / "src"))

from controllers.email_controller import EmailController
from controllers.tag_controller import TagController
from services.database_service import DatabaseService
from services.email_service import EmailService
from services.tag_service import TagService
from utils.config_manager import ConfigManager
from utils.logger import setup_logger

def test_tag_display():
    """测试标签显示功能"""
    
    # 设置日志
    logger = setup_logger(log_file=None, level="DEBUG")
    logger.info("开始测试标签显示功能")
    
    try:
        # 初始化服务
        config_file = project_root / "data" / "config.json"
        db_path = project_root / "data" / "email_manager.db"
        config_manager = ConfigManager(config_file)
        database_service = DatabaseService(db_path)
        
        # 获取配置
        config = config_manager.get_config()
        email_service = EmailService(config, database_service)
        tag_service = TagService(database_service)
        
        # 初始化数据库
        database_service.init_database()
        
        # 创建控制器
        email_controller = EmailController(
            config_manager=config_manager,
            database_service=database_service
        )
        tag_controller = TagController(database_service)
        
        # 1. 获取所有标签
        logger.info("=== 步骤1: 获取所有标签 ===")

        # 先直接调用TagService测试
        logger.info("直接调用TagService...")
        try:
            tags = tag_service.get_all_tags()
            logger.info(f"TagService返回 {len(tags)} 个标签")
            for tag in tags:
                logger.info(f"  标签: {tag.name} (ID: {tag.id}, 颜色: {tag.color}, 图标: {tag.icon})")
        except Exception as e:
            logger.error(f"直接调用TagService失败: {e}")
            import traceback
            logger.error(f"详细错误信息: {traceback.format_exc()}")
            return False

        # 再调用TagController测试
        try:
            tag_result = tag_controller.getAllTags()
            logger.info(f"TagController返回结果: {tag_result}")
            tag_data = json.loads(tag_result)
        except Exception as e:
            logger.error(f"调用TagController.getAllTags()失败: {e}")
            import traceback
            logger.error(f"详细错误信息: {traceback.format_exc()}")
            return False
        
        if tag_data.get('success'):
            all_tags = tag_data['tags']
            logger.info(f"获取到 {len(all_tags)} 个标签:")
            for tag in all_tags:
                logger.info(f"  - ID: {tag['id']}, 名称: {tag['name']}, 颜色: {tag['color']}, 图标: {tag['icon']}")
        else:
            logger.error("获取标签失败")
            return False
        
        # 2. 获取邮箱列表
        logger.info("=== 步骤2: 获取邮箱列表 ===")
        email_controller.refreshEmailList()
        
        import time
        time.sleep(1)
        
        if not email_controller._current_emails:
            logger.error("没有可用的邮箱")
            return False
        
        # 选择第一个邮箱
        test_email = email_controller._current_emails[0]
        logger.info(f"选择测试邮箱: ID={test_email.id}, 地址={test_email.email_address}")
        logger.info(f"邮箱当前标签: {test_email.tags}")
        
        # 3. 模拟前端数据格式
        logger.info("=== 步骤3: 模拟前端数据格式 ===")
        
        # 邮箱数据（模拟EmailController返回的格式）
        email_data = {
            "id": test_email.id,
            "email_address": test_email.email_address,
            "notes": test_email.notes,
            "tags": test_email.tags  # 这是字符串数组
        }
        
        logger.info(f"邮箱数据: {json.dumps(email_data, ensure_ascii=False)}")
        logger.info(f"所有标签数据: {json.dumps(all_tags, ensure_ascii=False)}")
        
        # 4. 测试标签名称到对象的转换
        logger.info("=== 步骤4: 测试标签转换 ===")
        
        def convert_tag_names_to_objects(tag_names, all_tag_objects):
            """将标签名称转换为标签对象"""
            tag_objects = []
            
            if not tag_names or not all_tag_objects:
                return tag_objects
            
            for tag_name in tag_names:
                # 在所有标签中查找匹配的标签对象
                for tag_obj in all_tag_objects:
                    if tag_obj['name'] == tag_name:
                        tag_objects.append(tag_obj)
                        break
            
            return tag_objects
        
        converted_tags = convert_tag_names_to_objects(email_data['tags'], all_tags)
        logger.info(f"转换后的标签对象: {json.dumps(converted_tags, ensure_ascii=False)}")
        
        # 5. 验证转换结果
        logger.info("=== 步骤5: 验证转换结果 ===")
        
        if len(converted_tags) == len(email_data['tags']):
            logger.info("✅ 标签转换成功！所有标签都找到了对应的对象")
            
            for i, tag_obj in enumerate(converted_tags):
                original_name = email_data['tags'][i]
                logger.info(f"  标签 '{original_name}' -> ID: {tag_obj['id']}, 颜色: {tag_obj['color']}, 图标: {tag_obj['icon']}")
            
            return True
        else:
            logger.warning(f"⚠️ 标签转换不完整: 原始{len(email_data['tags'])}个，转换后{len(converted_tags)}个")
            
            # 找出未转换的标签
            converted_names = [tag['name'] for tag in converted_tags]
            missing_tags = [name for name in email_data['tags'] if name not in converted_names]
            if missing_tags:
                logger.warning(f"未找到的标签: {missing_tags}")
            
            return len(converted_tags) > 0
            
    except Exception as e:
        logger.error(f"测试过程中发生错误: {e}")
        import traceback
        logger.error(f"详细错误信息: {traceback.format_exc()}")
        return False

if __name__ == "__main__":
    success = test_tag_display()
    sys.exit(0 if success else 1)
