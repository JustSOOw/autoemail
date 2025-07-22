# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 简化邮箱服务
专注于邮箱生成、存储和管理的核心功能
"""

import json
from datetime import datetime
from typing import List, Optional, Dict, Any

from models.email_model import EmailModel, EmailStatus, create_email_model
from models.config_model import ConfigModel
from services.database_service import DatabaseService
from services.email_generator import EmailGenerator
from utils.logger import get_logger


class EmailService:
    """
    简化邮箱服务类
    
    提供邮箱生成、存储和管理的核心功能
    """

    def __init__(self, config: ConfigModel, db_service: DatabaseService):
        """
        初始化邮箱服务
        
        Args:
            config: 配置模型实例
            db_service: 数据库服务实例
        """
        self.config = config
        self.db_service = db_service
        self.logger = get_logger(__name__)
        
        # 初始化邮箱生成器
        self.email_generator = EmailGenerator(config)
        
        self.logger.info("简化邮箱服务初始化完成")

    def create_email(self, 
                    prefix_type: str = "random_name",
                    custom_prefix: Optional[str] = None,
                    tags: Optional[List[str]] = None,
                    notes: str = "") -> EmailModel:
        """
        创建新邮箱
        
        Args:
            prefix_type: 前缀类型
            custom_prefix: 自定义前缀
            tags: 标签列表
            notes: 备注
            
        Returns:
            创建的邮箱模型
        """
        try:
            # 生成邮箱地址
            email_address = self.email_generator.generate_email(
                prefix_type=prefix_type,
                custom_prefix=custom_prefix,
                add_timestamp=True
            )
            
            # 创建邮箱模型
            email_model = create_email_model(
                email_address=email_address,
                tags=tags or [],
                notes=notes
            )
            
            # 保存到数据库
            email_id = self._save_email_to_db(email_model)
            email_model.id = email_id
            
            self.logger.info(f"成功创建邮箱: {email_address}")
            return email_model
            
        except Exception as e:
            self.logger.error(f"创建邮箱失败: {e}")
            raise

    def get_email_by_id(self, email_id: int) -> Optional[EmailModel]:
        """
        根据ID获取邮箱
        
        Args:
            email_id: 邮箱ID
            
        Returns:
            邮箱模型或None
        """
        try:
            query = "SELECT * FROM emails WHERE id = ? AND is_active = 1"
            result = self.db_service.execute_query(query, (email_id,), fetch_one=True)
            
            if result:
                return self._row_to_email_model(result)
            return None
            
        except Exception as e:
            self.logger.error(f"获取邮箱失败: {e}")
            return None

    def search_emails(self, 
                     keyword: str = "",
                     domain: str = "",
                     status: Optional[EmailStatus] = None,
                     tags: Optional[List[str]] = None,
                     limit: int = 100) -> List[EmailModel]:
        """
        搜索邮箱
        
        Args:
            keyword: 关键词
            domain: 域名
            status: 状态
            tags: 标签列表
            limit: 限制数量
            
        Returns:
            邮箱模型列表
        """
        try:
            # 构建安全的查询条件
            base_query = "SELECT * FROM emails WHERE is_active = 1"
            where_conditions = []
            params = []

            if keyword:
                where_conditions.append("(email_address LIKE ? OR notes LIKE ?)")
                params.extend([f"%{keyword}%", f"%{keyword}%"])

            if domain:
                where_conditions.append("domain = ?")
                params.append(domain)

            if status:
                where_conditions.append("status = ?")
                params.append(status.value)

            # 标签搜索需要JOIN操作
            if tags:
                for tag in tags:
                    where_conditions.append("EXISTS (SELECT 1 FROM email_tags et JOIN tags t ON et.tag_id = t.id WHERE et.email_id = emails.id AND t.name = ?)")
                    params.append(tag)

            # 安全地构建完整查询
            if where_conditions:
                query = f"{base_query} AND {' AND '.join(where_conditions)} ORDER BY created_at DESC LIMIT ?"
            else:
                query = f"{base_query} ORDER BY created_at DESC LIMIT ?"

            params.append(limit)
            
            results = self.db_service.execute_query(query, tuple(params))
            return [self._row_to_email_model(row) for row in results or []]
            
        except Exception as e:
            self.logger.error(f"搜索邮箱失败: {e}")
            return []

    def update_email(self, email_model: EmailModel) -> bool:
        """
        更新邮箱信息
        
        Args:
            email_model: 邮箱模型
            
        Returns:
            是否更新成功
        """
        try:
            email_model.updated_at = datetime.now()
            return self._update_email_in_db(email_model)
            
        except Exception as e:
            self.logger.error(f"更新邮箱失败: {e}")
            return False

    def delete_email(self, email_id: int) -> bool:
        """
        删除邮箱（软删除）
        
        Args:
            email_id: 邮箱ID
            
        Returns:
            是否删除成功
        """
        try:
            query = "UPDATE emails SET is_active = 0, updated_at = ? WHERE id = ?"
            affected_rows = self.db_service.execute_update(
                query, 
                (datetime.now().isoformat(), email_id)
            )
            
            success = affected_rows > 0
            if success:
                self.logger.info(f"成功删除邮箱: {email_id}")
            
            return success
            
        except Exception as e:
            self.logger.error(f"删除邮箱失败: {e}")
            return False

    def add_email_tag(self, email_id: int, tag_name: str) -> bool:
        """
        为邮箱添加标签

        Args:
            email_id: 邮箱ID
            tag_name: 标签名称

        Returns:
            是否添加成功
        """
        try:
            with self.db_service.get_cursor() as cursor:
                self._save_email_tags(cursor, email_id, [tag_name])
            return True

        except Exception as e:
            self.logger.error(f"添加邮箱标签失败: {e}")
            return False

    def remove_email_tag(self, email_id: int, tag_name: str) -> bool:
        """
        移除邮箱标签

        Args:
            email_id: 邮箱ID
            tag_name: 标签名称

        Returns:
            是否移除成功
        """
        try:
            query = """
                DELETE FROM email_tags
                WHERE email_id = ? AND tag_id = (
                    SELECT id FROM tags WHERE name = ?
                )
            """
            affected_rows = self.db_service.execute_update(query, (email_id, tag_name))
            return affected_rows > 0

        except Exception as e:
            self.logger.error(f"移除邮箱标签失败: {e}")
            return False

    def get_emails_by_domain(self, domain: str, limit: int = 100) -> List[EmailModel]:
        """
        根据域名获取邮箱列表

        Args:
            domain: 域名
            limit: 限制数量

        Returns:
            邮箱模型列表
        """
        try:
            query = """
                SELECT * FROM emails
                WHERE domain = ? AND is_active = 1
                ORDER BY created_at DESC
                LIMIT ?
            """
            results = self.db_service.execute_query(query, (domain, limit))

            return [self._row_to_email_model(row) for row in results or []]

        except Exception as e:
            self.logger.error(f"获取域名邮箱列表失败: {e}")
            return []

    def get_emails_by_status(self, status: EmailStatus, limit: int = 100) -> List[EmailModel]:
        """
        根据状态获取邮箱列表

        Args:
            status: 邮箱状态
            limit: 限制数量

        Returns:
            邮箱模型列表
        """
        try:
            query = """
                SELECT * FROM emails
                WHERE status = ? AND is_active = 1
                ORDER BY created_at DESC
                LIMIT ?
            """
            results = self.db_service.execute_query(query, (status.value, limit))

            return [self._row_to_email_model(row) for row in results or []]

        except Exception as e:
            self.logger.error(f"获取状态邮箱列表失败: {e}")
            return []

    def batch_create_emails(self,
                           count: int,
                           prefix_type: str = "random_name",
                           base_prefix: Optional[str] = None,
                           tags: Optional[List[str]] = None,
                           notes: str = "") -> List[EmailModel]:
        """
        批量创建邮箱

        Args:
            count: 创建数量
            prefix_type: 前缀类型
            base_prefix: 基础前缀（用于生成序列）
            tags: 标签列表
            notes: 备注

        Returns:
            创建的邮箱模型列表
        """
        if count <= 0:
            return []

        if count > 100:
            self.logger.warning(f"批量创建数量过大: {count}，限制为100")
            count = 100

        created_emails = []

        try:
            for i in range(count):
                try:
                    # 生成前缀
                    if prefix_type == "sequence" and base_prefix:
                        custom_prefix = f"{base_prefix}_{i+1:03d}"
                        email = self.create_email(
                            prefix_type="custom",
                            custom_prefix=custom_prefix,
                            tags=tags,
                            notes=f"{notes} (批量创建 {i+1}/{count})"
                        )
                    else:
                        email = self.create_email(
                            prefix_type=prefix_type,
                            tags=tags,
                            notes=f"{notes} (批量创建 {i+1}/{count})"
                        )

                    created_emails.append(email)

                    # 添加小延迟确保时间戳唯一性
                    if i < count - 1:
                        import time
                        time.sleep(0.01)

                except Exception as e:
                    self.logger.error(f"批量创建第 {i+1} 个邮箱失败: {e}")
                    continue

            self.logger.info(f"批量创建完成，成功创建 {len(created_emails)} 个邮箱")
            return created_emails

        except Exception as e:
            self.logger.error(f"批量创建邮箱失败: {e}")
            return created_emails

    def batch_delete_emails(self, email_ids: List[int]) -> Dict[str, Any]:
        """
        批量删除邮箱

        Args:
            email_ids: 邮箱ID列表

        Returns:
            删除结果统计
        """
        if not email_ids:
            return {"success": 0, "failed": 0, "total": 0}

        success_count = 0
        failed_count = 0

        try:
            for email_id in email_ids:
                try:
                    if self.delete_email(email_id):
                        success_count += 1
                    else:
                        failed_count += 1
                except Exception as e:
                    self.logger.error(f"删除邮箱 {email_id} 失败: {e}")
                    failed_count += 1

            result = {
                "success": success_count,
                "failed": failed_count,
                "total": len(email_ids)
            }

            self.logger.info(f"批量删除完成: {result}")
            return result

        except Exception as e:
            self.logger.error(f"批量删除邮箱失败: {e}")
            return {"success": success_count, "failed": failed_count, "total": len(email_ids)}

    def get_statistics(self) -> Dict[str, Any]:
        """
        获取邮箱统计信息
        
        Returns:
            统计信息字典
        """
        try:
            stats = {}
            
            # 总邮箱数
            total_query = "SELECT COUNT(*) as count FROM emails WHERE is_active = 1"
            total_result = self.db_service.execute_query(total_query, fetch_one=True)
            stats["total_emails"] = total_result["count"] if total_result else 0
            
            # 按状态统计
            status_query = """
                SELECT status, COUNT(*) as count 
                FROM emails 
                WHERE is_active = 1 
                GROUP BY status
            """
            status_results = self.db_service.execute_query(status_query)
            stats["by_status"] = {row["status"]: row["count"] for row in status_results or []}
            
            # 按域名统计
            domain_query = """
                SELECT domain, COUNT(*) as count 
                FROM emails 
                WHERE is_active = 1 
                GROUP BY domain 
                ORDER BY count DESC 
                LIMIT 10
            """
            domain_results = self.db_service.execute_query(domain_query)
            stats["by_domain"] = {row["domain"]: row["count"] for row in domain_results or []}
            
            # 今日创建数量
            today_query = """
                SELECT COUNT(*) as count 
                FROM emails 
                WHERE is_active = 1 AND DATE(created_at) = DATE('now')
            """
            today_result = self.db_service.execute_query(today_query, fetch_one=True)
            stats["today_created"] = today_result["count"] if today_result else 0
            
            return stats
            
        except Exception as e:
            self.logger.error(f"获取统计信息失败: {e}")
            return {}

    def export_emails(self, format_type: str = "json", filters: Optional[Dict] = None) -> str:
        """
        导出邮箱数据
        
        Args:
            format_type: 导出格式 ("json", "csv")
            filters: 过滤条件
            
        Returns:
            导出的数据字符串
        """
        try:
            # 获取邮箱列表
            emails = self.search_emails(**(filters or {}))
            
            if format_type.lower() == "csv":
                return self._export_to_csv(emails)
            else:
                return self._export_to_json(emails)
                
        except Exception as e:
            self.logger.error(f"导出邮箱数据失败: {e}")
            raise

    def _save_email_to_db(self, email_model: EmailModel) -> int:
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
            raise

    def _update_email_in_db(self, email_model: EmailModel) -> bool:
        """更新数据库中的邮箱信息"""
        try:
            query = """
                UPDATE emails SET
                    last_used = ?,
                    updated_at = ?,
                    status = ?,
                    notes = ?,
                    metadata = ?
                WHERE id = ?
            """

            params = (
                email_model.last_used.isoformat() if email_model.last_used else None,
                email_model.updated_at.isoformat() if email_model.updated_at else None,
                email_model.status.value,
                email_model.notes,
                json.dumps(email_model.metadata) if email_model.metadata else None,
                email_model.id
            )

            affected_rows = self.db_service.execute_update(query, params)
            return affected_rows > 0

        except Exception as e:
            self.logger.error(f"更新邮箱信息失败: {e}")
            return False

    def _save_email_tags(self, cursor, email_id: int, tags: List[str]):
        """保存邮箱标签关联"""
        for tag_name in tags:
            # 确保标签存在
            cursor.execute("SELECT id FROM tags WHERE name = ?", (tag_name,))
            tag_result = cursor.fetchone()

            if tag_result:
                tag_id = tag_result["id"]
            else:
                # 创建新标签
                cursor.execute(
                    "INSERT INTO tags (name, description) VALUES (?, ?)",
                    (tag_name, f"自动创建的标签: {tag_name}")
                )
                tag_id = cursor.lastrowid

            # 创建关联
            cursor.execute(
                "INSERT OR IGNORE INTO email_tags (email_id, tag_id) VALUES (?, ?)",
                (email_id, tag_id)
            )

    def _row_to_email_model(self, row) -> EmailModel:
        """将数据库行转换为邮箱模型"""
        try:
            # 解析时间字段
            def parse_datetime(dt_str):
                if dt_str:
                    try:
                        return datetime.fromisoformat(dt_str)
                    except (ValueError, TypeError):
                        pass
                return None

            # 解析状态
            status = EmailStatus.ACTIVE
            if row["status"]:
                try:
                    status = EmailStatus(row["status"])
                except ValueError:
                    pass

            # 解析元数据
            metadata = {}
            if row["metadata"]:
                try:
                    metadata = json.loads(row["metadata"])
                except (json.JSONDecodeError, TypeError):
                    pass

            # 获取标签
            tags = self._get_email_tags(row["id"])

            return EmailModel(
                id=row["id"],
                email_address=row["email_address"],
                domain=row["domain"],
                prefix=row["prefix"],
                timestamp_suffix=row["timestamp_suffix"] or "",
                created_at=parse_datetime(row["created_at"]),
                last_used=parse_datetime(row["last_used"]),
                updated_at=parse_datetime(row["updated_at"]),
                status=status,
                tags=tags,
                notes=row["notes"] or "",
                metadata=metadata,
                is_active=bool(row["is_active"]),
                created_by=row["created_by"] or "system"
            )

        except Exception as e:
            self.logger.error(f"转换数据库行失败: {e}")
            raise

    def _get_email_tags(self, email_id: int) -> List[str]:
        """获取邮箱的标签列表"""
        try:
            query = """
                SELECT t.name
                FROM tags t
                JOIN email_tags et ON t.id = et.tag_id
                WHERE et.email_id = ?
            """
            results = self.db_service.execute_query(query, (email_id,))
            return [row["name"] for row in results or []]

        except Exception as e:
            self.logger.error(f"获取邮箱标签失败: {e}")
            return []

    def _export_to_json(self, emails: List[EmailModel]) -> str:
        """导出为JSON格式"""
        data = [email.to_dict() for email in emails]
        return json.dumps(data, ensure_ascii=False, indent=2)

    def _export_to_csv(self, emails: List[EmailModel]) -> str:
        """导出为CSV格式"""
        import csv
        import io

        output = io.StringIO()
        writer = csv.writer(output)

        # 写入标题行
        headers = [
            "ID", "邮箱地址", "域名", "前缀", "创建时间", "状态",
            "标签", "备注"
        ]
        writer.writerow(headers)

        # 写入数据行
        for email in emails:
            row = [
                email.id,
                email.email_address,
                email.domain,
                email.prefix,
                email.created_at.isoformat() if email.created_at else "",
                email.status_display,
                ",".join(email.tags),
                email.notes
            ]
            writer.writerow(row)

        return output.getvalue()
