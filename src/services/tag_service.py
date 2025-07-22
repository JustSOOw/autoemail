# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 标签服务
负责标签的创建、管理和关联操作
"""

from datetime import datetime
from typing import List, Optional, Dict, Any

from models.tag_model import TagModel, create_tag_model
from services.database_service import DatabaseService
from utils.logger import get_logger


class TagService:
    """
    标签服务类
    
    提供标签的完整CRUD操作和关联管理功能
    """

    def __init__(self, db_service: DatabaseService):
        """
        初始化标签服务
        
        Args:
            db_service: 数据库服务实例
        """
        self.db_service = db_service
        self.logger = get_logger(__name__)
        
        self.logger.info("标签服务初始化完成")

    def create_tag(self, 
                   name: str,
                   description: str = "",
                   color: str = "#3498db",
                   icon: str = "🏷️") -> Optional[TagModel]:
        """
        创建新标签
        
        Args:
            name: 标签名称
            description: 标签描述
            color: 标签颜色（十六进制）
            icon: 标签图标
            
        Returns:
            创建的标签模型或None
        """
        try:
            # 检查标签名称是否已存在
            if self.get_tag_by_name(name):
                self.logger.warning(f"标签名称已存在: {name}")
                return None
            
            # 创建标签模型
            tag_model = create_tag_model(
                name=name,
                description=description,
                color=color,
                icon=icon
            )
            
            # 保存到数据库
            tag_id = self._save_tag_to_db(tag_model)
            if tag_id:
                tag_model.id = tag_id
                self.logger.info(f"成功创建标签: {name}")
                return tag_model
            
            return None
            
        except Exception as e:
            self.logger.error(f"创建标签失败: {e}")
            return None

    def get_tag_by_id(self, tag_id: int) -> Optional[TagModel]:
        """
        根据ID获取标签
        
        Args:
            tag_id: 标签ID
            
        Returns:
            标签模型或None
        """
        try:
            query = "SELECT * FROM tags WHERE id = ? AND is_active = 1"
            result = self.db_service.execute_query(query, (tag_id,), fetch_one=True)
            
            if result:
                return self._row_to_tag_model(result)
            return None
            
        except Exception as e:
            self.logger.error(f"获取标签失败: {e}")
            return None

    def get_tag_by_name(self, name: str) -> Optional[TagModel]:
        """
        根据名称获取标签
        
        Args:
            name: 标签名称
            
        Returns:
            标签模型或None
        """
        try:
            query = "SELECT * FROM tags WHERE name = ? AND is_active = 1"
            result = self.db_service.execute_query(query, (name,), fetch_one=True)
            
            if result:
                return self._row_to_tag_model(result)
            return None
            
        except Exception as e:
            self.logger.error(f"根据名称获取标签失败: {e}")
            return None

    def get_all_tags(self, include_system: bool = True) -> List[TagModel]:
        """
        获取所有标签
        
        Args:
            include_system: 是否包含系统标签
            
        Returns:
            标签模型列表
        """
        try:
            if include_system:
                query = "SELECT * FROM tags WHERE is_active = 1 ORDER BY is_system DESC, name ASC"
                params = ()
            else:
                query = "SELECT * FROM tags WHERE is_active = 1 AND is_system = 0 ORDER BY name ASC"
                params = ()
            
            results = self.db_service.execute_query(query, params)
            
            return [self._row_to_tag_model(row) for row in results or []]
            
        except Exception as e:
            self.logger.error(f"获取所有标签失败: {e}")
            return []

    def update_tag(self, tag_model: TagModel) -> bool:
        """
        更新标签信息
        
        Args:
            tag_model: 标签模型
            
        Returns:
            是否更新成功
        """
        try:
            # 系统标签不允许修改名称
            if tag_model.is_system:
                existing_tag = self.get_tag_by_id(tag_model.id)
                if existing_tag and existing_tag.name != tag_model.name:
                    self.logger.warning(f"系统标签不允许修改名称: {existing_tag.name}")
                    return False
            
            tag_model.updated_at = datetime.now()
            return self._update_tag_in_db(tag_model)
            
        except Exception as e:
            self.logger.error(f"更新标签失败: {e}")
            return False

    def delete_tag(self, tag_id: int, force: bool = False) -> bool:
        """
        删除标签（软删除）
        
        Args:
            tag_id: 标签ID
            force: 是否强制删除（包括系统标签）
            
        Returns:
            是否删除成功
        """
        try:
            # 检查是否为系统标签
            tag = self.get_tag_by_id(tag_id)
            if not tag:
                return False
            
            if tag.is_system and not force:
                self.logger.warning(f"系统标签不允许删除: {tag.name}")
                return False
            
            # 检查是否有邮箱使用此标签
            email_count = self._get_tag_usage_count(tag_id)
            if email_count > 0:
                self.logger.warning(f"标签 {tag.name} 正在被 {email_count} 个邮箱使用，无法删除")
                return False
            
            # 软删除
            query = "UPDATE tags SET is_active = 0, updated_at = ? WHERE id = ?"
            affected_rows = self.db_service.execute_update(
                query, 
                (datetime.now().isoformat(), tag_id)
            )
            
            success = affected_rows > 0
            if success:
                self.logger.info(f"成功删除标签: {tag.name}")
            
            return success
            
        except Exception as e:
            self.logger.error(f"删除标签失败: {e}")
            return False

    def get_tag_statistics(self) -> Dict[str, Any]:
        """
        获取标签统计信息
        
        Returns:
            标签统计信息字典
        """
        try:
            stats = {}
            
            # 总标签数
            total_query = "SELECT COUNT(*) as count FROM tags WHERE is_active = 1"
            total_result = self.db_service.execute_query(total_query, fetch_one=True)
            stats["total_tags"] = total_result["count"] if total_result else 0
            
            # 系统标签数
            system_query = "SELECT COUNT(*) as count FROM tags WHERE is_active = 1 AND is_system = 1"
            system_result = self.db_service.execute_query(system_query, fetch_one=True)
            stats["system_tags"] = system_result["count"] if system_result else 0
            
            # 用户标签数
            stats["user_tags"] = stats["total_tags"] - stats["system_tags"]
            
            # 标签使用统计
            usage_query = """
                SELECT t.name, t.color, t.icon, COUNT(et.email_id) as usage_count
                FROM tags t
                LEFT JOIN email_tags et ON t.id = et.tag_id
                WHERE t.is_active = 1
                GROUP BY t.id, t.name, t.color, t.icon
                ORDER BY usage_count DESC
                LIMIT 10
            """
            usage_results = self.db_service.execute_query(usage_query)
            stats["top_used_tags"] = [
                {
                    "name": row["name"],
                    "color": row["color"],
                    "icon": row["icon"],
                    "usage_count": row["usage_count"]
                }
                for row in usage_results or []
            ]
            
            return stats
            
        except Exception as e:
            self.logger.error(f"获取标签统计信息失败: {e}")
            return {}

    def search_tags(self, keyword: str = "", limit: int = 50) -> List[TagModel]:
        """
        搜索标签
        
        Args:
            keyword: 搜索关键词
            limit: 限制数量
            
        Returns:
            标签模型列表
        """
        try:
            if keyword:
                query = """
                    SELECT * FROM tags 
                    WHERE is_active = 1 AND (name LIKE ? OR description LIKE ?)
                    ORDER BY is_system DESC, name ASC 
                    LIMIT ?
                """
                params = (f"%{keyword}%", f"%{keyword}%", limit)
            else:
                query = """
                    SELECT * FROM tags 
                    WHERE is_active = 1 
                    ORDER BY is_system DESC, name ASC 
                    LIMIT ?
                """
                params = (limit,)
            
            results = self.db_service.execute_query(query, params)
            
            return [self._row_to_tag_model(row) for row in results or []]
            
        except Exception as e:
            self.logger.error(f"搜索标签失败: {e}")
            return []

    def get_tags_by_email(self, email_id: int) -> List[TagModel]:
        """
        获取邮箱关联的标签

        Args:
            email_id: 邮箱ID

        Returns:
            标签模型列表
        """
        try:
            query = """
                SELECT t.* FROM tags t
                JOIN email_tags et ON t.id = et.tag_id
                WHERE et.email_id = ? AND t.is_active = 1
                ORDER BY t.name ASC
            """
            results = self.db_service.execute_query(query, (email_id,))

            return [self._row_to_tag_model(row) for row in results or []]

        except Exception as e:
            self.logger.error(f"获取邮箱标签失败: {e}")
            return []

    def get_emails_by_tag(self, tag_id: int, limit: int = 100) -> List[int]:
        """
        获取使用指定标签的邮箱ID列表

        Args:
            tag_id: 标签ID
            limit: 限制数量

        Returns:
            邮箱ID列表
        """
        try:
            query = """
                SELECT et.email_id FROM email_tags et
                JOIN emails e ON et.email_id = e.id
                WHERE et.tag_id = ? AND e.is_active = 1
                ORDER BY e.created_at DESC
                LIMIT ?
            """
            results = self.db_service.execute_query(query, (tag_id, limit))

            return [row["email_id"] for row in results or []]

        except Exception as e:
            self.logger.error(f"获取标签邮箱列表失败: {e}")
            return []

    def batch_create_tags(self, tag_data_list: List[Dict[str, Any]]) -> List[TagModel]:
        """
        批量创建标签

        Args:
            tag_data_list: 标签数据列表，每个元素包含name, description, color, icon

        Returns:
            创建成功的标签模型列表
        """
        created_tags = []

        try:
            for tag_data in tag_data_list:
                try:
                    tag = self.create_tag(
                        name=tag_data.get("name", ""),
                        description=tag_data.get("description", ""),
                        color=tag_data.get("color", "#3498db"),
                        icon=tag_data.get("icon", "🏷️")
                    )
                    if tag:
                        created_tags.append(tag)
                except Exception as e:
                    self.logger.error(f"批量创建标签失败: {tag_data.get('name', 'unknown')}, {e}")
                    continue

            self.logger.info(f"批量创建完成，成功创建 {len(created_tags)} 个标签")
            return created_tags

        except Exception as e:
            self.logger.error(f"批量创建标签失败: {e}")
            return created_tags

    def _save_tag_to_db(self, tag_model: TagModel) -> Optional[int]:
        """保存标签到数据库"""
        try:
            query = """
                INSERT INTO tags (
                    name, description, color, icon,
                    created_at, updated_at, is_system, is_active
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """

            params = (
                tag_model.name,
                tag_model.description,
                tag_model.color,
                tag_model.icon,
                tag_model.created_at.isoformat() if tag_model.created_at else None,
                tag_model.updated_at.isoformat() if tag_model.updated_at else None,
                tag_model.is_system,
                tag_model.is_active
            )

            with self.db_service.get_cursor() as cursor:
                cursor.execute(query, params)
                return cursor.lastrowid

        except Exception as e:
            self.logger.error(f"保存标签到数据库失败: {e}")
            return None

    def _update_tag_in_db(self, tag_model: TagModel) -> bool:
        """更新数据库中的标签信息"""
        try:
            query = """
                UPDATE tags SET
                    name = ?,
                    description = ?,
                    color = ?,
                    icon = ?,
                    updated_at = ?
                WHERE id = ?
            """

            params = (
                tag_model.name,
                tag_model.description,
                tag_model.color,
                tag_model.icon,
                tag_model.updated_at.isoformat() if tag_model.updated_at else None,
                tag_model.id
            )

            affected_rows = self.db_service.execute_update(query, params)
            return affected_rows > 0

        except Exception as e:
            self.logger.error(f"更新标签信息失败: {e}")
            return False

    def _row_to_tag_model(self, row) -> TagModel:
        """将数据库行转换为标签模型"""
        try:
            # 解析时间字段
            def parse_datetime(dt_str):
                if dt_str:
                    try:
                        return datetime.fromisoformat(dt_str)
                    except (ValueError, TypeError):
                        pass
                return None

            return TagModel(
                id=row["id"],
                name=row["name"],
                description=row["description"] or "",
                color=row["color"] or "#3498db",
                icon=row["icon"] or "🏷️",
                created_at=parse_datetime(row["created_at"]),
                updated_at=parse_datetime(row["updated_at"]),
                is_system=bool(row["is_system"]),
                is_active=bool(row["is_active"])
            )

        except Exception as e:
            self.logger.error(f"转换数据库行失败: {e}")
            raise

    def _get_tag_usage_count(self, tag_id: int) -> int:
        """获取标签使用次数"""
        try:
            query = """
                SELECT COUNT(*) as count FROM email_tags et
                JOIN emails e ON et.email_id = e.id
                WHERE et.tag_id = ? AND e.is_active = 1
            """
            result = self.db_service.execute_query(query, (tag_id,), fetch_one=True)
            return result["count"] if result else 0

        except Exception as e:
            self.logger.error(f"获取标签使用次数失败: {e}")
            return 0
