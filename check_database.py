#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
检查数据库中的标签数据
"""

import sys
import sqlite3
from pathlib import Path

def check_database():
    """检查数据库中的标签数据"""
    
    project_root = Path(__file__).parent
    db_path = project_root / "data" / "email_manager.db"
    
    if not db_path.exists():
        print(f"数据库文件不存在: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row  # 使结果可以通过列名访问
        cursor = conn.cursor()
        
        print("=== 检查标签表结构 ===")
        cursor.execute("PRAGMA table_info(tags)")
        columns = cursor.fetchall()
        for col in columns:
            print(f"  {col['name']}: {col['type']}")
        
        print("\n=== 检查标签数据 ===")
        cursor.execute("SELECT * FROM tags")
        tags = cursor.fetchall()
        print(f"总共有 {len(tags)} 个标签:")
        
        for tag in tags:
            print(f"  ID: {tag['id']}, 名称: {tag['name']}, 活跃: {tag['is_active']}, 系统: {tag['is_system']}")
        
        print("\n=== 检查活跃标签 ===")
        cursor.execute("SELECT * FROM tags WHERE is_active = 1")
        active_tags = cursor.fetchall()
        print(f"活跃标签有 {len(active_tags)} 个:")
        
        for tag in active_tags:
            print(f"  ID: {tag['id']}, 名称: {tag['name']}, 颜色: {tag['color']}, 图标: {tag['icon']}")
        
        print("\n=== 检查邮箱标签关联 ===")
        cursor.execute("""
            SELECT et.email_id, et.tag_id, t.name as tag_name, e.email_address
            FROM email_tags et
            JOIN tags t ON et.tag_id = t.id
            JOIN emails e ON et.email_id = e.id
            LIMIT 10
        """)
        relations = cursor.fetchall()
        print(f"邮箱标签关联有 {len(relations)} 个:")
        
        for rel in relations:
            print(f"  邮箱: {rel['email_address']} -> 标签: {rel['tag_name']}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"检查数据库时发生错误: {e}")
        import traceback
        print(f"详细错误信息: {traceback.format_exc()}")
        return False

if __name__ == "__main__":
    success = check_database()
    sys.exit(0 if success else 1)
