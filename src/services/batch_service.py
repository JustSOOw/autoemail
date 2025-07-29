# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 批量操作服务
专门处理邮箱和标签的批量操作功能
"""

from datetime import datetime
from typing import List, Dict, Any, Optional, Tuple
import json

from models.email_model import EmailModel, EmailStatus, create_email_model
from models.tag_model import TagModel, create_tag_model
from models.config_model import ConfigModel
from services.database_service import DatabaseService
from services.email_generator import EmailGenerator
from utils.logger import get_logger


class BatchService:
    """
    批量操作服务类
    
    提供邮箱和标签的批量创建、更新、删除等操作
    """

    def __init__(self, db_service: DatabaseService, config: ConfigModel):
        """
        初始化批量操作服务
        
        Args:
            db_service: 数据库服务实例
            config: 配置模型实例
        """
        self.db_service = db_service
        self.config = config
        self.logger = get_logger(__name__)
        
        # 初始化邮箱生成器
        self.email_generator = EmailGenerator(config)
        
        self.logger.info("批量操作服务初始化完成")

    def batch_create_emails(self, 
                           count: int,
                           prefix_type: str = "random_name",
                           base_prefix: str = "",
                           tags: Optional[List[str]] = None,
                           notes: str = "",
                           created_by: str = "batch_system") -> Dict[str, Any]:
        """
        批量创建邮箱
        
        Args:
            count: 创建数量
            prefix_type: 前缀类型 ("random_name", "sequence", "timestamp", "custom")
            base_prefix: 基础前缀（用于sequence和custom类型）
            tags: 标签列表
            notes: 备注信息
            created_by: 创建者
            
        Returns:
            批量创建结果
        """
        result = {
            "total": count,
            "success": 0,
            "failed": 0,
            "emails": [],
            "errors": []
        }
        
        try:
            for i in range(count):
                try:
                    # 生成邮箱地址
                    if prefix_type == "sequence":
                        custom_prefix = f"{base_prefix}_{i+1:03d}" if base_prefix else f"email_{i+1:03d}"
                        email_address = self.email_generator.generate_email(
                            prefix_type="custom",
                            custom_prefix=custom_prefix,
                            add_timestamp=True
                        )
                    elif prefix_type == "custom":
                        email_address = self.email_generator.generate_email(
                            prefix_type="custom",
                            custom_prefix=base_prefix,
                            add_timestamp=True
                        )
                    else:
                        email_address = self.email_generator.generate_email(
                            prefix_type=prefix_type,
                            add_timestamp=True
                        )
                    
                    # 创建邮箱模型
                    email_model = create_email_model(
                        email_address=email_address,
                        tags=tags or [],
                        notes=notes,
                        created_by=created_by
                    )
                    
                    # 保存到数据库
                    email_id = self._save_email_to_db(email_model)
                    if email_id:
                        email_model.id = email_id
                        result["emails"].append(email_model)
                        result["success"] += 1
                    else:
                        result["failed"] += 1
                        result["errors"].append(f"邮箱 {i+1}: 保存失败")
                        
                except Exception as e:
                    result["failed"] += 1
                    result["errors"].append(f"邮箱 {i+1}: {str(e)}")
            
            self.logger.info(f"批量创建邮箱完成: 成功 {result['success']}, 失败 {result['failed']}")
            return result
            
        except Exception as e:
            self.logger.error(f"批量创建邮箱失败: {e}")
            result["errors"].append(str(e))
            return result

    def batch_update_emails(self, 
                           email_ids: List[int],
                           updates: Dict[str, Any]) -> Dict[str, Any]:
        """
        批量更新邮箱
        
        Args:
            email_ids: 邮箱ID列表
            updates: 更新字段字典
            
        Returns:
            批量更新结果
        """
        result = {
            "total": len(email_ids),
            "success": 0,
            "failed": 0,
            "errors": []
        }
        
        try:
            # 验证更新字段
            allowed_fields = ["status", "notes", "last_used"]
            update_fields = {k: v for k, v in updates.items() if k in allowed_fields}
            
            if not update_fields:
                result["errors"].append("没有有效的更新字段")
                return result
            
            # 构建更新查询
            set_clauses = []
            params = []
            
            for field, value in update_fields.items():
                if field == "status" and isinstance(value, str):
                    # 验证状态值
                    try:
                        EmailStatus(value)
                        set_clauses.append(f"{field} = ?")
                        params.append(value)
                    except ValueError:
                        result["errors"].append(f"无效的状态值: {value}")
                        continue
                else:
                    set_clauses.append(f"{field} = ?")
                    params.append(value)
            
            if not set_clauses:
                result["errors"].append("没有有效的更新字段")
                return result
            
            # 添加更新时间
            set_clauses.append("updated_at = ?")
            params.append(datetime.now().isoformat())
            
            # 批量更新
            for email_id in email_ids:
                try:
                    query = f"""
                        UPDATE emails 
                        SET {', '.join(set_clauses)}
                        WHERE id = ? AND is_active = 1
                    """
                    update_params = params + [email_id]
                    
                    affected_rows = self.db_service.execute_update(query, update_params)
                    
                    if affected_rows > 0:
                        result["success"] += 1
                    else:
                        result["failed"] += 1
                        result["errors"].append(f"邮箱 {email_id}: 更新失败或不存在")
                        
                except Exception as e:
                    result["failed"] += 1
                    result["errors"].append(f"邮箱 {email_id}: {str(e)}")
            
            self.logger.info(f"批量更新邮箱完成: 成功 {result['success']}, 失败 {result['failed']}")
            return result
            
        except Exception as e:
            self.logger.error(f"批量更新邮箱失败: {e}")
            result["errors"].append(str(e))
            return result

    def batch_delete_emails(self, email_ids: List[int], hard_delete: bool = False) -> Dict[str, Any]:
        """
        批量删除邮箱
        
        Args:
            email_ids: 邮箱ID列表
            hard_delete: 是否硬删除（物理删除）
            
        Returns:
            批量删除结果
        """
        result = {
            "total": len(email_ids),
            "success": 0,
            "failed": 0,
            "errors": []
        }
        
        try:
            for email_id in email_ids:
                try:
                    if hard_delete:
                        # 硬删除：先删除关联的标签，再删除邮箱
                        with self.db_service.get_cursor() as cursor:
                            cursor.execute("DELETE FROM email_tags WHERE email_id = ?", (email_id,))
                            cursor.execute("DELETE FROM emails WHERE id = ?", (email_id,))
                            
                            if cursor.rowcount > 0:
                                result["success"] += 1
                            else:
                                result["failed"] += 1
                                result["errors"].append(f"邮箱 {email_id}: 删除失败或不存在")
                    else:
                        # 软删除
                        query = "UPDATE emails SET is_active = 0, updated_at = ? WHERE id = ?"
                        affected_rows = self.db_service.execute_update(
                            query, 
                            (datetime.now().isoformat(), email_id)
                        )
                        
                        if affected_rows > 0:
                            result["success"] += 1
                        else:
                            result["failed"] += 1
                            result["errors"].append(f"邮箱 {email_id}: 删除失败或不存在")
                            
                except Exception as e:
                    result["failed"] += 1
                    result["errors"].append(f"邮箱 {email_id}: {str(e)}")
            
            self.logger.info(f"批量删除邮箱完成: 成功 {result['success']}, 失败 {result['failed']}")
            return result
            
        except Exception as e:
            self.logger.error(f"批量删除邮箱失败: {e}")
            result["errors"].append(str(e))
            return result

    def batch_apply_tags(self, 
                        email_ids: List[int], 
                        tag_names: List[str],
                        operation: str = "add") -> Dict[str, Any]:
        """
        批量应用标签操作
        
        Args:
            email_ids: 邮箱ID列表
            tag_names: 标签名称列表
            operation: 操作类型 ("add", "remove", "replace")
            
        Returns:
            批量操作结果
        """
        result = {
            "total_emails": len(email_ids),
            "total_tags": len(tag_names),
            "success_emails": 0,
            "failed_emails": 0,
            "errors": []
        }
        
        try:
            # 获取标签ID
            tag_ids = []
            for tag_name in tag_names:
                tag_query = "SELECT id FROM tags WHERE name = ? AND is_active = 1"
                tag_result = self.db_service.execute_query(tag_query, (tag_name,), fetch_one=True)
                
                if tag_result:
                    tag_ids.append(tag_result["id"])
                else:
                    result["errors"].append(f"标签不存在: {tag_name}")
            
            if not tag_ids:
                result["errors"].append("没有有效的标签")
                return result
            
            # 批量操作
            for email_id in email_ids:
                try:
                    if operation == "add":
                        success = self._add_tags_to_email(email_id, tag_ids)
                    elif operation == "remove":
                        success = self._remove_tags_from_email(email_id, tag_ids)
                    elif operation == "replace":
                        success = self._replace_email_tags(email_id, tag_ids)
                    else:
                        result["errors"].append(f"邮箱 {email_id}: 无效的操作类型 {operation}")
                        result["failed_emails"] += 1
                        continue
                    
                    if success:
                        result["success_emails"] += 1
                    else:
                        result["failed_emails"] += 1
                        result["errors"].append(f"邮箱 {email_id}: 标签操作失败")
                        
                except Exception as e:
                    result["failed_emails"] += 1
                    result["errors"].append(f"邮箱 {email_id}: {str(e)}")
            
            self.logger.info(f"批量标签操作完成: 成功 {result['success_emails']}, 失败 {result['failed_emails']}")
            return result
            
        except Exception as e:
            self.logger.error(f"批量标签操作失败: {e}")
            result["errors"].append(str(e))
            return result

    def batch_create_tags(self, tag_data_list: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        批量创建标签

        Args:
            tag_data_list: 标签数据列表，每个元素包含name, description, color, icon

        Returns:
            批量创建结果
        """
        result = {
            "total": len(tag_data_list),
            "success": 0,
            "failed": 0,
            "tags": [],
            "errors": []
        }

        try:
            for i, tag_data in enumerate(tag_data_list):
                try:
                    # 验证必需字段
                    if not tag_data.get("name"):
                        result["failed"] += 1
                        result["errors"].append(f"标签 {i+1}: 缺少名称")
                        continue

                    # 检查标签名称是否已存在
                    existing_query = "SELECT id FROM tags WHERE name = ? AND is_active = 1"
                    existing = self.db_service.execute_query(
                        existing_query,
                        (tag_data["name"],),
                        fetch_one=True
                    )

                    if existing:
                        result["failed"] += 1
                        result["errors"].append(f"标签 {i+1}: 名称已存在 - {tag_data['name']}")
                        continue

                    # 创建标签模型
                    tag_model = create_tag_model(
                        name=tag_data["name"],
                        description=tag_data.get("description", ""),
                        color=tag_data.get("color", "#3498db"),
                        icon=tag_data.get("icon", "🏷️")
                    )

                    # 保存到数据库
                    tag_id = self._save_tag_to_db(tag_model)
                    if tag_id:
                        tag_model.id = tag_id
                        result["tags"].append(tag_model)
                        result["success"] += 1
                    else:
                        result["failed"] += 1
                        result["errors"].append(f"标签 {i+1}: 保存失败")

                except Exception as e:
                    result["failed"] += 1
                    result["errors"].append(f"标签 {i+1}: {str(e)}")

            self.logger.info(f"批量创建标签完成: 成功 {result['success']}, 失败 {result['failed']}")
            return result

        except Exception as e:
            self.logger.error(f"批量创建标签失败: {e}")
            result["errors"].append(str(e))
            return result

    def batch_import_emails_from_data(self,
                                     import_data: List[Dict[str, Any]],
                                     conflict_strategy: str = "skip") -> Dict[str, Any]:
        """
        从数据批量导入邮箱

        Args:
            import_data: 导入数据列表
            conflict_strategy: 冲突处理策略 ("skip", "update", "error")

        Returns:
            批量导入结果
        """
        result = {
            "total": len(import_data),
            "success": 0,
            "failed": 0,
            "skipped": 0,
            "updated": 0,
            "emails": [],
            "errors": []
        }

        try:
            for i, email_data in enumerate(import_data):
                try:
                    email_address = email_data.get("email_address")
                    if not email_address:
                        result["failed"] += 1
                        result["errors"].append(f"邮箱 {i+1}: 缺少邮箱地址")
                        continue

                    # 检查邮箱是否已存在
                    existing_query = "SELECT id FROM emails WHERE email_address = ?"
                    existing = self.db_service.execute_query(
                        existing_query,
                        (email_address,),
                        fetch_one=True
                    )

                    if existing:
                        if conflict_strategy == "skip":
                            result["skipped"] += 1
                            continue
                        elif conflict_strategy == "update":
                            # 更新现有邮箱
                            update_success = self._update_existing_email(existing["id"], email_data)
                            if update_success:
                                result["updated"] += 1
                            else:
                                result["failed"] += 1
                                result["errors"].append(f"邮箱 {i+1}: 更新失败")
                            continue
                        else:  # error
                            result["failed"] += 1
                            result["errors"].append(f"邮箱 {i+1}: 邮箱地址已存在 - {email_address}")
                            continue

                    # 创建新邮箱
                    email_model = create_email_model(
                        email_address=email_address,
                        tags=email_data.get("tags", []),
                        notes=email_data.get("notes", ""),
                        created_by=email_data.get("created_by", "import_system")
                    )

                    # 设置其他字段
                    if email_data.get("status"):
                        try:
                            email_model.status = EmailStatus(email_data["status"])
                        except ValueError:
                            pass

                    if email_data.get("created_at"):
                        try:
                            email_model.created_at = datetime.fromisoformat(email_data["created_at"])
                        except ValueError:
                            pass

                    # 保存到数据库
                    email_id = self._save_email_to_db(email_model)
                    if email_id:
                        email_model.id = email_id
                        result["emails"].append(email_model)
                        result["success"] += 1
                    else:
                        result["failed"] += 1
                        result["errors"].append(f"邮箱 {i+1}: 保存失败")

                except Exception as e:
                    result["failed"] += 1
                    result["errors"].append(f"邮箱 {i+1}: {str(e)}")

            self.logger.info(f"批量导入邮箱完成: 成功 {result['success']}, 失败 {result['failed']}, 跳过 {result['skipped']}, 更新 {result['updated']}")
            return result

        except Exception as e:
            self.logger.error(f"批量导入邮箱失败: {e}")
            result["errors"].append(str(e))
            return result

    # ==================== 私有辅助方法 ====================

    def _save_email_to_db(self, email_model: EmailModel) -> Optional[int]:
        """保存邮箱到数据库"""
        try:
            query = """
                INSERT INTO emails (
                    email_address, domain, prefix, timestamp_suffix,
                    created_at, last_used, updated_at, status,
                    notes, metadata, is_active, created_by
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """

            params = (
                email_model.email_address,
                email_model.domain,
                email_model.prefix,
                email_model.timestamp_suffix,
                email_model.created_at.isoformat() if email_model.created_at else None,
                email_model.last_used.isoformat() if email_model.last_used else None,
                email_model.updated_at.isoformat() if email_model.updated_at else None,
                email_model.status.value,
                email_model.notes,
                json.dumps(email_model.metadata) if email_model.metadata else None,
                email_model.is_active,
                email_model.created_by
            )

            with self.db_service.get_cursor() as cursor:
                cursor.execute(query, params)
                email_id = cursor.lastrowid

                # 保存标签关联
                if email_model.tags:
                    self._save_email_tags(cursor, email_id, email_model.tags)

                return email_id

        except Exception as e:
            self.logger.error(f"保存邮箱到数据库失败: {e}")
            return None

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

    def _save_email_tags(self, cursor, email_id: int, tag_names: List[str]):
        """保存邮箱标签关联"""
        try:
            for tag_name in tag_names:
                # 获取或创建标签
                tag_query = "SELECT id FROM tags WHERE name = ? AND is_active = 1"
                tag_result = cursor.execute(tag_query, (tag_name,)).fetchone()

                if tag_result:
                    tag_id = tag_result[0]
                else:
                    # 创建新标签
                    create_tag_query = """
                        INSERT INTO tags (name, description, color, icon, created_at, updated_at, is_system, is_active)
                        VALUES (?, '', '#3498db', '🏷️', ?, ?, 0, 1)
                    """
                    current_time = datetime.now().isoformat()
                    cursor.execute(create_tag_query, (tag_name, current_time, current_time))
                    tag_id = cursor.lastrowid

                # 创建关联
                relation_query = """
                    INSERT OR IGNORE INTO email_tags (email_id, tag_id, created_at)
                    VALUES (?, ?, ?)
                """
                cursor.execute(relation_query, (email_id, tag_id, datetime.now().isoformat()))

        except Exception as e:
            self.logger.error(f"保存邮箱标签关联失败: {e}")
            raise

    def _add_tags_to_email(self, email_id: int, tag_ids: List[int]) -> bool:
        """为邮箱添加标签"""
        try:
            with self.db_service.get_cursor() as cursor:
                for tag_id in tag_ids:
                    # 检查关联是否已存在
                    check_query = "SELECT 1 FROM email_tags WHERE email_id = ? AND tag_id = ?"
                    existing = cursor.execute(check_query, (email_id, tag_id)).fetchone()

                    if not existing:
                        # 添加关联
                        insert_query = """
                            INSERT INTO email_tags (email_id, tag_id, created_at)
                            VALUES (?, ?, ?)
                        """
                        cursor.execute(insert_query, (email_id, tag_id, datetime.now().isoformat()))

                return True

        except Exception as e:
            self.logger.error(f"为邮箱添加标签失败: {e}")
            return False

    def _remove_tags_from_email(self, email_id: int, tag_ids: List[int]) -> bool:
        """从邮箱移除标签"""
        try:
            with self.db_service.get_cursor() as cursor:
                for tag_id in tag_ids:
                    delete_query = "DELETE FROM email_tags WHERE email_id = ? AND tag_id = ?"
                    cursor.execute(delete_query, (email_id, tag_id))

                return True

        except Exception as e:
            self.logger.error(f"从邮箱移除标签失败: {e}")
            return False

    def _replace_email_tags(self, email_id: int, tag_ids: List[int]) -> bool:
        """替换邮箱的所有标签"""
        try:
            with self.db_service.get_cursor() as cursor:
                # 删除现有标签关联
                cursor.execute("DELETE FROM email_tags WHERE email_id = ?", (email_id,))

                # 添加新的标签关联
                if tag_ids:
                    insert_query = """
                        INSERT INTO email_tags (email_id, tag_id, created_at)
                        VALUES (?, ?, ?)
                    """
                    current_time = datetime.now().isoformat()

                    for tag_id in tag_ids:
                        cursor.execute(insert_query, (email_id, tag_id, current_time))

                return True

        except Exception as e:
            self.logger.error(f"替换邮箱标签失败: {e}")
            return False

    def _update_existing_email(self, email_id: int, email_data: Dict[str, Any]) -> bool:
        """更新现有邮箱"""
        try:
            # 构建更新字段
            update_fields = []
            params = []

            if email_data.get("notes"):
                update_fields.append("notes = ?")
                params.append(email_data["notes"])

            if email_data.get("status"):
                try:
                    EmailStatus(email_data["status"])
                    update_fields.append("status = ?")
                    params.append(email_data["status"])
                except ValueError:
                    pass

            if not update_fields:
                return True  # 没有需要更新的字段

            # 添加更新时间
            update_fields.append("updated_at = ?")
            params.append(datetime.now().isoformat())
            params.append(email_id)

            # 执行更新
            query = f"UPDATE emails SET {', '.join(update_fields)} WHERE id = ?"
            affected_rows = self.db_service.execute_update(query, params)

            # 更新标签
            if email_data.get("tags"):
                # 获取标签ID
                tag_ids = []
                for tag_name in email_data["tags"]:
                    tag_query = "SELECT id FROM tags WHERE name = ? AND is_active = 1"
                    tag_result = self.db_service.execute_query(tag_query, (tag_name,), fetch_one=True)
                    if tag_result:
                        tag_ids.append(tag_result["id"])

                if tag_ids:
                    self._replace_email_tags(email_id, tag_ids)

            return affected_rows > 0

        except Exception as e:
            self.logger.error(f"更新现有邮箱失败: {e}")
            return False
