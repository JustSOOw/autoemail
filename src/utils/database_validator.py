# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 数据库验证工具
验证数据库结构是否满足应用需求
"""

from pathlib import Path
from typing import Dict, List, Any

from services.database_service import DatabaseService
from models.email_model import EmailModel
from models.config_model import ConfigModel
from utils.logger import get_logger


class DatabaseValidator:
    """
    数据库验证器
    
    验证数据库结构的完整性和正确性
    """

    def __init__(self, db_service: DatabaseService):
        """
        初始化数据库验证器
        
        Args:
            db_service: 数据库服务实例
        """
        self.db_service = db_service
        self.logger = get_logger(__name__)

    def validate_database(self) -> Dict[str, Any]:
        """
        验证整个数据库结构
        
        Returns:
            验证结果字典
        """
        results = {
            "overall_status": "success",
            "tables": {},
            "indexes": {},
            "data_integrity": {},
            "recommendations": [],
            "errors": []
        }
        
        try:
            # 验证表结构
            table_results = self._validate_tables()
            results["tables"] = table_results
            
            # 验证索引
            index_results = self._validate_indexes()
            results["indexes"] = index_results
            
            # 验证数据完整性
            integrity_results = self._validate_data_integrity()
            results["data_integrity"] = integrity_results
            
            # 生成建议
            recommendations = self._generate_recommendations(results)
            results["recommendations"] = recommendations
            
            # 检查是否有错误
            has_errors = any(
                table.get("status") == "error" for table in table_results.values()
            )
            
            if has_errors:
                results["overall_status"] = "error"
            elif recommendations:
                results["overall_status"] = "warning"
            
            self.logger.info(f"数据库验证完成，状态: {results['overall_status']}")
            
        except Exception as e:
            self.logger.error(f"数据库验证失败: {e}")
            results["overall_status"] = "error"
            results["errors"].append(str(e))
        
        return results

    def _validate_tables(self) -> Dict[str, Any]:
        """验证表结构"""
        results = {}
        
        # 定义期望的表结构
        expected_tables = {
            "emails": {
                "required_columns": [
                    "id", "email_address", "domain", "prefix", "timestamp_suffix",
                    "created_at", "last_used", "verification_status", "verification_code",
                    "verification_method", "verification_attempts", "last_verification_at",
                    "notes", "is_active", "metadata", "created_by", "updated_at"
                ],
                "unique_columns": ["email_address"],
                "indexed_columns": ["domain", "created_at", "verification_status", "is_active"]
            },
            "tags": {
                "required_columns": [
                    "id", "name", "color", "icon", "description", "created_at",
                    "updated_at", "is_system", "sort_order"
                ],
                "unique_columns": ["name"],
                "indexed_columns": ["name", "sort_order"]
            },
            "email_tags": {
                "required_columns": [
                    "id", "email_id", "tag_id", "created_at", "created_by"
                ],
                "unique_columns": [],
                "indexed_columns": ["email_id", "tag_id"]
            },
            "configurations": {
                "required_columns": [
                    "id", "config_key", "config_value", "config_type", "is_encrypted",
                    "is_active", "version", "created_at", "updated_at", "description"
                ],
                "unique_columns": [],
                "indexed_columns": ["config_key", "config_type", "is_active"]
            },
            "operation_logs": {
                "required_columns": [
                    "id", "operation_type", "target_type", "target_id", "operation_details",
                    "result", "error_message", "user_agent", "ip_address", "created_at",
                    "execution_time"
                ],
                "unique_columns": [],
                "indexed_columns": ["operation_type", "target_type", "created_at", "result"]
            }
        }
        
        for table_name, expected in expected_tables.items():
            results[table_name] = self._validate_single_table(table_name, expected)
        
        return results

    def _validate_single_table(self, table_name: str, expected: Dict) -> Dict[str, Any]:
        """验证单个表结构"""
        result = {
            "status": "success",
            "exists": False,
            "missing_columns": [],
            "extra_columns": [],
            "column_details": {},
            "issues": []
        }
        
        try:
            # 检查表是否存在
            table_info = self.db_service.get_table_info(table_name)
            
            if not table_info:
                result["status"] = "error"
                result["issues"].append(f"表 {table_name} 不存在")
                return result
            
            result["exists"] = True
            
            # 获取实际列名
            actual_columns = {col["name"] for col in table_info}
            expected_columns = set(expected["required_columns"])
            
            # 检查缺失的列
            missing = expected_columns - actual_columns
            if missing:
                result["missing_columns"] = list(missing)
                result["status"] = "error"
                result["issues"].append(f"缺失列: {', '.join(missing)}")
            
            # 检查额外的列
            extra = actual_columns - expected_columns
            if extra:
                result["extra_columns"] = list(extra)
                result["issues"].append(f"额外列: {', '.join(extra)}")
            
            # 记录列详情
            for col in table_info:
                result["column_details"][col["name"]] = {
                    "type": col["type"],
                    "nullable": not col["notnull"],
                    "default": col["default_value"],
                    "primary_key": col["primary_key"]
                }
            
        except Exception as e:
            result["status"] = "error"
            result["issues"].append(f"验证表 {table_name} 时出错: {e}")
        
        return result

    def _validate_indexes(self) -> Dict[str, Any]:
        """验证索引"""
        results = {
            "status": "success",
            "missing_indexes": [],
            "existing_indexes": [],
            "issues": []
        }
        
        try:
            # 这里可以添加索引验证逻辑
            # SQLite的索引查询比较复杂，暂时跳过详细验证
            results["issues"].append("索引验证功能待实现")
            
        except Exception as e:
            results["status"] = "error"
            results["issues"].append(f"验证索引时出错: {e}")
        
        return results

    def _validate_data_integrity(self) -> Dict[str, Any]:
        """验证数据完整性"""
        results = {
            "status": "success",
            "orphaned_records": {},
            "invalid_data": {},
            "statistics": {},
            "issues": []
        }
        
        try:
            # 检查孤立记录
            orphaned = self._check_orphaned_records()
            if orphaned:
                results["orphaned_records"] = orphaned
                results["issues"].extend([f"发现孤立记录: {k}" for k in orphaned.keys()])
            
            # 检查无效数据
            invalid = self._check_invalid_data()
            if invalid:
                results["invalid_data"] = invalid
                results["issues"].extend([f"发现无效数据: {k}" for k in invalid.keys()])
            
            # 获取统计信息
            stats = self.db_service.get_database_stats()
            results["statistics"] = stats
            
            if results["issues"]:
                results["status"] = "warning"
            
        except Exception as e:
            results["status"] = "error"
            results["issues"].append(f"验证数据完整性时出错: {e}")
        
        return results

    def _check_orphaned_records(self) -> Dict[str, int]:
        """检查孤立记录"""
        orphaned = {}
        
        try:
            # 检查email_tags表中的孤立记录
            query = """
                SELECT COUNT(*) as count FROM email_tags et 
                WHERE NOT EXISTS (SELECT 1 FROM emails e WHERE e.id = et.email_id)
                   OR NOT EXISTS (SELECT 1 FROM tags t WHERE t.id = et.tag_id)
            """
            result = self.db_service.execute_query(query, fetch_one=True)
            if result and result["count"] > 0:
                orphaned["email_tags"] = result["count"]
            
        except Exception as e:
            self.logger.error(f"检查孤立记录失败: {e}")
        
        return orphaned

    def _check_invalid_data(self) -> Dict[str, int]:
        """检查无效数据"""
        invalid = {}
        
        try:
            # 检查无效的邮箱地址
            query = """
                SELECT COUNT(*) as count FROM emails 
                WHERE email_address NOT LIKE '%@%' OR email_address = ''
            """
            result = self.db_service.execute_query(query, fetch_one=True)
            if result and result["count"] > 0:
                invalid["invalid_emails"] = result["count"]
            
            # 检查无效的验证状态
            valid_statuses = ["pending", "verified", "failed", "expired"]
            query = f"""
                SELECT COUNT(*) as count FROM emails 
                WHERE verification_status NOT IN ({','.join(['?' for _ in valid_statuses])})
            """
            result = self.db_service.execute_query(query, tuple(valid_statuses), fetch_one=True)
            if result and result["count"] > 0:
                invalid["invalid_verification_status"] = result["count"]
            
        except Exception as e:
            self.logger.error(f"检查无效数据失败: {e}")
        
        return invalid

    def _generate_recommendations(self, validation_results: Dict[str, Any]) -> List[str]:
        """生成优化建议"""
        recommendations = []
        
        # 基于验证结果生成建议
        tables = validation_results.get("tables", {})
        
        for table_name, table_result in tables.items():
            if table_result.get("missing_columns"):
                recommendations.append(f"需要为表 {table_name} 添加缺失的列")
            
            if table_result.get("extra_columns"):
                recommendations.append(f"考虑清理表 {table_name} 中的额外列")
        
        # 数据完整性建议
        integrity = validation_results.get("data_integrity", {})
        if integrity.get("orphaned_records"):
            recommendations.append("建议清理孤立记录")
        
        if integrity.get("invalid_data"):
            recommendations.append("建议修复无效数据")
        
        # 性能建议
        stats = integrity.get("statistics", {})
        if stats.get("emails_count", 0) > 10000:
            recommendations.append("考虑添加更多索引以提高查询性能")
        
        return recommendations

    def fix_database_issues(self, validation_results: Dict[str, Any]) -> bool:
        """
        修复数据库问题
        
        Args:
            validation_results: 验证结果
            
        Returns:
            是否修复成功
        """
        try:
            fixed_issues = []
            
            # 修复缺失的列
            tables = validation_results.get("tables", {})
            for table_name, table_result in tables.items():
                if table_result.get("missing_columns"):
                    if self._add_missing_columns(table_name, table_result["missing_columns"]):
                        fixed_issues.append(f"为表 {table_name} 添加了缺失的列")
            
            # 清理孤立记录
            integrity = validation_results.get("data_integrity", {})
            if integrity.get("orphaned_records"):
                if self._clean_orphaned_records():
                    fixed_issues.append("清理了孤立记录")
            
            if fixed_issues:
                self.logger.info(f"修复了以下问题: {'; '.join(fixed_issues)}")
                return True
            else:
                self.logger.info("没有需要修复的问题")
                return True
                
        except Exception as e:
            self.logger.error(f"修复数据库问题失败: {e}")
            return False

    def _add_missing_columns(self, table_name: str, missing_columns: List[str]) -> bool:
        """添加缺失的列"""
        try:
            # 这里可以添加具体的列添加逻辑
            # 由于SQLite的ALTER TABLE限制，这个功能比较复杂
            self.logger.warning(f"添加缺失列功能待实现: {table_name} - {missing_columns}")
            return False
            
        except Exception as e:
            self.logger.error(f"添加缺失列失败: {e}")
            return False

    def _clean_orphaned_records(self) -> bool:
        """清理孤立记录"""
        try:
            # 清理email_tags表中的孤立记录
            query = """
                DELETE FROM email_tags 
                WHERE NOT EXISTS (SELECT 1 FROM emails WHERE emails.id = email_tags.email_id)
                   OR NOT EXISTS (SELECT 1 FROM tags WHERE tags.id = email_tags.tag_id)
            """
            affected_rows = self.db_service.execute_update(query)
            
            if affected_rows > 0:
                self.logger.info(f"清理了 {affected_rows} 条孤立记录")
            
            return True
            
        except Exception as e:
            self.logger.error(f"清理孤立记录失败: {e}")
            return False
