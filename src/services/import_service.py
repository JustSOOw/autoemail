"""
邮箱数据导入服务
处理文件解析、数据验证、批量导入等核心逻辑
"""

import json
import csv
import os
import re
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
import logging

try:
    import pandas as pd
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False

from models.email_model import EmailModel, EmailStatus, create_email_model
from services.database_service import DatabaseService
from services.batch_service import BatchService
from utils.logger import get_logger


class ImportService:
    """邮箱数据导入服务"""
    
    def __init__(self, db_service: DatabaseService, batch_service: Optional[BatchService] = None):
        """
        初始化导入服务

        Args:
            db_service: 数据库服务实例
            batch_service: 批量操作服务实例
        """
        self.db_service = db_service
        self.batch_service = batch_service  # 不再自动创建，必须由外部传入
        self.logger = get_logger(__name__)
        
        # 支持的文件格式
        self.supported_formats = ["json", "csv", "xlsx"]
        
        # 邮箱格式验证正则表达式
        self.email_pattern = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    
    def import_from_file(self, 
                        file_path: str,
                        format_type: str = "auto",
                        options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        从文件导入邮箱数据
        
        Args:
            file_path: 文件路径
            format_type: 文件格式 ("json", "csv", "xlsx", "auto")
            options: 导入选项
            
        Returns:
            导入结果字典
        """
        try:
            # 验证文件存在
            if not os.path.exists(file_path):
                raise FileNotFoundError(f"文件不存在: {file_path}")
            
            # 自动检测格式
            if format_type == "auto":
                format_type = self._detect_file_format(file_path)
            
            # 验证格式支持
            if format_type not in self.supported_formats:
                raise ValueError(f"不支持的文件格式: {format_type}")
            
            # 设置默认选项
            options = options or {}
            conflict_strategy = options.get("conflictStrategy", "skip")
            validate_emails = options.get("validateEmails", True)
            import_tags = options.get("importTags", True)
            import_metadata = options.get("importMetadata", False)
            
            self.logger.info(f"开始导入文件: {file_path}, 格式: {format_type}")
            
            # 解析文件数据
            raw_data = self._parse_file(file_path, format_type)
            
            # 验证和转换数据
            validated_data = self._validate_and_convert_data(
                raw_data, 
                validate_emails, 
                import_tags, 
                import_metadata
            )
            
            # 批量导入数据
            if not self.batch_service:
                raise ValueError("批量服务未初始化")

            import_result = self.batch_service.batch_import_emails_from_data(
                validated_data,
                conflict_strategy
            )
            
            # 添加导入统计信息
            import_result.update({
                "file_path": file_path,
                "file_format": format_type,
                "import_time": datetime.now().isoformat(),
                "options": options
            })
            
            self.logger.info(f"导入完成: 成功 {import_result['success']}, 失败 {import_result['failed']}")
            return import_result
            
        except Exception as e:
            self.logger.error(f"导入文件失败: {e}")
            return {
                "total": 0,
                "success": 0,
                "failed": 1,
                "skipped": 0,
                "updated": 0,
                "emails": [],
                "errors": [str(e)],
                "file_path": file_path,
                "import_time": datetime.now().isoformat()
            }
    
    def preview_file(self, file_path: str, format_type: str = "auto", limit: int = 10) -> Dict[str, Any]:
        """
        预览文件内容
        
        Args:
            file_path: 文件路径
            format_type: 文件格式
            limit: 预览行数限制
            
        Returns:
            预览结果字典
        """
        try:
            if not os.path.exists(file_path):
                raise FileNotFoundError(f"文件不存在: {file_path}")
            
            if format_type == "auto":
                format_type = self._detect_file_format(file_path)
            
            # 解析文件数据（限制行数）
            raw_data = self._parse_file(file_path, format_type, limit)
            
            # 获取文件信息
            file_info = self._get_file_info(file_path)
            
            return {
                "success": True,
                "file_info": file_info,
                "format": format_type,
                "preview_data": raw_data[:limit],
                "total_rows": len(raw_data),
                "columns": list(raw_data[0].keys()) if raw_data else [],
                "message": f"成功预览 {len(raw_data)} 行数据"
            }
            
        except Exception as e:
            self.logger.error(f"预览文件失败: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": f"预览文件失败: {e}"
            }
    
    def validate_file_format(self, file_path: str) -> Dict[str, Any]:
        """
        验证文件格式和内容
        
        Args:
            file_path: 文件路径
            
        Returns:
            验证结果字典
        """
        try:
            if not os.path.exists(file_path):
                return {"valid": False, "error": "文件不存在"}
            
            format_type = self._detect_file_format(file_path)
            
            # 尝试解析少量数据来验证格式
            try:
                sample_data = self._parse_file(file_path, format_type, limit=5)
                
                # 检查必要字段
                required_fields = ["email_address"]
                if sample_data:
                    missing_fields = [field for field in required_fields 
                                    if field not in sample_data[0]]
                    if missing_fields:
                        return {
                            "valid": False,
                            "error": f"缺少必要字段: {missing_fields}",
                            "format": format_type
                        }
                
                return {
                    "valid": True,
                    "format": format_type,
                    "sample_count": len(sample_data),
                    "columns": list(sample_data[0].keys()) if sample_data else []
                }
                
            except Exception as parse_error:
                return {
                    "valid": False,
                    "error": f"文件格式错误: {parse_error}",
                    "format": format_type
                }
                
        except Exception as e:
            return {"valid": False, "error": str(e)}
    
    def _detect_file_format(self, file_path: str) -> str:
        """检测文件格式"""
        file_ext = Path(file_path).suffix.lower()
        
        format_map = {
            ".json": "json",
            ".csv": "csv",
            ".xlsx": "xlsx",
            ".xls": "xlsx"
        }
        
        return format_map.get(file_ext, "unknown")
    
    def _parse_file(self, file_path: str, format_type: str, limit: Optional[int] = None) -> List[Dict[str, Any]]:
        """解析文件数据"""
        if format_type == "json":
            return self._parse_json_file(file_path, limit)
        elif format_type == "csv":
            return self._parse_csv_file(file_path, limit)
        elif format_type == "xlsx":
            return self._parse_xlsx_file(file_path, limit)
        else:
            raise ValueError(f"不支持的文件格式: {format_type}")
    
    def _parse_json_file(self, file_path: str, limit: Optional[int] = None) -> List[Dict[str, Any]]:
        """解析JSON文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # 处理不同的JSON结构
            if isinstance(data, list):
                result = data
            elif isinstance(data, dict):
                # 如果是包含emails字段的对象
                if "emails" in data:
                    result = data["emails"]
                else:
                    result = [data]
            else:
                raise ValueError("JSON文件格式不正确")
            
            return result[:limit] if limit else result
            
        except json.JSONDecodeError as e:
            raise ValueError(f"JSON文件格式错误: {e}")
        except Exception as e:
            raise ValueError(f"读取JSON文件失败: {e}")
    
    def _parse_csv_file(self, file_path: str, limit: Optional[int] = None) -> List[Dict[str, Any]]:
        """解析CSV文件"""
        try:
            result = []
            with open(file_path, 'r', encoding='utf-8', newline='') as f:
                # 尝试检测分隔符
                sample = f.read(1024)
                f.seek(0)
                
                sniffer = csv.Sniffer()
                delimiter = sniffer.sniff(sample).delimiter
                
                reader = csv.DictReader(f, delimiter=delimiter)
                
                for i, row in enumerate(reader):
                    if limit and i >= limit:
                        break
                    result.append(dict(row))
            
            return result
            
        except Exception as e:
            raise ValueError(f"读取CSV文件失败: {e}")
    
    def _parse_xlsx_file(self, file_path: str, limit: Optional[int] = None) -> List[Dict[str, Any]]:
        """解析Excel文件"""
        if not PANDAS_AVAILABLE:
            raise ValueError("需要安装pandas库来支持Excel文件导入")
        
        try:
            # 读取Excel文件
            df = pd.read_excel(file_path, engine='openpyxl')
            
            # 限制行数
            if limit:
                df = df.head(limit)
            
            # 转换为字典列表
            result = df.to_dict('records')
            
            # 处理NaN值
            for row in result:
                for key, value in row.items():
                    if pd.isna(value):
                        row[key] = ""
            
            return result
            
        except Exception as e:
            raise ValueError(f"读取Excel文件失败: {e}")
    
    def _validate_and_convert_data(self, 
                                  raw_data: List[Dict[str, Any]], 
                                  validate_emails: bool = True,
                                  import_tags: bool = True,
                                  import_metadata: bool = False) -> List[Dict[str, Any]]:
        """验证和转换数据"""
        validated_data = []
        
        for i, row in enumerate(raw_data):
            try:
                # 获取邮箱地址
                email_address = row.get("email_address", "").strip()
                if not email_address:
                    self.logger.warning(f"第 {i+1} 行缺少邮箱地址，跳过")
                    continue
                
                # 验证邮箱格式
                if validate_emails and not self.email_pattern.match(email_address):
                    self.logger.warning(f"第 {i+1} 行邮箱格式无效: {email_address}")
                    continue
                
                # 构建验证后的数据
                validated_row = {
                    "email_address": email_address,
                    "notes": row.get("notes", ""),
                    "status": row.get("status", "active"),
                    "created_by": "import_system"
                }
                
                # 处理标签
                if import_tags:
                    tags = row.get("tags", [])
                    if isinstance(tags, str):
                        # 如果是字符串，尝试解析为列表
                        try:
                            tags = json.loads(tags)
                        except:
                            tags = [tag.strip() for tag in tags.split(",") if tag.strip()]
                    validated_row["tags"] = tags if isinstance(tags, list) else []
                
                # 处理元数据
                if import_metadata:
                    metadata = row.get("metadata", {})
                    if isinstance(metadata, str):
                        try:
                            metadata = json.loads(metadata)
                        except:
                            metadata = {}
                    validated_row["metadata"] = metadata if isinstance(metadata, dict) else {}
                
                # 处理时间字段
                for time_field in ["created_at", "last_used", "updated_at"]:
                    if time_field in row and row[time_field]:
                        validated_row[time_field] = row[time_field]
                
                validated_data.append(validated_row)
                
            except Exception as e:
                self.logger.error(f"验证第 {i+1} 行数据失败: {e}")
                continue
        
        self.logger.info(f"数据验证完成: 原始 {len(raw_data)} 行，有效 {len(validated_data)} 行")
        return validated_data
    
    def _get_file_info(self, file_path: str) -> Dict[str, Any]:
        """获取文件信息"""
        try:
            file_stat = os.stat(file_path)
            return {
                "name": os.path.basename(file_path),
                "size": file_stat.st_size,
                "size_formatted": self._format_file_size(file_stat.st_size),
                "modified_time": datetime.fromtimestamp(file_stat.st_mtime).isoformat(),
                "extension": Path(file_path).suffix.lower()
            }
        except Exception as e:
            self.logger.error(f"获取文件信息失败: {e}")
            return {"name": os.path.basename(file_path), "error": str(e)}
    
    def _format_file_size(self, size_bytes: int) -> str:
        """格式化文件大小"""
        if size_bytes < 1024:
            return f"{size_bytes} B"
        elif size_bytes < 1024 * 1024:
            return f"{size_bytes / 1024:.1f} KB"
        elif size_bytes < 1024 * 1024 * 1024:
            return f"{size_bytes / (1024 * 1024):.1f} MB"
        else:
            return f"{size_bytes / (1024 * 1024 * 1024):.1f} GB"
