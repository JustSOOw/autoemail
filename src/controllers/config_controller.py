# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 配置控制器
负责配置相关的业务逻辑控制和QML交互
"""

import json
from typing import Dict, Any, Optional

from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot
from PyQt6.QtQml import qmlRegisterType

from models.config_model import ConfigModel, DomainConfig, SecurityConfig, SystemConfig
from services.config_service import ConfigService
from services.database_service import DatabaseService
from utils.config_manager import ConfigManager
from utils.logger import get_logger


class ConfigController(QObject):
    """
    配置控制器 - 连接QML和Python配置管理
    负责处理所有配置相关的操作和状态管理
    """

    # 信号定义 - QML可以监听这些信号
    configLoaded = pyqtSignal('QVariantMap')  # config_data
    configSaved = pyqtSignal(bool, str)  # success, message
    domainValidated = pyqtSignal(bool, str)  # is_valid, message
    statusChanged = pyqtSignal(str)  # status_message
    errorOccurred = pyqtSignal(str, str)  # error_type, error_message

    def __init__(self, config_manager: ConfigManager, database_service: DatabaseService):
        """
        初始化配置控制器
        
        Args:
            config_manager: 配置管理器
            database_service: 数据库服务
        """
        super().__init__()
        self.config_manager = config_manager
        self.database_service = database_service
        self.logger = get_logger(__name__)
        
        # 初始化配置服务
        self.config_service = ConfigService(database_service)
        
        # 当前配置缓存
        self._current_config: Optional[ConfigModel] = None
        
        self.logger.info("配置控制器初始化完成")

    @pyqtSlot()
    def loadConfig(self):
        """加载配置 - QML调用的方法"""
        try:
            self.statusChanged.emit("正在加载配置...")
            
            # 从配置管理器加载配置
            config = self.config_manager.get_config()
            self._current_config = config
            
            # 转换为QML可用的格式
            config_data = self._config_to_qml_format(config)
            
            # 发送信号
            self.configLoaded.emit(config_data)
            self.statusChanged.emit("配置加载完成")
            
            self.logger.info("配置加载成功")
            
        except Exception as e:
            self.logger.error(f"配置加载失败: {e}")
            self.errorOccurred.emit("加载失败", str(e))
            self.statusChanged.emit(f"配置加载失败: {e}")

    @pyqtSlot('QVariantMap')
    def saveConfig(self, config_data):
        """
        保存配置 - QML调用的方法
        
        Args:
            config_data: 配置数据字典
        """
        try:
            self.statusChanged.emit("正在保存配置...")
            
            # 转换QML数据为配置模型
            config = self._qml_format_to_config(config_data)
            
            # 验证配置
            validation_errors = config.validate_config()
            if validation_errors:
                error_msg = f"配置验证失败: {', '.join(validation_errors)}"
                self.configSaved.emit(False, error_msg)
                self.errorOccurred.emit("验证失败", error_msg)
                return
            
            # 保存配置
            success = self.config_manager.save_config(config)
            
            if success:
                self._current_config = config
                self.configSaved.emit(True, "配置保存成功")
                self.statusChanged.emit("配置保存成功")
                self.logger.info("配置保存成功")
            else:
                self.configSaved.emit(False, "配置保存失败")
                self.errorOccurred.emit("保存失败", "配置保存失败")
                
        except Exception as e:
            self.logger.error(f"配置保存失败: {e}")
            self.configSaved.emit(False, f"配置保存失败: {e}")
            self.errorOccurred.emit("保存失败", str(e))
            self.statusChanged.emit(f"配置保存失败: {e}")

    @pyqtSlot(str)
    def validateDomain(self, domain: str):
        """
        验证域名 - QML调用的方法
        
        Args:
            domain: 域名
        """
        try:
            self.statusChanged.emit(f"正在验证域名: {domain}")
            
            # 基础域名格式验证
            if not domain or not domain.strip():
                self.domainValidated.emit(False, "域名不能为空")
                return
            
            domain = domain.strip().lower()
            
            # 简单的域名格式检查
            import re
            domain_pattern = r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$'
            
            if not re.match(domain_pattern, domain):
                self.domainValidated.emit(False, "域名格式不正确")
                return
            
            # 检查域名长度
            if len(domain) > 253:
                self.domainValidated.emit(False, "域名长度超过限制")
                return
            
            # 验证成功
            self.domainValidated.emit(True, "域名格式正确")
            self.statusChanged.emit(f"域名验证成功: {domain}")
            
            self.logger.info(f"域名验证成功: {domain}")
            
        except Exception as e:
            self.logger.error(f"域名验证失败: {e}")
            self.domainValidated.emit(False, f"验证失败: {e}")
            self.errorOccurred.emit("验证失败", str(e))

    @pyqtSlot(result=str)
    def getCurrentDomain(self):
        """获取当前域名 - QML调用的方法"""
        try:
            if self._current_config:
                return self._current_config.get_domain() or ""
            
            config = self.config_manager.get_config()
            return config.get_domain() or "" if config else ""
            
        except Exception as e:
            self.logger.error(f"获取当前域名失败: {e}")
            return ""

    @pyqtSlot(str)
    def setDomain(self, domain: str):
        """
        设置域名 - QML调用的方法
        
        Args:
            domain: 域名
        """
        try:
            # 获取当前配置
            if not self._current_config:
                self._current_config = self.config_manager.get_config()
            
            # 设置域名
            self._current_config.domain_config.domain = domain.strip()
            
            # 保存配置
            success = self.config_manager.save_config(self._current_config)
            
            if success:
                self.statusChanged.emit(f"域名设置成功: {domain}")
                self.logger.info(f"域名设置成功: {domain}")
            else:
                self.errorOccurred.emit("设置失败", "域名设置失败")
                
        except Exception as e:
            self.logger.error(f"域名设置失败: {e}")
            self.errorOccurred.emit("设置失败", str(e))

    @pyqtSlot(result=bool)
    def isConfigured(self):
        """检查是否已配置 - QML调用的方法"""
        try:
            if self._current_config:
                return self._current_config.is_configured()
            
            config = self.config_manager.get_config()
            return config.is_configured() if config else False
            
        except Exception as e:
            self.logger.error(f"检查配置状态失败: {e}")
            return False

    @pyqtSlot()
    def resetConfig(self):
        """重置配置 - QML调用的方法"""
        try:
            self.statusChanged.emit("正在重置配置...")
            
            # 创建默认配置
            default_config = ConfigModel()
            
            # 保存默认配置
            success = self.config_manager.save_config(default_config)
            
            if success:
                self._current_config = default_config
                config_data = self._config_to_qml_format(default_config)
                self.configLoaded.emit(config_data)
                self.statusChanged.emit("配置重置成功")
                self.logger.info("配置重置成功")
            else:
                self.errorOccurred.emit("重置失败", "配置重置失败")
                
        except Exception as e:
            self.logger.error(f"配置重置失败: {e}")
            self.errorOccurred.emit("重置失败", str(e))

    def _config_to_qml_format(self, config: ConfigModel) -> Dict[str, Any]:
        """将配置模型转换为QML可用的格式"""
        try:
            return {
                # 域名配置
                "domain": config.domain_config.domain or "",
                "domain_verified": config.domain_config.dns_verified,
                
                # 安全配置
                "encrypt_sensitive_data": config.security_config.encrypt_sensitive_data,
                "auto_lock_enabled": config.security_config.auto_lock_enabled,
                "auto_lock_timeout": config.security_config.auto_lock_minutes,
                "log_level": config.security_config.log_level,
                
                # 系统配置
                "auto_start": False,  # 暂时硬编码，后续可以添加到SystemConfig
                "remember_window_state": True,
                "show_notifications": True,
                "theme": config.system_config.ui_theme,
                
                # 其他信息
                "is_configured": config.is_configured(),
                "created_at": "",  # ConfigModel没有created_at属性
                "updated_at": ""   # ConfigModel没有updated_at属性
            }
        except Exception as e:
            self.logger.error(f"配置转换失败: {e}")
            return {}

    def _qml_format_to_config(self, config_data: Dict[str, Any]) -> ConfigModel:
        """将QML格式的数据转换为配置模型"""
        try:
            # 创建配置模型
            config = ConfigModel()
            
            # 域名配置
            config.domain_config.domain = config_data.get("domain", "")
            config.domain_config.dns_verified = config_data.get("domain_verified", False)
            
            # 安全配置
            config.security_config.encrypt_sensitive_data = config_data.get("encrypt_sensitive_data", True)
            config.security_config.auto_lock_enabled = config_data.get("auto_lock_enabled", False)
            config.security_config.auto_lock_minutes = config_data.get("auto_lock_timeout", 30)
            config.security_config.log_level = config_data.get("log_level", "INFO")
            
            # 系统配置
            # 注意：这些配置项暂时不保存到SystemConfig，因为SystemConfig主要用于系统级配置
            # 如果需要持久化这些UI配置，可以考虑添加到custom_config中
            config.system_config.ui_theme = config_data.get("theme", "light")
            
            return config
            
        except Exception as e:
            self.logger.error(f"QML数据转换失败: {e}")
            return ConfigModel()

    @staticmethod
    def register_qml_type():
        """注册QML类型"""
        qmlRegisterType(ConfigController, "EmailManager", 1, 0, "ConfigController")
