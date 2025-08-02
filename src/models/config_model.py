# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 配置数据模型
定义应用程序配置的数据结构
"""

import json
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, Optional


class ConfigType(Enum):
    """配置类型枚举"""

    DOMAIN = "domain"  # 域名配置
    IMAP = "imap"  # IMAP配置
    TEMPMAIL = "tempmail"  # tempmail配置
    SECURITY = "security"  # 安全配置
    SYSTEM = "system"  # 系统配置


@dataclass
class DomainConfig:
    """域名配置"""

    domain: str = ""
    dns_verified: bool = False
    mx_record_verified: bool = False
    cloudflare_verified: bool = False
    last_verified: Optional[str] = None


@dataclass
class IMAPConfig:
    """IMAP配置"""

    server: str = ""
    port: int = 993
    username: str = ""
    password: str = ""  # 加密存储
    protocol: str = "IMAP"  # IMAP 或 POP3
    inbox_dir: str = "inbox"
    use_ssl: bool = True
    connection_timeout: int = 30


@dataclass
class TempMailConfig:
    """TempMail配置"""

    username: str = ""
    epin: str = ""  # 加密存储
    extension: str = "@mailto.plus"
    api_timeout: int = 30


@dataclass
class SecurityConfig:
    """安全配置"""

    master_password_hash: str = ""  # 主密码哈希
    encrypt_sensitive_data: bool = True
    auto_lock_enabled: bool = True
    auto_lock_minutes: int = 30
    log_level: str = "INFO"
    remember_password: bool = False


@dataclass
class SystemConfig:
    """系统配置"""

    app_version: str = "1.0.0"
    database_version: str = "1.0.0"
    auto_cleanup_days: int = 30
    max_verification_attempts: int = 5
    default_timeout: int = 300
    ui_theme: str = "default"
    language: str = "zh_CN"
    window_geometry: str = ""
    window_state: str = ""


@dataclass
class ConfigModel:
    """
    配置数据模型

    包含应用程序的所有配置信息
    """

    # 各类配置
    domain_config: DomainConfig = field(default_factory=DomainConfig)
    imap_config: IMAPConfig = field(default_factory=IMAPConfig)
    tempmail_config: TempMailConfig = field(default_factory=TempMailConfig)
    security_config: SecurityConfig = field(default_factory=SecurityConfig)
    system_config: SystemConfig = field(default_factory=SystemConfig)

    # 邮箱验证方式选择
    verification_method: str = "auto"  # auto, tempmail, imap

    # 扩展配置
    custom_config: Dict[str, Any] = field(default_factory=dict)

    def get_domain(self) -> str:
        """获取域名"""
        return self.domain_config.domain

    def set_domain(self, domain: str):
        """设置域名"""
        self.domain_config.domain = domain

    def is_domain_configured(self) -> bool:
        """域名是否已配置"""
        return bool(self.domain_config.domain)

    def is_imap_configured(self) -> bool:
        """IMAP是否已配置"""
        return bool(
            self.imap_config.server
            and self.imap_config.username
            and self.imap_config.password
        )

    def is_tempmail_configured(self) -> bool:
        """TempMail是否已配置"""
        return bool(self.tempmail_config.username and self.tempmail_config.epin)

    def get_verification_method(self) -> str:
        """获取验证方式"""
        if self.verification_method == "auto":
            # 自动选择：优先tempmail，其次IMAP
            if self.is_tempmail_configured():
                return "tempmail"
            elif self.is_imap_configured():
                return "imap"
            else:
                return "none"
        return self.verification_method

    def is_configured(self) -> bool:
        """是否已完成基本配置"""
        # 简化配置要求：只需要域名配置即可
        return self.is_domain_configured()

    def get_missing_config(self) -> list:
        """获取缺失的配置项"""
        missing = []

        if not self.is_domain_configured():
            missing.append("域名配置")

        if not self.is_imap_configured() and not self.is_tempmail_configured():
            missing.append("邮箱验证配置")

        return missing

    def validate_config(self) -> Dict[str, list]:
        """验证配置"""
        errors = {}

        # 验证域名配置
        domain_errors = []
        if not self.domain_config.domain:
            domain_errors.append("域名不能为空")
        elif not self._is_valid_domain(self.domain_config.domain):
            domain_errors.append("域名格式无效")

        if domain_errors:
            errors["domain"] = domain_errors

        # 验证IMAP配置
        if self.verification_method in ["auto", "imap"]:
            imap_errors = []
            if not self.imap_config.server:
                imap_errors.append("IMAP服务器不能为空")
            if not self.imap_config.username:
                imap_errors.append("IMAP用户名不能为空")
            if not self.imap_config.password:
                imap_errors.append("IMAP密码不能为空")
            if not (1 <= self.imap_config.port <= 65535):
                imap_errors.append("IMAP端口必须在1-65535之间")

            if imap_errors:
                errors["imap"] = imap_errors

        # 验证TempMail配置
        if self.verification_method in ["auto", "tempmail"]:
            tempmail_errors = []
            if not self.tempmail_config.username:
                tempmail_errors.append("TempMail用户名不能为空")
            if not self.tempmail_config.epin:
                tempmail_errors.append("TempMail EPIN不能为空")

            if tempmail_errors:
                errors["tempmail"] = tempmail_errors

        return errors

    def _is_valid_domain(self, domain: str) -> bool:
        """验证域名格式"""
        import re

        pattern = r"^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$"
        return bool(re.match(pattern, domain)) and len(domain) <= 253

    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "domain_config": {
                "domain": self.domain_config.domain,
                "dns_verified": self.domain_config.dns_verified,
                "mx_record_verified": self.domain_config.mx_record_verified,
                "cloudflare_verified": self.domain_config.cloudflare_verified,
                "last_verified": self.domain_config.last_verified,
            },
            "imap_config": {
                "server": self.imap_config.server,
                "port": self.imap_config.port,
                "username": self.imap_config.username,
                "password": self.imap_config.password,
                "protocol": self.imap_config.protocol,
                "inbox_dir": self.imap_config.inbox_dir,
                "use_ssl": self.imap_config.use_ssl,
                "connection_timeout": self.imap_config.connection_timeout,
            },
            "tempmail_config": {
                "username": self.tempmail_config.username,
                "epin": self.tempmail_config.epin,
                "extension": self.tempmail_config.extension,
                "api_timeout": self.tempmail_config.api_timeout,
            },
            "security_config": {
                "master_password_hash": self.security_config.master_password_hash,
                "encrypt_sensitive_data": self.security_config.encrypt_sensitive_data,
                "auto_lock_enabled": self.security_config.auto_lock_enabled,
                "auto_lock_minutes": self.security_config.auto_lock_minutes,
                "log_level": self.security_config.log_level,
                "remember_password": self.security_config.remember_password,
            },
            "system_config": {
                "app_version": self.system_config.app_version,
                "database_version": self.system_config.database_version,
                "auto_cleanup_days": self.system_config.auto_cleanup_days,
                "max_verification_attempts": self.system_config.max_verification_attempts,
                "default_timeout": self.system_config.default_timeout,
                "ui_theme": self.system_config.ui_theme,
                "language": self.system_config.language,
                "window_geometry": self.system_config.window_geometry,
                "window_state": self.system_config.window_state,
            },
            "verification_method": self.verification_method,
            "custom_config": self.custom_config.copy(),
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "ConfigModel":
        """从字典创建实例"""
        instance = cls()

        # 域名配置
        if "domain_config" in data:
            dc = data["domain_config"]
            instance.domain_config = DomainConfig(
                domain=dc.get("domain", ""),
                dns_verified=dc.get("dns_verified", False),
                mx_record_verified=dc.get("mx_record_verified", False),
                cloudflare_verified=dc.get("cloudflare_verified", False),
                last_verified=dc.get("last_verified"),
            )

        # IMAP配置
        if "imap_config" in data:
            ic = data["imap_config"]
            instance.imap_config = IMAPConfig(
                server=ic.get("server", ""),
                port=ic.get("port", 993),
                username=ic.get("username", ""),
                password=ic.get("password", ""),
                protocol=ic.get("protocol", "IMAP"),
                inbox_dir=ic.get("inbox_dir", "inbox"),
                use_ssl=ic.get("use_ssl", True),
                connection_timeout=ic.get("connection_timeout", 30),
            )

        # TempMail配置
        if "tempmail_config" in data:
            tc = data["tempmail_config"]
            instance.tempmail_config = TempMailConfig(
                username=tc.get("username", ""),
                epin=tc.get("epin", ""),
                extension=tc.get("extension", "@mailto.plus"),
                api_timeout=tc.get("api_timeout", 30),
            )

        # 安全配置
        if "security_config" in data:
            sc = data["security_config"]
            instance.security_config = SecurityConfig(
                master_password_hash=sc.get("master_password_hash", ""),
                encrypt_sensitive_data=sc.get("encrypt_sensitive_data", True),
                auto_lock_enabled=sc.get("auto_lock_enabled", True),
                auto_lock_minutes=sc.get("auto_lock_minutes", 30),
                log_level=sc.get("log_level", "INFO"),
                remember_password=sc.get("remember_password", False),
            )

        # 系统配置
        if "system_config" in data:
            sysc = data["system_config"]
            instance.system_config = SystemConfig(
                app_version=sysc.get("app_version", "1.0.0"),
                database_version=sysc.get("database_version", "1.0.0"),
                auto_cleanup_days=sysc.get("auto_cleanup_days", 30),
                max_verification_attempts=sysc.get("max_verification_attempts", 5),
                default_timeout=sysc.get("default_timeout", 300),
                ui_theme=sysc.get("ui_theme", "default"),
                language=sysc.get("language", "zh_CN"),
                window_geometry=sysc.get("window_geometry", ""),
                window_state=sysc.get("window_state", ""),
            )

        # 其他配置
        instance.verification_method = data.get("verification_method", "auto")
        instance.custom_config = data.get("custom_config", {}).copy()

        return instance

    def to_json(self) -> str:
        """转换为JSON字符串"""
        return json.dumps(self.to_dict(), ensure_ascii=False, indent=2)

    @classmethod
    def from_json(cls, json_str: str) -> "ConfigModel":
        """从JSON字符串创建实例"""
        data = json.loads(json_str)
        return cls.from_dict(data)

    def encrypt_sensitive_data(self, master_password: Optional[str] = None):
        """
        加密敏感数据

        Args:
            master_password: 主密码，如果为None则使用默认加密
        """
        try:
            from utils.encryption import get_encryption_manager
            encryption_manager = get_encryption_manager(master_password)

            # 加密IMAP密码
            if self.imap_config.password and not encryption_manager.is_encrypted(self.imap_config.password):
                self.imap_config.password = encryption_manager.encrypt(self.imap_config.password)

            # 加密TempMail EPIN
            if self.tempmail_config.epin and not encryption_manager.is_encrypted(self.tempmail_config.epin):
                self.tempmail_config.epin = encryption_manager.encrypt(self.tempmail_config.epin)

            # 标记已启用加密
            self.security_config.encrypt_sensitive_data = True

        except Exception as e:
            raise ValueError(f"加密敏感数据失败: {e}")

    def decrypt_sensitive_data(self, master_password: Optional[str] = None):
        """
        解密敏感数据

        Args:
            master_password: 主密码，如果为None则使用默认加密
        """
        try:
            from utils.encryption import get_encryption_manager
            encryption_manager = get_encryption_manager(master_password)

            # 解密IMAP密码
            if self.imap_config.password and encryption_manager.is_encrypted(self.imap_config.password):
                self.imap_config.password = encryption_manager.decrypt(self.imap_config.password)

            # 解密TempMail EPIN
            if self.tempmail_config.epin and encryption_manager.is_encrypted(self.tempmail_config.epin):
                self.tempmail_config.epin = encryption_manager.decrypt(self.tempmail_config.epin)

        except Exception as e:
            raise ValueError(f"解密敏感数据失败: {e}")

    def get_decrypted_imap_password(self, master_password: Optional[str] = None) -> str:
        """
        获取解密后的IMAP密码

        Args:
            master_password: 主密码

        Returns:
            解密后的密码
        """
        if not self.imap_config.password:
            return ""

        try:
            from utils.encryption import get_encryption_manager
            encryption_manager = get_encryption_manager(master_password)
            if encryption_manager.is_encrypted(self.imap_config.password):
                return encryption_manager.decrypt(self.imap_config.password)
            else:
                return self.imap_config.password
        except:
            return self.imap_config.password

    def get_decrypted_tempmail_epin(self, master_password: Optional[str] = None) -> str:
        """
        获取解密后的TempMail EPIN

        Args:
            master_password: 主密码

        Returns:
            解密后的EPIN
        """
        if not self.tempmail_config.epin:
            return ""

        try:
            from utils.encryption import get_encryption_manager
            encryption_manager = get_encryption_manager(master_password)
            if encryption_manager.is_encrypted(self.tempmail_config.epin):
                return encryption_manager.decrypt(self.tempmail_config.epin)
            else:
                return self.tempmail_config.epin
        except:
            return self.tempmail_config.epin

    def set_master_password(self, password: str) -> tuple:
        """
        设置主密码

        Args:
            password: 主密码

        Returns:
            (密码哈希, 盐值) 的元组
        """
        from utils.encryption import hash_master_password

        password_hash, salt = hash_master_password(password)
        self.security_config.master_password_hash = f"{password_hash}:{salt}"

        return password_hash, salt

    def verify_master_password(self, password: str) -> bool:
        """
        验证主密码

        Args:
            password: 输入的密码

        Returns:
            密码是否正确
        """
        if not self.security_config.master_password_hash:
            return False

        try:
            from utils.encryption import verify_master_password

            parts = self.security_config.master_password_hash.split(':')
            if len(parts) != 2:
                return False

            password_hash, salt = parts
            return verify_master_password(password, password_hash, salt)

        except:
            return False

    def is_master_password_set(self) -> bool:
        """是否已设置主密码"""
        return bool(self.security_config.master_password_hash)

    def get_sensitive_fields(self) -> list:
        """获取敏感字段列表"""
        return [
            "imap_config.password",
            "tempmail_config.epin"
        ]

    def __str__(self) -> str:
        """字符串表示"""
        return f"ConfigModel(domain={self.get_domain()}, method={self.get_verification_method()})"
