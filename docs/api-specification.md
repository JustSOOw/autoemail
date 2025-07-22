# 域名邮箱管理器 - 内部API接口规范

## 📋 API概述

本文档定义了域名邮箱管理器内部各模块间的API接口规范，确保模块间的标准化通信和数据交换。

## 🔧 核心服务API

### 1. EmailService API

#### 1.1 邮箱管理接口

```python
class EmailService:
    
    def create_email(
        self, 
        prefix_type: str = "random_name",
        custom_prefix: Optional[str] = None,
        tags: Optional[List[str]] = None,
        notes: str = ""
    ) -> EmailModel:
        """
        创建新邮箱并持久化到数据库
        
        Args:
            prefix_type: 前缀类型 ("random_name", "timestamp", "custom")
            custom_prefix: 自定义前缀 (当 prefix_type 为 "custom" 时使用)
            tags: 关联的标签列表
            notes: 备注信息
            
        Returns:
            EmailModel: 创建并保存后的邮箱数据模型实例
            
        Raises:
            ValueError: 如果域名未配置
            Exception: 如果数据库保存失败
        """
        pass

    def get_email_by_id(self, email_id: int) -> Optional[EmailModel]:
        """
        根据ID获取单个邮箱记录
        
        Args:
            email_id: 邮箱的数据库ID
            
        Returns:
            Optional[EmailModel]: 找到的邮箱模型实例，否则返回None
        """
        pass

    def search_emails(
        self, 
        keyword: str = "",
        status: Optional[EmailStatus] = None,
        tags: Optional[List[str]] = None,
        limit: int = 100
    ) -> List[EmailModel]:
        """
        根据条件搜索邮箱记录
        
        Args:
            keyword: 在邮箱地址和备注中搜索的关键词
            status: 邮箱状态 (EmailStatus.ACTIVE, etc.)
            tags: 必须包含的标签名称列表
            limit: 返回的最大记录数
            
        Returns:
            List[EmailModel]: 符合条件的邮箱模型实例列表
        """
        pass

    def update_email(self, email_model: EmailModel) -> bool:
        """
        更新一个已存在的邮箱记录
        
        Args:
            email_model: 包含更新后数据的邮箱模型实例 (ID必须有效)
            
        Returns:
            bool: 更新是否成功
        """
        pass

    def delete_email(self, email_id: int) -> bool:
        """
        软删除一个邮箱记录 (将其is_active设为False)
        
        Args:
            email_id: 要删除的邮箱的数据库ID
            
        Returns:
            bool: 删除是否成功
        """
        pass
```

#### 1.2 数据模型定义

```python
from dataclasses import dataclass
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class EmailStatus(Enum):
    """邮箱状态枚举"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    ARCHIVED = "archived"

@dataclass
class EmailModel:
    """邮箱核心数据模型"""
    id: Optional[int] = None
    email_address: str = ""
    domain: str = ""
    created_at: Optional[datetime] = None
    status: EmailStatus = EmailStatus.ACTIVE
    tags: List[str] = field(default_factory=list)
    notes: str = ""
    is_active: bool = True
```

### 2. ConfigService API

#### 2.1 配置管理接口

```python
class ConfigService:
    
    def load_config(self, master_password: Optional[str] = None) -> ConfigModel:
        """
        从数据库加载完整的应用程序配置
        
        Args:
            master_password: 主密码，用于解密配置中的敏感数据
            
        Returns:
            ConfigModel: 包含所有配置的完整数据模型实例
        """
        pass
        
    def save_config(self, config: ConfigModel, master_password: Optional[str] = None) -> bool:
        """
        将完整的配置模型保存到数据库
        
        Args:
            config: 包含所有配置的数据模型实例
            master_password: 主密码，用于加密配置中的敏感数据
            
        Returns:
            bool: 保存是否成功
        """
        pass

    def export_config(self, include_sensitive: bool = False) -> str:
        """
        将当前配置导出为JSON字符串

        Args:
            include_sensitive: 是否在导出的JSON中包含密码等敏感信息

        Returns:
            str: 代表配置的JSON字符串
        """
        pass

    def import_config(self, config_json: str, master_password: Optional[str] = None) -> bool:
        """
        从JSON字符串导入配置并保存

        Args:
            config_json: 代表配置的JSON字符串
            master_password: 主密码，用于处理导入配置中的敏感数据

        Returns:
            bool: 导入和保存是否成功
        """
        pass
```

#### 2.2 配置数据模型

```python
@dataclass
class DomainConfig:
    """域名配置"""
    domain: str = ""

@dataclass
class SecurityConfig:
    """安全配置"""
    encrypt_sensitive_data: bool = True
    auto_lock_minutes: int = 30

@dataclass
class SystemConfig:
    """系统配置"""
    ui_theme: str = "default"
    language: str = "zh_CN"

@dataclass
class ConfigModel:
    """应用程序所有配置的统一数据模型"""
    domain_config: DomainConfig = field(default_factory=DomainConfig)
    security_config: SecurityConfig = field(default_factory=SecurityConfig)
    system_config: SystemConfig = field(default_factory=SystemConfig)
```

## 🚨 核心异常

```python
class EmailManagerException(Exception):
    """应用程序的基础异常类"""
    pass

class DatabaseError(EmailManagerException):
    """数据库操作相关的错误"""
    pass

class ConfigurationError(EmailManagerException):
    """配置加载或保存时发生的错误"""
    pass
```
