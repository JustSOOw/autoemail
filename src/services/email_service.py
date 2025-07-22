# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 邮箱服务
整合邮箱生成、验证和数据库操作的核心服务
"""

import json
from datetime import datetime
from typing import List, Optional, Dict, Any

from models.email_model import EmailModel, VerificationStatus, VerificationMethod, create_email_model
from models.config_model import ConfigModel
from services.database_service import DatabaseService
from services.email_generator import EmailGenerator
from services.email_verification_handler import EmailVerificationHandler
from utils.logger import get_logger


class EmailService:
    """
    邮箱服务类
    
    提供邮箱生成、验证、管理的完整功能
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
        
        # 初始化子服务
        self.email_generator = EmailGenerator(config)
        
        self.logger.info("邮箱服务初始化完成")

    def create_email(self, 
                    prefix_type: str = "random_name",
                    custom_prefix: Optional[str] = None,
                    tags: Optional[List[str]] = None,
                    notes: str = "",
                    auto_verify: bool = False) -> EmailModel:
        """
        创建新邮箱
        
        Args:
            prefix_type: 前缀类型
            custom_prefix: 自定义前缀
            tags: 标签列表
            notes: 备注
            auto_verify: 是否自动验证
            
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
            
            # 自动验证
            if auto_verify:
                try:
                    verification_result = self.verify_email(email_model.id)
                    if verification_result["success"]:
                        email_model.update_verification_status(
                            VerificationStatus.VERIFIED,
                            verification_result.get("code"),
                            VerificationMethod(verification_result.get("method", "auto"))
                        )
                        self._update_email_in_db(email_model)
                except Exception as e:
                    self.logger.warning(f"自动验证失败: {e}")
            
            return email_model
            
        except Exception as e:
            self.logger.error(f"创建邮箱失败: {e}")
            raise

    def verify_email(self, email_id: int, max_retries: int = 5) -> Dict[str, Any]:
        """
        验证邮箱
        
        Args:
            email_id: 邮箱ID
            max_retries: 最大重试次数
            
        Returns:
            验证结果字典
        """
        try:
            # 从数据库获取邮箱信息
            email_model = self.get_email_by_id(email_id)
            if not email_model:
                return {"success": False, "message": "邮箱不存在"}
            
            # 创建验证处理器
            verification_handler = EmailVerificationHandler(
                self.config, 
                email_model.email_address
            )
            
            # 更新验证状态为进行中
            email_model.verification_status = VerificationStatus.PENDING
            email_model.verification_attempts += 1
            self._update_email_in_db(email_model)
            
            # 执行验证
            verification_code = verification_handler.get_verification_code(
                max_retries=max_retries
            )
            
            if verification_code:
                # 验证成功
                email_model.update_verification_status(
                    VerificationStatus.VERIFIED,
                    verification_code,
                    VerificationMethod(self.config.get_verification_method())
                )
                self._update_email_in_db(email_model)
                
                result = {
                    "success": True,
                    "message": "验证成功",
                    "code": verification_code,
                    "method": self.config.get_verification_method(),
                    "email": email_model.email_address
                }
                
                self.logger.info(f"邮箱验证成功: {email_model.email_address}")
                return result
            else:
                # 验证失败
                email_model.update_verification_status(VerificationStatus.FAILED)
                self._update_email_in_db(email_model)
                
                return {
                    "success": False,
                    "message": "未获取到验证码",
                    "email": email_model.email_address
                }
                
        except Exception as e:
            self.logger.error(f"验证邮箱失败: {e}")
            
            # 更新失败状态
            try:
                if 'email_model' in locals():
                    email_model.update_verification_status(VerificationStatus.FAILED)
                    self._update_email_in_db(email_model)
            except:
                pass
            
            return {
                "success": False,
                "message": f"验证过程出错: {e}",
                "email": email_model.email_address if 'email_model' in locals() else "unknown"
            }

    def get_email_by_id(self, email_id: int) -> Optional[EmailModel]:
        """
        根据ID获取邮箱
        
        Args:
            email_id: 邮箱ID
            
        Returns:
            邮箱模型或None
        """
        try:
            query = "SELECT * FROM emails WHERE id = ?"
            result = self.db_service.execute_query(query, (email_id,), fetch_one=True)
            
            if result:
                return self._row_to_email_model(result)
            return None
            
        except Exception as e:
            self.logger.error(f"获取邮箱失败: {e}")
            return None

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

    def search_emails(self, 
                     keyword: str = "",
                     domain: str = "",
                     status: Optional[VerificationStatus] = None,
                     tags: Optional[List[str]] = None,
                     limit: int = 100) -> List[EmailModel]:
        """
        搜索邮箱
        
        Args:
            keyword: 关键词
            domain: 域名
            status: 验证状态
            tags: 标签列表
            limit: 限制数量
            
        Returns:
            邮箱模型列表
        """
        try:
            conditions = ["is_active = 1"]
            params = []
            
            if keyword:
                conditions.append("(email_address LIKE ? OR notes LIKE ?)")
                params.extend([f"%{keyword}%", f"%{keyword}%"])
            
            if domain:
                conditions.append("domain = ?")
                params.append(domain)
            
            if status:
                conditions.append("verification_status = ?")
                params.append(status.value)
            
            # 标签搜索需要JOIN操作
            if tags:
                tag_conditions = []
                for tag in tags:
                    tag_conditions.append("EXISTS (SELECT 1 FROM email_tags et JOIN tags t ON et.tag_id = t.id WHERE et.email_id = emails.id AND t.name = ?)")
                    params.append(tag)
                conditions.extend(tag_conditions)
            
            query = f"""
                SELECT * FROM emails 
                WHERE {' AND '.join(conditions)}
                ORDER BY created_at DESC 
                LIMIT ?
            """
            params.append(limit)
            
            results = self.db_service.execute_query(query, tuple(params))
            return [self._row_to_email_model(row) for row in results or []]
            
        except Exception as e:
            self.logger.error(f"搜索邮箱失败: {e}")
            return []

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
                SELECT verification_status, COUNT(*) as count 
                FROM emails 
                WHERE is_active = 1 
                GROUP BY verification_status
            """
            status_results = self.db_service.execute_query(status_query)
            stats["by_status"] = {row["verification_status"]: row["count"] for row in status_results or []}
            
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

    def test_verification_connection(self) -> Dict[str, Any]:
        """
        测试验证连接
        
        Returns:
            测试结果
        """
        try:
            # 使用临时邮箱地址进行测试
            test_email = "test@example.com"
            verification_handler = EmailVerificationHandler(self.config, test_email)
            return verification_handler.test_connection()
            
        except Exception as e:
            self.logger.error(f"测试验证连接失败: {e}")
            return {
                "success": False,
                "message": f"测试失败: {e}",
                "method": self.config.get_verification_method()
            }

    def _save_email_to_db(self, email_model: EmailModel) -> int:
        """
        保存邮箱到数据库

        Args:
            email_model: 邮箱模型

        Returns:
            邮箱ID
        """
        try:
            query = """
                INSERT INTO emails (
                    email_address, domain, prefix, timestamp_suffix,
                    created_at, verification_status, verification_method,
                    verification_attempts, notes, metadata, created_by
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """

            params = (
                email_model.email_address,
                email_model.domain,
                email_model.prefix,
                email_model.timestamp_suffix,
                email_model.created_at.isoformat() if email_model.created_at else None,
                email_model.verification_status.value,
                email_model.verification_method.value if email_model.verification_method else None,
                email_model.verification_attempts,
                email_model.notes,
                json.dumps(email_model.metadata) if email_model.metadata else None,
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
        """
        更新数据库中的邮箱信息

        Args:
            email_model: 邮箱模型

        Returns:
            是否更新成功
        """
        try:
            query = """
                UPDATE emails SET
                    verification_status = ?,
                    verification_code = ?,
                    verification_method = ?,
                    verification_attempts = ?,
                    last_verification_at = ?,
                    last_used = ?,
                    notes = ?,
                    metadata = ?,
                    updated_at = ?
                WHERE id = ?
            """

            params = (
                email_model.verification_status.value,
                email_model.verification_code,
                email_model.verification_method.value if email_model.verification_method else None,
                email_model.verification_attempts,
                email_model.last_verification_at.isoformat() if email_model.last_verification_at else None,
                email_model.last_used.isoformat() if email_model.last_used else None,
                email_model.notes,
                json.dumps(email_model.metadata) if email_model.metadata else None,
                datetime.now().isoformat(),
                email_model.id
            )

            affected_rows = self.db_service.execute_update(query, params)
            return affected_rows > 0

        except Exception as e:
            self.logger.error(f"更新邮箱信息失败: {e}")
            return False

    def _save_email_tags(self, cursor, email_id: int, tags: List[str]):
        """
        保存邮箱标签关联

        Args:
            cursor: 数据库游标
            email_id: 邮箱ID
            tags: 标签列表
        """
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
        """
        将数据库行转换为邮箱模型

        Args:
            row: 数据库行

        Returns:
            邮箱模型
        """
        try:
            # 解析时间字段
            def parse_datetime(dt_str):
                if dt_str:
                    try:
                        return datetime.fromisoformat(dt_str)
                    except (ValueError, TypeError):
                        pass
                return None

            # 解析枚举字段
            verification_status = VerificationStatus.PENDING
            if row["verification_status"]:
                try:
                    verification_status = VerificationStatus(row["verification_status"])
                except ValueError:
                    pass

            verification_method = None
            if row["verification_method"]:
                try:
                    verification_method = VerificationMethod(row["verification_method"])
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
                timestamp_suffix=row["timestamp_suffix"],
                created_at=parse_datetime(row["created_at"]),
                last_used=parse_datetime(row["last_used"]),
                verification_status=verification_status,
                verification_code=row["verification_code"],
                verification_method=verification_method,
                verification_attempts=row["verification_attempts"] or 0,
                last_verification_at=parse_datetime(row["last_verification_at"]),
                tags=tags,
                notes=row["notes"] or "",
                metadata=metadata,
                is_active=bool(row["is_active"]),
                created_by=row["created_by"] or "system",
                updated_at=parse_datetime(row["updated_at"])
            )

        except Exception as e:
            self.logger.error(f"转换数据库行失败: {e}")
            raise

    def _get_email_tags(self, email_id: int) -> List[str]:
        """
        获取邮箱的标签列表

        Args:
            email_id: 邮箱ID

        Returns:
            标签名称列表
        """
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
            "ID", "邮箱地址", "域名", "前缀", "创建时间", "验证状态",
            "验证码", "验证方式", "标签", "备注"
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
                email.verification_status_display,
                email.verification_code or "",
                email.verification_method.value if email.verification_method else "",
                ",".join(email.tags),
                email.notes
            ]
            writer.writerow(row)

        return output.getvalue()
