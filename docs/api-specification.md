# 域名邮箱管理器 - 内部API接口规范

## 📋 API概述

本文档定义了域名邮箱管理器内部各模块间的API接口规范，确保模块间的标准化通信和数据交换。

## 🔧 核心服务API

### 1. EmailService API

#### 1.1 邮箱生成接口

```python
class EmailService:
    
    async def generate_email_address(
        self, 
        domain: str, 
        prefix_length: int = 4,
        name_type: str = "random"
    ) -> EmailGenerationResult:
        """
        生成邮箱地址
        
        Args:
            domain: 域名
            prefix_length: 时间戳长度
            name_type: 名字类型 ("random", "custom")
            
        Returns:
            EmailGenerationResult: 生成结果
            
        Raises:
            InvalidDomainError: 域名无效
            GenerationError: 生成失败
        """
        pass
        
    async def get_verification_code(
        self,
        email_address: str,
        method: str = "auto",
        timeout: int = 300
    ) -> VerificationResult:
        """
        获取验证码
        
        Args:
            email_address: 邮箱地址
            method: 获取方式 ("auto", "tempmail", "imap", "pop3")
            timeout: 超时时间（秒）
            
        Returns:
            VerificationResult: 验证码获取结果
            
        Raises:
            EmailNotFoundError: 邮箱不存在
            TimeoutError: 获取超时
            AuthenticationError: 认证失败
        """
        pass
        
    def validate_email_format(self, email: str) -> ValidationResult:
        """
        验证邮箱格式
        
        Args:
            email: 邮箱地址
            
        Returns:
            ValidationResult: 验证结果
        """
        pass
```

#### 1.2 数据模型定义

```python
from dataclasses import dataclass
from typing import Optional, Dict, Any
from datetime import datetime

@dataclass
class EmailGenerationResult:
    """邮箱生成结果"""
    success: bool
    email_address: Optional[str] = None
    domain: Optional[str] = None
    generated_at: Optional[datetime] = None
    error_message: Optional[str] = None
    metadata: Dict[str, Any] = None

@dataclass
class VerificationResult:
    """验证码获取结果"""
    success: bool
    verification_code: Optional[str] = None
    method_used: Optional[str] = None
    retrieved_at: Optional[datetime] = None
    error_message: Optional[str] = None
    retry_count: int = 0

@dataclass
class ValidationResult:
    """验证结果"""
    is_valid: bool
    error_type: Optional[str] = None
    error_message: Optional[str] = None
    suggestions: list = None
```

### 2. ConfigService API

#### 2.1 配置管理接口

```python
class ConfigService:
    
    def load_config(self, config_type: str = "all") -> ConfigResult:
        """
        加载配置
        
        Args:
            config_type: 配置类型 ("all", "domain", "imap", "tempmail", "security")
            
        Returns:
            ConfigResult: 配置加载结果
        """
        pass
        
    def save_config(self, config_data: Dict[str, Any]) -> SaveResult:
        """
        保存配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            SaveResult: 保存结果
        """
        pass
        
    def validate_config(self, config_data: Dict[str, Any]) -> ValidationResult:
        """
        验证配置
        
        Args:
            config_data: 待验证的配置数据
            
        Returns:
            ValidationResult: 验证结果
        """
        pass
        
    async def test_connection(
        self, 
        config_type: str, 
        config_data: Dict[str, Any]
    ) -> ConnectionTestResult:
        """
        测试连接
        
        Args:
            config_type: 配置类型 ("imap", "tempmail")
            config_data: 连接配置
            
        Returns:
            ConnectionTestResult: 连接测试结果
        """
        pass
```

#### 2.2 配置数据模型

```python
@dataclass
class ConfigResult:
    """配置加载结果"""
    success: bool
    config_data: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None
    loaded_sections: list = None

@dataclass
class SaveResult:
    """保存结果"""
    success: bool
    saved_at: Optional[datetime] = None
    error_message: Optional[str] = None
    backup_created: bool = False

@dataclass
class ConnectionTestResult:
    """连接测试结果"""
    success: bool
    connection_type: str
    response_time: Optional[float] = None
    error_message: Optional[str] = None
    server_info: Optional[Dict[str, Any]] = None
```

### 3. DatabaseService API

#### 3.1 邮箱记录管理

```python
class DatabaseService:
    
    def create_email_record(self, email_data: EmailModel) -> CreateResult:
        """
        创建邮箱记录
        
        Args:
            email_data: 邮箱数据模型
            
        Returns:
            CreateResult: 创建结果
        """
        pass
        
    def get_email_records(
        self, 
        filters: Optional[Dict[str, Any]] = None,
        page: int = 1,
        page_size: int = 50
    ) -> QueryResult:
        """
        获取邮箱记录
        
        Args:
            filters: 筛选条件
            page: 页码
            page_size: 每页大小
            
        Returns:
            QueryResult: 查询结果
        """
        pass
        
    def update_email_record(
        self, 
        email_id: int, 
        update_data: Dict[str, Any]
    ) -> UpdateResult:
        """
        更新邮箱记录
        
        Args:
            email_id: 邮箱ID
            update_data: 更新数据
            
        Returns:
            UpdateResult: 更新结果
        """
        pass
        
    def delete_email_record(self, email_id: int) -> DeleteResult:
        """
        删除邮箱记录
        
        Args:
            email_id: 邮箱ID
            
        Returns:
            DeleteResult: 删除结果
        """
        pass
        
    def search_emails(
        self, 
        query: str, 
        search_fields: list = None
    ) -> SearchResult:
        """
        搜索邮箱
        
        Args:
            query: 搜索关键词
            search_fields: 搜索字段列表
            
        Returns:
            SearchResult: 搜索结果
        """
        pass
```

#### 3.2 标签管理

```python
class DatabaseService:
    
    def create_tag(self, tag_data: TagModel) -> CreateResult:
        """创建标签"""
        pass
        
    def get_tags(self) -> QueryResult:
        """获取所有标签"""
        pass
        
    def update_tag(self, tag_id: int, update_data: Dict[str, Any]) -> UpdateResult:
        """更新标签"""
        pass
        
    def delete_tag(self, tag_id: int) -> DeleteResult:
        """删除标签"""
        pass
        
    def associate_email_tag(self, email_id: int, tag_id: int) -> AssociationResult:
        """关联邮箱和标签"""
        pass
        
    def dissociate_email_tag(self, email_id: int, tag_id: int) -> AssociationResult:
        """取消关联邮箱和标签"""
        pass
        
    def get_email_tags(self, email_id: int) -> QueryResult:
        """获取邮箱的所有标签"""
        pass
```

#### 3.3 数据库操作结果模型

```python
@dataclass
class CreateResult:
    """创建结果"""
    success: bool
    created_id: Optional[int] = None
    error_message: Optional[str] = None
    created_at: Optional[datetime] = None

@dataclass
class QueryResult:
    """查询结果"""
    success: bool
    data: list = None
    total_count: int = 0
    page: int = 1
    page_size: int = 50
    error_message: Optional[str] = None

@dataclass
class UpdateResult:
    """更新结果"""
    success: bool
    affected_rows: int = 0
    error_message: Optional[str] = None
    updated_at: Optional[datetime] = None

@dataclass
class DeleteResult:
    """删除结果"""
    success: bool
    deleted_count: int = 0
    error_message: Optional[str] = None

@dataclass
class SearchResult:
    """搜索结果"""
    success: bool
    results: list = None
    total_matches: int = 0
    search_time: Optional[float] = None
    error_message: Optional[str] = None

@dataclass
class AssociationResult:
    """关联操作结果"""
    success: bool
    email_id: Optional[int] = None
    tag_id: Optional[int] = None
    error_message: Optional[str] = None
```

### 4. ValidationService API

#### 4.1 验证接口

```python
class ValidationService:
    
    def validate_domain(self, domain: str) -> DomainValidationResult:
        """
        验证域名
        
        Args:
            domain: 域名
            
        Returns:
            DomainValidationResult: 域名验证结果
        """
        pass
        
    def validate_imap_config(self, config: Dict[str, Any]) -> IMAPValidationResult:
        """
        验证IMAP配置
        
        Args:
            config: IMAP配置
            
        Returns:
            IMAPValidationResult: IMAP验证结果
        """
        pass
        
    def validate_tempmail_config(self, config: Dict[str, Any]) -> TempMailValidationResult:
        """
        验证tempmail配置
        
        Args:
            config: tempmail配置
            
        Returns:
            TempMailValidationResult: tempmail验证结果
        """
        pass
```

#### 4.2 验证结果模型

```python
@dataclass
class DomainValidationResult:
    """域名验证结果"""
    is_valid: bool
    domain: str
    has_mx_record: bool = False
    has_cloudflare_dns: bool = False
    error_message: Optional[str] = None
    suggestions: list = None

@dataclass
class IMAPValidationResult:
    """IMAP验证结果"""
    is_valid: bool
    can_connect: bool = False
    can_authenticate: bool = False
    server_capabilities: list = None
    error_message: Optional[str] = None

@dataclass
class TempMailValidationResult:
    """TempMail验证结果"""
    is_valid: bool
    api_accessible: bool = False
    account_valid: bool = False
    error_message: Optional[str] = None
```

## 🎯 Controller层API

### 1. EmailController API

```python
class EmailController:
    
    async def handle_email_generation(
        self, 
        generation_request: EmailGenerationRequest
    ) -> EmailGenerationResponse:
        """
        处理邮箱生成请求
        
        Args:
            generation_request: 生成请求
            
        Returns:
            EmailGenerationResponse: 生成响应
        """
        pass
        
    async def handle_verification_request(
        self,
        verification_request: VerificationRequest
    ) -> VerificationResponse:
        """
        处理验证码获取请求
        
        Args:
            verification_request: 验证请求
            
        Returns:
            VerificationResponse: 验证响应
        """
        pass
        
    def handle_email_list_request(
        self,
        list_request: EmailListRequest
    ) -> EmailListResponse:
        """
        处理邮箱列表请求
        
        Args:
            list_request: 列表请求
            
        Returns:
            EmailListResponse: 列表响应
        """
        pass
```

### 2. 请求响应模型

```python
@dataclass
class EmailGenerationRequest:
    """邮箱生成请求"""
    domain: str
    prefix_length: int = 4
    name_type: str = "random"
    custom_prefix: Optional[str] = None
    tags: list = None

@dataclass
class EmailGenerationResponse:
    """邮箱生成响应"""
    success: bool
    email_record: Optional[EmailModel] = None
    error_message: Optional[str] = None
    generation_time: Optional[float] = None

@dataclass
class VerificationRequest:
    """验证码获取请求"""
    email_address: str
    method: str = "auto"
    timeout: int = 300

@dataclass
class VerificationResponse:
    """验证码获取响应"""
    success: bool
    verification_code: Optional[str] = None
    method_used: Optional[str] = None
    error_message: Optional[str] = None

@dataclass
class EmailListRequest:
    """邮箱列表请求"""
    filters: Optional[Dict[str, Any]] = None
    sort_by: str = "created_at"
    sort_order: str = "desc"
    page: int = 1
    page_size: int = 50

@dataclass
class EmailListResponse:
    """邮箱列表响应"""
    success: bool
    emails: list = None
    total_count: int = 0
    page_info: Dict[str, Any] = None
    error_message: Optional[str] = None
```

## 🔄 事件系统API

### 1. 事件定义

```python
from enum import Enum
from dataclasses import dataclass
from typing import Any, Dict

class EventType(Enum):
    """事件类型枚举"""
    EMAIL_GENERATED = "email_generated"
    VERIFICATION_CODE_RECEIVED = "verification_code_received"
    CONFIG_UPDATED = "config_updated"
    TAG_CREATED = "tag_created"
    EMAIL_DELETED = "email_deleted"
    ERROR_OCCURRED = "error_occurred"

@dataclass
class Event:
    """事件基类"""
    event_type: EventType
    timestamp: datetime
    data: Dict[str, Any]
    source: str
```

### 2. 事件处理器

```python
class EventHandler:
    """事件处理器接口"""
    
    def handle_event(self, event: Event) -> None:
        """处理事件"""
        pass

class EventBus:
    """事件总线"""
    
    def subscribe(self, event_type: EventType, handler: EventHandler) -> None:
        """订阅事件"""
        pass
        
    def unsubscribe(self, event_type: EventType, handler: EventHandler) -> None:
        """取消订阅"""
        pass
        
    def publish(self, event: Event) -> None:
        """发布事件"""
        pass
```

## 🚨 异常处理API

### 1. 自定义异常

```python
class EmailManagerException(Exception):
    """邮箱管理器基础异常"""
    pass

class InvalidDomainError(EmailManagerException):
    """无效域名异常"""
    pass

class GenerationError(EmailManagerException):
    """生成失败异常"""
    pass

class EmailNotFoundError(EmailManagerException):
    """邮箱未找到异常"""
    pass

class AuthenticationError(EmailManagerException):
    """认证失败异常"""
    pass

class ConfigurationError(EmailManagerException):
    """配置错误异常"""
    pass

class DatabaseError(EmailManagerException):
    """数据库错误异常"""
    pass
```

### 2. 错误处理器

```python
class ErrorHandler:
    """错误处理器"""
    
    def handle_error(self, error: Exception, context: Dict[str, Any]) -> ErrorResponse:
        """
        处理错误
        
        Args:
            error: 异常对象
            context: 错误上下文
            
        Returns:
            ErrorResponse: 错误响应
        """
        pass

@dataclass
class ErrorResponse:
    """错误响应"""
    error_code: str
    error_message: str
    error_type: str
    context: Dict[str, Any]
    timestamp: datetime
    suggestions: list = None
```

## 📊 日志API

### 1. 日志接口

```python
class Logger:
    """日志记录器"""
    
    def debug(self, message: str, **kwargs) -> None:
        """调试日志"""
        pass
        
    def info(self, message: str, **kwargs) -> None:
        """信息日志"""
        pass
        
    def warning(self, message: str, **kwargs) -> None:
        """警告日志"""
        pass
        
    def error(self, message: str, error: Exception = None, **kwargs) -> None:
        """错误日志"""
        pass
        
    def critical(self, message: str, error: Exception = None, **kwargs) -> None:
        """严重错误日志"""
        pass
```

这个API规范确保了各模块间的标准化通信，为开发提供了清晰的接口定义。
