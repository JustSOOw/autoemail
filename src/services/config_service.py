# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 配置服务
负责配置的加载、保存和管理
"""

import json
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List

from models.config_model import ConfigModel
from services.database_service import DatabaseService
from utils.logger import get_logger


class ConfigService:
    """
    配置服务类
    
    负责配置的持久化存储和管理
    """

    def __init__(self, db_service: DatabaseService):
        """
        初始化配置服务
        
        Args:
            db_service: 数据库服务实例
        """
        self.db_service = db_service
        self.logger = get_logger(__name__)
        self._config_cache = None
        
        self.logger.info("配置服务初始化完成")

    def load_config(self, master_password: Optional[str] = None) -> ConfigModel:
        """
        加载配置
        
        Args:
            master_password: 主密码，用于解密敏感数据
            
        Returns:
            配置模型实例
        """
        try:
            # 从数据库加载配置
            config_data = self._load_config_from_db()
            
            # 创建配置模型
            if config_data:
                config = ConfigModel.from_dict(config_data)
            else:
                config = ConfigModel()
                # 保存默认配置
                self.save_config(config)
            
            # 解密敏感数据
            if master_password and config.security_config.encrypt_sensitive_data:
                try:
                    config.decrypt_sensitive_data(master_password)
                except Exception as e:
                    self.logger.warning(f"解密配置失败: {e}")
            
            self._config_cache = config
            self.logger.info("配置加载完成")
            
            return config
            
        except Exception as e:
            self.logger.error(f"加载配置失败: {e}")
            # 返回默认配置
            return ConfigModel()

    def save_config(self, config: ConfigModel, master_password: Optional[str] = None) -> bool:
        """
        保存配置
        
        Args:
            config: 配置模型实例
            master_password: 主密码，用于加密敏感数据
            
        Returns:
            是否保存成功
        """
        try:
            # 创建配置副本用于保存
            config_copy = ConfigModel.from_dict(config.to_dict())
            
            # 加密敏感数据
            if master_password and config.security_config.encrypt_sensitive_data:
                try:
                    config_copy.encrypt_sensitive_data(master_password)
                except Exception as e:
                    self.logger.warning(f"加密配置失败: {e}")
            
            # 保存到数据库
            success = self._save_config_to_db(config_copy.to_dict())
            
            if success:
                self._config_cache = config
                self.logger.info("配置保存成功")
            
            return success
            
        except Exception as e:
            self.logger.error(f"保存配置失败: {e}")
            return False

    def get_config_value(self, key: str, default: Any = None) -> Any:
        """
        获取配置值

        Args:
            key: 配置键，支持点分隔的嵌套键
            default: 默认值

        Returns:
            配置值
        """
        try:
            # 首先尝试从数据库直接获取
            query = "SELECT config_value, config_type FROM configurations WHERE config_key = ? AND is_active = 1"
            result = self.db_service.execute_query(query, (key,), fetch_one=True)

            if result:
                config_value = result["config_value"]
                config_type = result["config_type"]

                # 根据类型转换值
                if config_type == "dict" or config_type == "list":
                    try:
                        return json.loads(config_value)
                    except json.JSONDecodeError:
                        return default
                elif config_type == "int":
                    try:
                        return int(config_value)
                    except ValueError:
                        return default
                elif config_type == "float":
                    try:
                        return float(config_value)
                    except ValueError:
                        return default
                elif config_type == "bool":
                    return config_value.lower() in ("true", "1", "yes")
                else:
                    return config_value

            # 如果数据库中没有，尝试从配置模型获取
            if not self._config_cache:
                self._config_cache = self.load_config()

            # 解析嵌套键
            keys = key.split('.')
            value = self._config_cache.to_dict()

            for k in keys:
                if isinstance(value, dict) and k in value:
                    value = value[k]
                else:
                    return default

            return value

        except Exception as e:
            self.logger.error(f"获取配置值失败: {e}")
            return default

    def set_config_value(self, key: str, value: Any) -> bool:
        """
        设置配置值

        Args:
            key: 配置键，支持点分隔的嵌套键
            value: 配置值

        Returns:
            是否设置成功
        """
        try:
            # 直接保存到数据库
            query = """
                INSERT OR REPLACE INTO configurations
                (config_key, config_value, config_type, updated_at, is_active)
                VALUES (?, ?, ?, ?, 1)
            """

            # 确定配置值类型
            config_type = type(value).__name__
            config_value = json.dumps(value) if isinstance(value, (dict, list)) else str(value)

            affected_rows = self.db_service.execute_update(
                query,
                (key, config_value, config_type, datetime.now().isoformat())
            )

            # 清除缓存
            self.clear_cache()

            success = affected_rows > 0
            if success:
                self.logger.debug(f"设置配置值成功: {key} = {value}")

            return success

        except Exception as e:
            self.logger.error(f"设置配置值失败: {e}")
            return False

    def export_config(self, include_sensitive: bool = False) -> str:
        """
        导出配置
        
        Args:
            include_sensitive: 是否包含敏感数据
            
        Returns:
            配置JSON字符串
        """
        try:
            if not self._config_cache:
                self._config_cache = self.load_config()
            
            config_dict = self._config_cache.to_dict()
            
            # 如果不包含敏感数据，则移除敏感字段
            if not include_sensitive:
                if "imap_config" in config_dict:
                    config_dict["imap_config"]["password"] = ""
                if "tempmail_config" in config_dict:
                    config_dict["tempmail_config"]["epin"] = ""
                if "security_config" in config_dict:
                    config_dict["security_config"]["master_password_hash"] = ""
            
            return json.dumps(config_dict, ensure_ascii=False, indent=2)
            
        except Exception as e:
            self.logger.error(f"导出配置失败: {e}")
            return "{}"

    def import_config(self, config_json: str, master_password: Optional[str] = None) -> bool:
        """
        导入配置
        
        Args:
            config_json: 配置JSON字符串
            master_password: 主密码
            
        Returns:
            是否导入成功
        """
        try:
            config_dict = json.loads(config_json)
            config = ConfigModel.from_dict(config_dict)
            
            # 验证配置
            errors = config.validate_config()
            if errors:
                self.logger.error(f"配置验证失败: {errors}")
                return False
            
            return self.save_config(config, master_password)
            
        except Exception as e:
            self.logger.error(f"导入配置失败: {e}")
            return False

    def reset_config(self) -> bool:
        """
        重置配置为默认值
        
        Returns:
            是否重置成功
        """
        try:
            default_config = ConfigModel()
            success = self.save_config(default_config)
            
            if success:
                self._config_cache = default_config
                self.logger.info("配置已重置为默认值")
            
            return success
            
        except Exception as e:
            self.logger.error(f"重置配置失败: {e}")
            return False

    def backup_config(self, backup_path: Path) -> bool:
        """
        备份配置
        
        Args:
            backup_path: 备份文件路径
            
        Returns:
            是否备份成功
        """
        try:
            config_json = self.export_config(include_sensitive=True)
            
            # 确保备份目录存在
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            
            # 写入备份文件
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(config_json)
            
            self.logger.info(f"配置备份成功: {backup_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"备份配置失败: {e}")
            return False

    def restore_config(self, backup_path: Path, master_password: Optional[str] = None) -> bool:
        """
        恢复配置
        
        Args:
            backup_path: 备份文件路径
            master_password: 主密码
            
        Returns:
            是否恢复成功
        """
        try:
            if not backup_path.exists():
                self.logger.error(f"备份文件不存在: {backup_path}")
                return False
            
            # 读取备份文件
            with open(backup_path, 'r', encoding='utf-8') as f:
                config_json = f.read()
            
            # 导入配置
            success = self.import_config(config_json, master_password)
            
            if success:
                self.logger.info(f"配置恢复成功: {backup_path}")
            
            return success
            
        except Exception as e:
            self.logger.error(f"恢复配置失败: {e}")
            return False

    def _load_config_from_db(self) -> Optional[Dict[str, Any]]:
        """从数据库加载配置"""
        try:
            # 获取所有配置项
            query = "SELECT config_key, config_value, config_type FROM configurations WHERE is_active = 1"
            results = self.db_service.execute_query(query)
            
            if not results:
                return None
            
            # 组织配置数据
            config_data = {}
            
            for row in results:
                key = row["config_key"]
                value = row["config_value"]
                config_type = row["config_type"]
                
                # 解析JSON值
                if config_type == "json" and value:
                    try:
                        value = json.loads(value)
                    except:
                        pass
                
                # 设置嵌套键值
                self._set_nested_value(config_data, key, value)
            
            return config_data
            
        except Exception as e:
            self.logger.error(f"从数据库加载配置失败: {e}")
            return None

    def _save_config_to_db(self, config_dict: Dict[str, Any]) -> bool:
        """保存配置到数据库"""
        try:
            # 扁平化配置字典
            flat_config = self._flatten_dict(config_dict)
            
            with self.db_service.get_cursor() as cursor:
                for key, value in flat_config.items():
                    # 确定配置类型
                    config_type = "string"
                    if isinstance(value, (dict, list)):
                        config_type = "json"
                        value = json.dumps(value, ensure_ascii=False)
                    elif isinstance(value, bool):
                        config_type = "boolean"
                        value = str(value)
                    elif isinstance(value, (int, float)):
                        config_type = "number"
                        value = str(value)
                    
                    # 插入或更新配置
                    cursor.execute(
                        """
                        INSERT OR REPLACE INTO configurations 
                        (config_key, config_value, config_type, updated_at) 
                        VALUES (?, ?, ?, ?)
                        """,
                        (key, value, config_type, "datetime('now')")
                    )
            
            return True
            
        except Exception as e:
            self.logger.error(f"保存配置到数据库失败: {e}")
            return False

    def _flatten_dict(self, d: Dict[str, Any], parent_key: str = "", sep: str = ".") -> Dict[str, Any]:
        """扁平化字典"""
        items = []
        for k, v in d.items():
            new_key = f"{parent_key}{sep}{k}" if parent_key else k
            if isinstance(v, dict):
                items.extend(self._flatten_dict(v, new_key, sep=sep).items())
            else:
                items.append((new_key, v))
        return dict(items)

    def _set_nested_value(self, d: Dict[str, Any], key: str, value: Any):
        """设置嵌套字典值"""
        keys = key.split('.')
        for k in keys[:-1]:
            d = d.setdefault(k, {})
        d[keys[-1]] = value

    def validate_config(self, config: ConfigModel) -> Dict[str, str]:
        """
        验证配置

        Args:
            config: 配置模型实例

        Returns:
            验证错误字典，键为字段名，值为错误信息
        """
        try:
            return config.validate_config()
        except Exception as e:
            self.logger.error(f"验证配置失败: {e}")
            return {"validation_error": str(e)}

    def get_config_summary(self) -> Dict[str, Any]:
        """
        获取配置摘要信息

        Returns:
            配置摘要字典
        """
        try:
            if not self._config_cache:
                self._config_cache = self.load_config()

            config = self._config_cache

            return {
                "domain": config.get_domain(),
                "verification_method": config.get_verification_method(),
                "domain_configured": config.is_domain_configured(),
                "encryption_enabled": config.security_config.encrypt_sensitive_data,
                "master_password_set": config.is_master_password_set(),
                "last_updated": datetime.now().isoformat()
            }

        except Exception as e:
            self.logger.error(f"获取配置摘要失败: {e}")
            return {}

    def update_domain_config(self, domain: str, enable_wildcard: bool = False) -> bool:
        """
        更新域名配置

        Args:
            domain: 域名
            enable_wildcard: 是否启用通配符

        Returns:
            是否更新成功
        """
        try:
            if not self._config_cache:
                self._config_cache = self.load_config()

            self._config_cache.domain_config.domain = domain
            self._config_cache.domain_config.enable_wildcard = enable_wildcard

            return self.save_config(self._config_cache)

        except Exception as e:
            self.logger.error(f"更新域名配置失败: {e}")
            return False

    def update_verification_method(self, method: str) -> bool:
        """
        更新验证方式

        Args:
            method: 验证方式 ("tempmail" 或 "imap")

        Returns:
            是否更新成功
        """
        try:
            if method not in ["tempmail", "imap"]:
                raise ValueError(f"不支持的验证方式: {method}")

            if not self._config_cache:
                self._config_cache = self.load_config()

            self._config_cache.verification_method = method

            return self.save_config(self._config_cache)

        except Exception as e:
            self.logger.error(f"更新验证方式失败: {e}")
            return False

    def clear_cache(self):
        """清除配置缓存"""
        self._config_cache = None
        self.logger.debug("配置缓存已清除")

    def get_config_history(self, limit: int = 10) -> List[Dict[str, Any]]:
        """
        获取配置变更历史

        Args:
            limit: 限制数量

        Returns:
            配置历史列表
        """
        try:
            query = """
                SELECT config_key, config_value, updated_at, version
                FROM configurations
                WHERE is_active = 1
                ORDER BY updated_at DESC
                LIMIT ?
            """
            results = self.db_service.execute_query(query, (limit,))

            history = []
            for row in results or []:
                history.append({
                    "key": row["config_key"],
                    "value": row["config_value"],
                    "updated_at": row["updated_at"],
                    "version": row.get("version", 1)
                })

            return history

        except Exception as e:
            self.logger.error(f"获取配置历史失败: {e}")
            return []
