# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 数据库服务
负责数据库的初始化、连接和基本操作
"""

import sqlite3
import threading
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from utils.logger import get_logger


class DatabaseService:
    """数据库服务类"""

    def __init__(self, db_path: Path):
        """
        初始化数据库服务

        Args:
            db_path: 数据库文件路径
        """
        self.db_path = db_path
        self.logger = get_logger(__name__)
        self._local = threading.local()

        # 确保数据库目录存在
        self.db_path.parent.mkdir(parents=True, exist_ok=True)

        self.logger.info(f"数据库服务初始化: {db_path}")

    def get_connection(self) -> sqlite3.Connection:
        """
        获取数据库连接（线程安全）

        Returns:
            数据库连接对象
        """
        if not hasattr(self._local, "connection"):
            self._local.connection = sqlite3.connect(
                str(self.db_path), check_same_thread=False, timeout=30.0
            )

            # 设置连接属性
            self._local.connection.row_factory = sqlite3.Row
            self._local.connection.execute("PRAGMA foreign_keys = ON")
            self._local.connection.execute("PRAGMA journal_mode = WAL")

        return self._local.connection

    @contextmanager
    def get_cursor(self):
        """
        获取数据库游标的上下文管理器

        Yields:
            数据库游标
        """
        conn = self.get_connection()
        cursor = conn.cursor()
        try:
            yield cursor
            conn.commit()
        except Exception as e:
            conn.rollback()
            self.logger.error(f"数据库操作失败: {e}")
            raise
        finally:
            cursor.close()

    def init_database(self) -> bool:
        """
        初始化数据库表结构

        Returns:
            是否初始化成功
        """
        try:
            self.logger.info("开始初始化数据库表结构")

            with self.get_cursor() as cursor:
                # 创建邮箱表
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS emails (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        email_address VARCHAR(255) NOT NULL UNIQUE,
                        domain VARCHAR(100) NOT NULL,
                        prefix VARCHAR(50) NOT NULL,
                        timestamp_suffix VARCHAR(20),
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        last_used DATETIME,
                        verification_status VARCHAR(20) DEFAULT 'pending',
                        verification_code VARCHAR(10),
                        verification_method VARCHAR(20),
                        verification_attempts INTEGER DEFAULT 0,
                        last_verification_at DATETIME,
                        notes TEXT,
                        is_active BOOLEAN DEFAULT 1,
                        metadata TEXT,
                        created_by VARCHAR(50) DEFAULT 'system',
                        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                """
                )

                # 创建标签表
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS tags (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name VARCHAR(50) NOT NULL UNIQUE,
                        color VARCHAR(7) DEFAULT '#3498db',
                        icon VARCHAR(50),
                        description TEXT,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        is_system BOOLEAN DEFAULT 0,
                        sort_order INTEGER DEFAULT 0
                    )
                """
                )

                # 创建邮箱标签关联表
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS email_tags (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        email_id INTEGER NOT NULL,
                        tag_id INTEGER NOT NULL,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        created_by VARCHAR(50) DEFAULT 'user',
                        FOREIGN KEY (email_id) REFERENCES emails(id) ON DELETE CASCADE,
                        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
                        UNIQUE(email_id, tag_id)
                    )
                """
                )

                # 创建配置表
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS configurations (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        config_key VARCHAR(100) NOT NULL,
                        config_value TEXT,
                        config_type VARCHAR(50) NOT NULL,
                        is_encrypted BOOLEAN DEFAULT 0,
                        is_active BOOLEAN DEFAULT 1,
                        version INTEGER DEFAULT 1,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        description TEXT
                    )
                """
                )

                # 创建操作日志表
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS operation_logs (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        operation_type VARCHAR(50) NOT NULL,
                        target_type VARCHAR(50) NOT NULL,
                        target_id INTEGER,
                        operation_details TEXT,
                        result VARCHAR(20) NOT NULL,
                        error_message TEXT,
                        user_agent TEXT,
                        ip_address VARCHAR(45),
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        execution_time REAL
                    )
                """
                )

                # 创建索引
                self._create_indexes(cursor)

                # 插入系统预定义数据
                self._insert_system_data(cursor)

            self.logger.info("数据库表结构初始化完成")
            return True

        except Exception as e:
            self.logger.error(f"初始化数据库失败: {e}")
            return False

    def _create_indexes(self, cursor: sqlite3.Cursor):
        """创建数据库索引"""
        indexes = [
            # 邮箱表索引
            "CREATE INDEX IF NOT EXISTS idx_emails_domain ON emails(domain)",
            "CREATE INDEX IF NOT EXISTS idx_emails_created_at ON emails(created_at)",
            "CREATE INDEX IF NOT EXISTS idx_emails_verification_status ON emails(verification_status)",
            "CREATE INDEX IF NOT EXISTS idx_emails_is_active ON emails(is_active)",
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_emails_address ON emails(email_address)",
            # 标签表索引
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_tags_name ON tags(name)",
            "CREATE INDEX IF NOT EXISTS idx_tags_sort_order ON tags(sort_order)",
            # 邮箱标签关联表索引
            "CREATE INDEX IF NOT EXISTS idx_email_tags_email_id ON email_tags(email_id)",
            "CREATE INDEX IF NOT EXISTS idx_email_tags_tag_id ON email_tags(tag_id)",
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_email_tags_unique ON email_tags(email_id, tag_id)",
            # 配置表索引
            "CREATE INDEX IF NOT EXISTS idx_config_key_type ON configurations(config_key, config_type)",
            "CREATE INDEX IF NOT EXISTS idx_config_active ON configurations(is_active)",
            "CREATE INDEX IF NOT EXISTS idx_config_type ON configurations(config_type)",
            # 操作日志表索引
            "CREATE INDEX IF NOT EXISTS idx_logs_operation_type ON operation_logs(operation_type)",
            "CREATE INDEX IF NOT EXISTS idx_logs_target_type ON operation_logs(target_type)",
            "CREATE INDEX IF NOT EXISTS idx_logs_created_at ON operation_logs(created_at)",
            "CREATE INDEX IF NOT EXISTS idx_logs_result ON operation_logs(result)",
        ]

        for index_sql in indexes:
            try:
                cursor.execute(index_sql)
            except Exception as e:
                self.logger.warning(f"创建索引失败: {e}")

    def _insert_system_data(self, cursor: sqlite3.Cursor):
        """插入系统预定义数据"""
        try:
            # 插入系统预定义标签
            system_tags = [
                ("测试用", "#e74c3c", "🧪", "用于测试目的的邮箱", 1, 1),
                ("开发用", "#3498db", "💻", "开发环境使用的邮箱", 1, 2),
                ("生产用", "#27ae60", "🚀", "生产环境使用的邮箱", 1, 3),
                ("临时用", "#f39c12", "⏰", "临时使用的邮箱", 1, 4),
                ("重要", "#9b59b6", "⭐", "重要的邮箱记录", 1, 5),
            ]

            for tag_data in system_tags:
                cursor.execute(
                    """
                    INSERT OR IGNORE INTO tags 
                    (name, color, icon, description, is_system, sort_order) 
                    VALUES (?, ?, ?, ?, ?, ?)
                """,
                    tag_data,
                )

            # 插入默认配置
            default_configs = [
                ("app_version", "1.0.0", "system", "应用程序版本"),
                ("database_version", "1.0.0", "system", "数据库版本"),
                ("auto_cleanup_days", "30", "system", "自动清理天数"),
                ("max_verification_attempts", "5", "system", "最大验证尝试次数"),
                ("default_timeout", "300", "system", "默认超时时间（秒）"),
            ]

            for config_data in default_configs:
                cursor.execute(
                    """
                    INSERT OR IGNORE INTO configurations 
                    (config_key, config_value, config_type, description) 
                    VALUES (?, ?, ?, ?)
                """,
                    config_data,
                )

            self.logger.debug("系统预定义数据插入完成")

        except Exception as e:
            self.logger.error(f"插入系统数据失败: {e}")

    def execute_query(
        self, query: str, params: tuple = (), fetch_one: bool = False
    ) -> Optional[List[sqlite3.Row]]:
        """
        执行查询语句

        Args:
            query: SQL查询语句
            params: 查询参数
            fetch_one: 是否只获取一条记录

        Returns:
            查询结果
        """
        try:
            with self.get_cursor() as cursor:
                cursor.execute(query, params)

                if fetch_one:
                    return cursor.fetchone()
                else:
                    return cursor.fetchall()

        except Exception as e:
            self.logger.error(f"执行查询失败: {e}")
            return None

    def execute_update(self, query: str, params: tuple = ()) -> int:
        """
        执行更新语句

        Args:
            query: SQL更新语句
            params: 更新参数

        Returns:
            影响的行数
        """
        try:
            with self.get_cursor() as cursor:
                cursor.execute(query, params)
                return cursor.rowcount

        except Exception as e:
            self.logger.error(f"执行更新失败: {e}")
            return 0

    def get_table_info(self, table_name: str) -> List[Dict[str, Any]]:
        """
        获取表结构信息

        Args:
            table_name: 表名

        Returns:
            表结构信息列表
        """
        try:
            with self.get_cursor() as cursor:
                cursor.execute(f"PRAGMA table_info({table_name})")
                columns = cursor.fetchall()

                return [
                    {
                        "cid": col["cid"],
                        "name": col["name"],
                        "type": col["type"],
                        "notnull": bool(col["notnull"]),
                        "default_value": col["dflt_value"],
                        "primary_key": bool(col["pk"]),
                    }
                    for col in columns
                ]

        except Exception as e:
            self.logger.error(f"获取表结构信息失败: {e}")
            return []

    def get_database_stats(self) -> Dict[str, Any]:
        """
        获取数据库统计信息

        Returns:
            数据库统计信息
        """
        try:
            stats = {}

            # 表记录数统计
            tables = [
                "emails",
                "tags",
                "email_tags",
                "configurations",
                "operation_logs",
            ]

            for table in tables:
                # 使用预定义的表名，安全的SQL查询
                query = "SELECT COUNT(*) as count FROM " + table  # nosec B608
                count = self.execute_query(query, fetch_one=True)
                stats[f"{table}_count"] = count["count"] if count else 0

            # 数据库文件大小
            if self.db_path.exists():
                stats["file_size"] = self.db_path.stat().st_size
            else:
                stats["file_size"] = 0

            # 数据库版本
            version_info = self.execute_query(
                "SELECT config_value FROM configurations WHERE config_key = 'database_version'",
                fetch_one=True,
            )
            stats["database_version"] = (
                version_info["config_value"] if version_info else "unknown"
            )

            return stats

        except Exception as e:
            self.logger.error(f"获取数据库统计信息失败: {e}")
            return {}

    def vacuum_database(self) -> bool:
        """
        清理数据库碎片

        Returns:
            是否清理成功
        """
        try:
            self.logger.info("开始清理数据库碎片")

            with self.get_cursor() as cursor:
                cursor.execute("VACUUM")

            self.logger.info("数据库碎片清理完成")
            return True

        except Exception as e:
            self.logger.error(f"清理数据库碎片失败: {e}")
            return False

    def backup_database(self, backup_path: Path) -> bool:
        """
        备份数据库

        Args:
            backup_path: 备份文件路径

        Returns:
            是否备份成功
        """
        try:
            self.logger.info(f"开始备份数据库到: {backup_path}")

            # 确保备份目录存在
            backup_path.parent.mkdir(parents=True, exist_ok=True)

            # 使用SQLite的备份API
            source_conn = self.get_connection()
            backup_conn = sqlite3.connect(str(backup_path))

            source_conn.backup(backup_conn)
            backup_conn.close()

            self.logger.info("数据库备份完成")
            return True

        except Exception as e:
            self.logger.error(f"备份数据库失败: {e}")
            return False

    def close(self):
        """关闭数据库连接"""
        try:
            if hasattr(self._local, "connection"):
                self._local.connection.close()
                delattr(self._local, "connection")

            self.logger.info("数据库连接已关闭")

        except Exception as e:
            self.logger.error(f"关闭数据库连接失败: {e}")

    def __del__(self):
        """析构函数"""
        self.close()
