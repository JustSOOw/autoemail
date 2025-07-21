# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 配置管理器
负责应用程序配置的加载、保存和管理
"""

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional

from models.config_model import ConfigModel
from utils.logger import get_logger


class ConfigManager:
    """配置管理器"""

    def __init__(self, config_file: Path):
        """
        初始化配置管理器

        Args:
            config_file: 配置文件路径
        """
        self.config_file = config_file
        self.logger = get_logger(__name__)
        self._config: Optional[ConfigModel] = None
        self._backup_count = 5

        # 确保配置目录存在
        self.config_file.parent.mkdir(parents=True, exist_ok=True)

        # 加载配置
        self.load_config()

    def load_config(self) -> ConfigModel:
        """
        加载配置文件

        Returns:
            配置模型实例
        """
        try:
            if self.config_file.exists():
                self.logger.info(f"加载配置文件: {self.config_file}")

                with open(self.config_file, "r", encoding="utf-8") as f:
                    config_data = json.load(f)

                self._config = ConfigModel.from_dict(config_data)
                self.logger.info("配置文件加载成功")

            else:
                self.logger.info("配置文件不存在，创建默认配置")
                self._config = ConfigModel()
                self.save_config()

        except Exception as e:
            self.logger.error(f"加载配置文件失败: {e}")
            self.logger.info("使用默认配置")
            self._config = ConfigModel()

        return self._config

    def save_config(self) -> bool:
        """
        保存配置文件

        Returns:
            是否保存成功
        """
        try:
            if self._config is None:
                self.logger.error("配置对象为空，无法保存")
                return False

            # 创建备份
            self._create_backup()

            # 保存配置
            config_data = self._config.to_dict()

            # 添加保存时间戳
            config_data["_metadata"] = {
                "saved_at": datetime.now().isoformat(),
                "version": "1.0.0",
            }

            with open(self.config_file, "w", encoding="utf-8") as f:
                json.dump(config_data, f, ensure_ascii=False, indent=2)

            self.logger.info(f"配置文件保存成功: {self.config_file}")
            return True

        except Exception as e:
            self.logger.error(f"保存配置文件失败: {e}")
            return False

    def get_config(self) -> ConfigModel:
        """
        获取配置对象

        Returns:
            配置模型实例
        """
        if self._config is None:
            self._config = self.load_config()
        return self._config

    def update_config(self, updates: Dict[str, Any]) -> bool:
        """
        更新配置

        Args:
            updates: 更新的配置项

        Returns:
            是否更新成功
        """
        try:
            config = self.get_config()

            # 更新域名配置
            if "domain_config" in updates:
                domain_updates = updates["domain_config"]
                for key, value in domain_updates.items():
                    if hasattr(config.domain_config, key):
                        setattr(config.domain_config, key, value)

            # 更新IMAP配置
            if "imap_config" in updates:
                imap_updates = updates["imap_config"]
                for key, value in imap_updates.items():
                    if hasattr(config.imap_config, key):
                        setattr(config.imap_config, key, value)

            # 更新TempMail配置
            if "tempmail_config" in updates:
                tempmail_updates = updates["tempmail_config"]
                for key, value in tempmail_updates.items():
                    if hasattr(config.tempmail_config, key):
                        setattr(config.tempmail_config, key, value)

            # 更新安全配置
            if "security_config" in updates:
                security_updates = updates["security_config"]
                for key, value in security_updates.items():
                    if hasattr(config.security_config, key):
                        setattr(config.security_config, key, value)

            # 更新系统配置
            if "system_config" in updates:
                system_updates = updates["system_config"]
                for key, value in system_updates.items():
                    if hasattr(config.system_config, key):
                        setattr(config.system_config, key, value)

            # 更新其他配置
            if "verification_method" in updates:
                config.verification_method = updates["verification_method"]

            if "custom_config" in updates:
                config.custom_config.update(updates["custom_config"])

            # 保存配置
            return self.save_config()

        except Exception as e:
            self.logger.error(f"更新配置失败: {e}")
            return False

    def reset_config(self) -> bool:
        """
        重置配置为默认值

        Returns:
            是否重置成功
        """
        try:
            self.logger.info("重置配置为默认值")
            self._config = ConfigModel()
            return self.save_config()

        except Exception as e:
            self.logger.error(f"重置配置失败: {e}")
            return False

    def export_config(self, export_file: Path) -> bool:
        """
        导出配置到文件

        Args:
            export_file: 导出文件路径

        Returns:
            是否导出成功
        """
        try:
            config = self.get_config()
            config_data = config.to_dict()

            # 添加导出信息
            config_data["_export_info"] = {
                "exported_at": datetime.now().isoformat(),
                "exported_from": str(self.config_file),
                "version": "1.0.0",
            }

            with open(export_file, "w", encoding="utf-8") as f:
                json.dump(config_data, f, ensure_ascii=False, indent=2)

            self.logger.info(f"配置导出成功: {export_file}")
            return True

        except Exception as e:
            self.logger.error(f"导出配置失败: {e}")
            return False

    def import_config(self, import_file: Path) -> bool:
        """
        从文件导入配置

        Args:
            import_file: 导入文件路径

        Returns:
            是否导入成功
        """
        try:
            if not import_file.exists():
                self.logger.error(f"导入文件不存在: {import_file}")
                return False

            with open(import_file, "r", encoding="utf-8") as f:
                config_data = json.load(f)

            # 移除导出信息
            config_data.pop("_export_info", None)
            config_data.pop("_metadata", None)

            # 创建配置对象
            imported_config = ConfigModel.from_dict(config_data)

            # 验证配置
            validation_errors = imported_config.validate_config()
            if validation_errors:
                self.logger.warning(f"导入的配置存在问题: {validation_errors}")

            # 创建当前配置的备份
            self._create_backup()

            # 应用导入的配置
            self._config = imported_config

            # 保存配置
            if self.save_config():
                self.logger.info(f"配置导入成功: {import_file}")
                return True
            else:
                self.logger.error("保存导入的配置失败")
                return False

        except Exception as e:
            self.logger.error(f"导入配置失败: {e}")
            return False

    def _create_backup(self):
        """创建配置文件备份"""
        try:
            if not self.config_file.exists():
                return

            # 备份目录
            backup_dir = self.config_file.parent / "backups"
            backup_dir.mkdir(exist_ok=True)

            # 备份文件名
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_file = backup_dir / f"{self.config_file.stem}_{timestamp}.backup"

            # 复制文件
            import shutil

            shutil.copy2(self.config_file, backup_file)

            # 清理旧备份
            self._cleanup_old_backups(backup_dir)

            self.logger.debug(f"创建配置备份: {backup_file}")

        except Exception as e:
            self.logger.warning(f"创建配置备份失败: {e}")

    def _cleanup_old_backups(self, backup_dir: Path):
        """清理旧的备份文件"""
        try:
            backup_files = list(backup_dir.glob("*.backup"))
            backup_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)

            # 保留最新的几个备份
            for old_backup in backup_files[self._backup_count :]:
                old_backup.unlink()
                self.logger.debug(f"删除旧备份: {old_backup}")

        except Exception as e:
            self.logger.warning(f"清理旧备份失败: {e}")

    def get_backup_files(self) -> list:
        """获取备份文件列表"""
        try:
            backup_dir = self.config_file.parent / "backups"
            if not backup_dir.exists():
                return []

            backup_files = list(backup_dir.glob("*.backup"))
            backup_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)

            return [
                {
                    "file": backup_file,
                    "name": backup_file.name,
                    "created_at": datetime.fromtimestamp(backup_file.stat().st_mtime),
                    "size": backup_file.stat().st_size,
                }
                for backup_file in backup_files
            ]

        except Exception as e:
            self.logger.error(f"获取备份文件列表失败: {e}")
            return []

    def restore_from_backup(self, backup_file: Path) -> bool:
        """从备份恢复配置"""
        try:
            if not backup_file.exists():
                self.logger.error(f"备份文件不存在: {backup_file}")
                return False

            # 创建当前配置的备份
            self._create_backup()

            # 恢复备份
            import shutil

            shutil.copy2(backup_file, self.config_file)

            # 重新加载配置
            self.load_config()

            self.logger.info(f"从备份恢复配置成功: {backup_file}")
            return True

        except Exception as e:
            self.logger.error(f"从备份恢复配置失败: {e}")
            return False

    def validate_current_config(self) -> Dict[str, list]:
        """验证当前配置"""
        config = self.get_config()
        return config.validate_config()

    def is_configured(self) -> bool:
        """检查是否已完成基本配置"""
        config = self.get_config()
        return config.is_configured()

    def get_missing_config(self) -> list:
        """获取缺失的配置项"""
        config = self.get_config()
        return config.get_missing_config()

    def __str__(self) -> str:
        """字符串表示"""
        return f"ConfigManager(file={self.config_file})"
