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

    # ==================== Phase 3A: 高级标签功能 ====================

    def add_tag_to_email(self, email_id: int, tag_id: int) -> bool:
        """
        为邮箱添加标签

        Args:
            email_id: 邮箱ID
            tag_id: 标签ID

        Returns:
            是否添加成功
        """
        try:
            # 检查关联是否已存在
            check_query = "SELECT 1 FROM email_tags WHERE email_id = ? AND tag_id = ?"
            existing = self.db_service.execute_query(check_query, (email_id, tag_id), fetch_one=True)

            if existing:
                self.logger.warning(f"邮箱 {email_id} 已关联标签 {tag_id}")
                return True

            # 添加关联
            insert_query = """
                INSERT INTO email_tags (email_id, tag_id, created_at)
                VALUES (?, ?, ?)
            """
            affected_rows = self.db_service.execute_update(
                insert_query,
                (email_id, tag_id, datetime.now().isoformat())
            )

            success = affected_rows > 0
            if success:
                self.logger.info(f"成功为邮箱 {email_id} 添加标签 {tag_id}")

            return success

        except Exception as e:
            self.logger.error(f"为邮箱添加标签失败: {e}")
            return False

    def remove_tag_from_email(self, email_id: int, tag_id: int) -> bool:
        """
        从邮箱移除标签

        Args:
            email_id: 邮箱ID
            tag_id: 标签ID

        Returns:
            是否移除成功
        """
        try:
            query = "DELETE FROM email_tags WHERE email_id = ? AND tag_id = ?"
            affected_rows = self.db_service.execute_update(query, (email_id, tag_id))

            success = affected_rows > 0
            if success:
                self.logger.info(f"成功从邮箱 {email_id} 移除标签 {tag_id}")

            return success

        except Exception as e:
            self.logger.error(f"从邮箱移除标签失败: {e}")
            return False

    def batch_add_tags_to_email(self, email_id: int, tag_ids: List[int]) -> Dict[str, Any]:
        """
        批量为邮箱添加标签

        Args:
            email_id: 邮箱ID
            tag_ids: 标签ID列表

        Returns:
            操作结果统计
        """
        result = {
            "total": len(tag_ids),
            "success": 0,
            "failed": 0,
            "skipped": 0,
            "errors": []
        }

        try:
            for tag_id in tag_ids:
                try:
                    if self.add_tag_to_email(email_id, tag_id):
                        result["success"] += 1
                    else:
                        result["skipped"] += 1
                except Exception as e:
                    result["failed"] += 1
                    result["errors"].append(f"标签 {tag_id}: {str(e)}")

            self.logger.info(f"批量添加标签完成: 成功 {result['success']}, 跳过 {result['skipped']}, 失败 {result['failed']}")
            return result

        except Exception as e:
            self.logger.error(f"批量添加标签失败: {e}")
            result["errors"].append(str(e))
            return result

    def batch_remove_tags_from_email(self, email_id: int, tag_ids: List[int]) -> Dict[str, Any]:
        """
        批量从邮箱移除标签

        Args:
            email_id: 邮箱ID
            tag_ids: 标签ID列表

        Returns:
            操作结果统计
        """
        result = {
            "total": len(tag_ids),
            "success": 0,
            "failed": 0,
            "errors": []
        }

        try:
            for tag_id in tag_ids:
                try:
                    if self.remove_tag_from_email(email_id, tag_id):
                        result["success"] += 1
                    else:
                        result["failed"] += 1
                except Exception as e:
                    result["failed"] += 1
                    result["errors"].append(f"标签 {tag_id}: {str(e)}")

            self.logger.info(f"批量移除标签完成: 成功 {result['success']}, 失败 {result['failed']}")
            return result

        except Exception as e:
            self.logger.error(f"批量移除标签失败: {e}")
            result["errors"].append(str(e))
            return result

    def replace_email_tags(self, email_id: int, new_tag_ids: List[int]) -> bool:
        """
        替换邮箱的所有标签

        Args:
            email_id: 邮箱ID
            new_tag_ids: 新的标签ID列表

        Returns:
            是否替换成功
        """
        try:
            # 开始事务
            with self.db_service.get_cursor() as cursor:
                # 删除现有标签关联
                cursor.execute("DELETE FROM email_tags WHERE email_id = ?", (email_id,))

                # 添加新的标签关联
                if new_tag_ids:
                    insert_query = """
                        INSERT INTO email_tags (email_id, tag_id, created_at)
                        VALUES (?, ?, ?)
                    """
                    current_time = datetime.now().isoformat()

                    for tag_id in new_tag_ids:
                        cursor.execute(insert_query, (email_id, tag_id, current_time))

                self.logger.info(f"成功替换邮箱 {email_id} 的标签，新标签数: {len(new_tag_ids)}")
                return True

        except Exception as e:
            self.logger.error(f"替换邮箱标签失败: {e}")
            return False

    def batch_apply_tags_to_emails(self, email_ids: List[int], tag_ids: List[int]) -> Dict[str, Any]:
        """
        批量为多个邮箱应用标签

        Args:
            email_ids: 邮箱ID列表
            tag_ids: 标签ID列表

        Returns:
            操作结果统计
        """
        result = {
            "total_emails": len(email_ids),
            "total_tags": len(tag_ids),
            "success_emails": 0,
            "failed_emails": 0,
            "total_operations": len(email_ids) * len(tag_ids),
            "success_operations": 0,
            "errors": []
        }

        try:
            for email_id in email_ids:
                try:
                    batch_result = self.batch_add_tags_to_email(email_id, tag_ids)
                    result["success_operations"] += batch_result["success"]
                    result["success_emails"] += 1

                    if batch_result["errors"]:
                        result["errors"].extend([f"邮箱 {email_id}: {error}" for error in batch_result["errors"]])

                except Exception as e:
                    result["failed_emails"] += 1
                    result["errors"].append(f"邮箱 {email_id}: {str(e)}")

            self.logger.info(f"批量应用标签完成: 成功邮箱 {result['success_emails']}, 失败邮箱 {result['failed_emails']}")
            return result

        except Exception as e:
            self.logger.error(f"批量应用标签失败: {e}")
            result["errors"].append(str(e))
            return result

    def get_tag_usage_details(self, tag_id: int) -> Dict[str, Any]:
        """
        获取标签使用详情

        Args:
            tag_id: 标签ID

        Returns:
            标签使用详情
        """
        try:
            tag = self.get_tag_by_id(tag_id)
            if not tag:
                return {}

            # 基本信息
            details = {
                "tag": {
                    "id": tag.id,
                    "name": tag.name,
                    "description": tag.description,
                    "color": tag.color,
                    "icon": tag.icon,
                    "is_system": tag.is_system,
                    "created_at": tag.created_at.isoformat() if tag.created_at else None
                },
                "usage": {
                    "total_emails": 0,
                    "active_emails": 0,
                    "archived_emails": 0,
                    "recent_usage": []
                }
            }

            # 使用统计
            usage_query = """
                SELECT
                    COUNT(*) as total_emails,
                    SUM(CASE WHEN e.status = 'active' THEN 1 ELSE 0 END) as active_emails,
                    SUM(CASE WHEN e.status = 'archived' THEN 1 ELSE 0 END) as archived_emails
                FROM email_tags et
                JOIN emails e ON et.email_id = e.id
                WHERE et.tag_id = ? AND e.is_active = 1
            """
            usage_result = self.db_service.execute_query(usage_query, (tag_id,), fetch_one=True)

            if usage_result:
                details["usage"]["total_emails"] = usage_result["total_emails"] or 0
                details["usage"]["active_emails"] = usage_result["active_emails"] or 0
                details["usage"]["archived_emails"] = usage_result["archived_emails"] or 0

            # 最近使用的邮箱
            recent_query = """
                SELECT e.email_address, e.created_at, e.status
                FROM email_tags et
                JOIN emails e ON et.email_id = e.id
                WHERE et.tag_id = ? AND e.is_active = 1
                ORDER BY et.created_at DESC
                LIMIT 10
            """
            recent_results = self.db_service.execute_query(recent_query, (tag_id,))

            details["usage"]["recent_usage"] = [
                {
                    "email_address": row["email_address"],
                    "created_at": row["created_at"],
                    "status": row["status"]
                }
                for row in recent_results or []
            ]

            return details

        except Exception as e:
            self.logger.error(f"获取标签使用详情失败: {e}")
            return {}

    def get_unused_tags(self) -> List[TagModel]:
        """
        获取未使用的标签

        Returns:
            未使用的标签列表
        """
        try:
            query = """
                SELECT t.* FROM tags t
                LEFT JOIN email_tags et ON t.id = et.tag_id
                WHERE t.is_active = 1 AND et.tag_id IS NULL
                ORDER BY t.created_at DESC
            """
            results = self.db_service.execute_query(query)

            return [self._row_to_tag_model(row) for row in results or []]

        except Exception as e:
            self.logger.error(f"获取未使用标签失败: {e}")
            return []

    def merge_tags(self, source_tag_id: int, target_tag_id: int, delete_source: bool = True) -> bool:
        """
        合并标签（将源标签的所有关联转移到目标标签）

        Args:
            source_tag_id: 源标签ID
            target_tag_id: 目标标签ID
            delete_source: 是否删除源标签

        Returns:
            是否合并成功
        """
        try:
            # 检查标签是否存在
            source_tag = self.get_tag_by_id(source_tag_id)
            target_tag = self.get_tag_by_id(target_tag_id)

            if not source_tag or not target_tag:
                self.logger.error("源标签或目标标签不存在")
                return False

            if source_tag.is_system or target_tag.is_system:
                self.logger.error("不能合并系统标签")
                return False

            # 开始事务
            with self.db_service.get_cursor() as cursor:
                # 获取源标签的所有邮箱关联
                cursor.execute(
                    "SELECT email_id FROM email_tags WHERE tag_id = ?",
                    (source_tag_id,)
                )
                email_ids = [row[0] for row in cursor.fetchall()]

                # 为这些邮箱添加目标标签（如果还没有的话）
                for email_id in email_ids:
                    # 检查是否已经有目标标签
                    cursor.execute(
                        "SELECT 1 FROM email_tags WHERE email_id = ? AND tag_id = ?",
                        (email_id, target_tag_id)
                    )

                    if not cursor.fetchone():
                        # 添加目标标签关联
                        cursor.execute(
                            "INSERT INTO email_tags (email_id, tag_id, created_at) VALUES (?, ?, ?)",
                            (email_id, target_tag_id, datetime.now().isoformat())
                        )

                # 删除源标签的所有关联
                cursor.execute("DELETE FROM email_tags WHERE tag_id = ?", (source_tag_id,))

                # 如果需要，删除源标签
                if delete_source:
                    cursor.execute(
                        "UPDATE tags SET is_active = 0, updated_at = ? WHERE id = ?",
                        (datetime.now().isoformat(), source_tag_id)
                    )

                self.logger.info(f"成功合并标签: {source_tag.name} -> {target_tag.name}")
                return True

        except Exception as e:
            self.logger.error(f"合并标签失败: {e}")
            return False

    def export_tags(self, format_type: str = "json", include_usage: bool = False) -> str:
        """
        导出标签数据

        Args:
            format_type: 导出格式 ("json" 或 "csv")
            include_usage: 是否包含使用统计

        Returns:
            导出的数据字符串
        """
        try:
            tags = self.get_all_tags()

            if format_type.lower() == "csv":
                return self._export_tags_csv(tags, include_usage)
            else:
                return self._export_tags_json(tags, include_usage)

        except Exception as e:
            self.logger.error(f"导出标签失败: {e}")
            return ""

    def _export_tags_json(self, tags: List[TagModel], include_usage: bool) -> str:
        """导出标签为JSON格式"""
        import json

        try:
            export_data = []

            for tag in tags:
                tag_data = {
                    "id": tag.id,
                    "name": tag.name,
                    "description": tag.description,
                    "color": tag.color,
                    "icon": tag.icon,
                    "is_system": tag.is_system,
                    "created_at": tag.created_at.isoformat() if tag.created_at else None,
                    "updated_at": tag.updated_at.isoformat() if tag.updated_at else None
                }

                if include_usage:
                    usage_count = self._get_tag_usage_count(tag.id)
                    tag_data["usage_count"] = usage_count

                export_data.append(tag_data)

            return json.dumps(export_data, ensure_ascii=False, indent=2)

        except Exception as e:
            self.logger.error(f"导出JSON格式失败: {e}")
            return ""

    def _export_tags_csv(self, tags: List[TagModel], include_usage: bool) -> str:
        """导出标签为CSV格式"""
        import csv
        import io

        try:
            output = io.StringIO()

            # 定义CSV列
            fieldnames = ["id", "name", "description", "color", "icon", "is_system", "created_at", "updated_at"]
            if include_usage:
                fieldnames.append("usage_count")

            writer = csv.DictWriter(output, fieldnames=fieldnames)
            writer.writeheader()

            for tag in tags:
                row_data = {
                    "id": tag.id,
                    "name": tag.name,
                    "description": tag.description,
                    "color": tag.color,
                    "icon": tag.icon,
                    "is_system": tag.is_system,
                    "created_at": tag.created_at.isoformat() if tag.created_at else "",
                    "updated_at": tag.updated_at.isoformat() if tag.updated_at else ""
                }

                if include_usage:
                    usage_count = self._get_tag_usage_count(tag.id)
                    row_data["usage_count"] = usage_count

                writer.writerow(row_data)

            return output.getvalue()

        except Exception as e:
            self.logger.error(f"导出CSV格式失败: {e}")
            return ""

    def get_tags_with_pagination(self, page: int = 1, page_size: int = 20,
                                keyword: str = "", sort_by: str = "name",
                                sort_order: str = "asc") -> Dict[str, Any]:
        """
        分页获取标签列表

        Args:
            page: 页码（从1开始）
            page_size: 每页大小
            keyword: 搜索关键词
            sort_by: 排序字段 ("name", "created_at", "usage_count")
            sort_order: 排序方向 ("asc", "desc")

        Returns:
            分页结果
        """
        try:
            # 计算偏移量
            offset = (page - 1) * page_size

            # 构建查询条件
            where_clause = "WHERE t.is_active = 1"
            params = []

            if keyword:
                where_clause += " AND (t.name LIKE ? OR t.description LIKE ?)"
                params.extend([f"%{keyword}%", f"%{keyword}%"])

            # 构建排序子句
            sort_column = "t.name"
            if sort_by == "created_at":
                sort_column = "t.created_at"
            elif sort_by == "usage_count":
                sort_column = "usage_count"

            sort_direction = "ASC" if sort_order.lower() == "asc" else "DESC"

            # 查询总数
            count_query = f"""
                SELECT COUNT(*) as total FROM tags t
                {where_clause}
            """
            count_result = self.db_service.execute_query(count_query, params, fetch_one=True)
            total = count_result["total"] if count_result else 0

            # 查询数据
            data_query = f"""
                SELECT t.*,
                       COALESCE(usage_stats.usage_count, 0) as usage_count
                FROM tags t
                LEFT JOIN (
                    SELECT et.tag_id, COUNT(*) as usage_count
                    FROM email_tags et
                    JOIN emails e ON et.email_id = e.id
                    WHERE e.is_active = 1
                    GROUP BY et.tag_id
                ) usage_stats ON t.id = usage_stats.tag_id
                {where_clause}
                ORDER BY {sort_column} {sort_direction}
                LIMIT ? OFFSET ?
            """
            params.extend([page_size, offset])

            results = self.db_service.execute_query(data_query, params)

            # 转换为标签模型
            tags = []
            for row in results or []:
                tag = self._row_to_tag_model(row)
                # 添加使用统计
                tag.usage_count = row["usage_count"]
                tags.append(tag)

            # 计算分页信息
            total_pages = (total + page_size - 1) // page_size

            return {
                "tags": tags,
                "pagination": {
                    "current_page": page,
                    "page_size": page_size,
                    "total_items": total,
                    "total_pages": total_pages,
                    "has_next": page < total_pages,
                    "has_prev": page > 1
                },
                "filters": {
                    "keyword": keyword,
                    "sort_by": sort_by,
                    "sort_order": sort_order
                }
            }

        except Exception as e:
            self.logger.error(f"分页获取标签失败: {e}")
            return {
                "tags": [],
                "pagination": {
                    "current_page": 1,
                    "page_size": page_size,
                    "total_items": 0,
                    "total_pages": 0,
                    "has_next": False,
                    "has_prev": False
                },
                "filters": {
                    "keyword": keyword,
                    "sort_by": sort_by,
                    "sort_order": sort_order
                }
            }
