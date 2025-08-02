# 域名邮箱管理器 - 后端API接口规范

## 📋 API概述

本文档定义了域名邮箱管理器后端服务的完整API接口规范，包含Phase 3A新增的高级功能，为前端开发提供详细的接口说明。

**版本**: Phase 3A
**更新时间**: 2025年1月23日
**状态**: ✅ 已完成并测试通过

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

    # ==================== Phase 3A: 高级搜索和筛选功能 ====================

    def advanced_search_emails(
        self,
        keyword: str = "",
        domain: str = "",
        status: Optional[EmailStatus] = None,
        tags: Optional[List[str]] = None,
        date_from: Optional[str] = None,
        date_to: Optional[str] = None,
        created_by: str = "",
        has_notes: Optional[bool] = None,
        page: int = 1,
        page_size: int = 20,
        sort_by: str = "created_at",
        sort_order: str = "desc"
    ) -> Dict[str, Any]:
        """
        高级搜索邮箱（支持分页和多条件筛选）

        Args:
            keyword: 搜索关键词（邮箱地址、备注）
            domain: 域名筛选
            status: 状态筛选
            tags: 标签筛选（包含任一标签）
            date_from: 开始日期 (YYYY-MM-DD)
            date_to: 结束日期 (YYYY-MM-DD)
            created_by: 创建者筛选
            has_notes: 是否有备注
            page: 页码（从1开始）
            page_size: 每页大小
            sort_by: 排序字段 ("created_at", "email_address", "domain", "status")
            sort_order: 排序方向 ("asc", "desc")

        Returns:
            Dict[str, Any]: {
                "emails": List[EmailModel],
                "pagination": {
                    "current_page": int,
                    "page_size": int,
                    "total_items": int,
                    "total_pages": int,
                    "has_next": bool,
                    "has_prev": bool
                },
                "filters": Dict[str, Any]
            }
        """
        pass

    def get_emails_by_multiple_tags(
        self,
        tag_names: List[str],
        match_all: bool = True,
        limit: int = 100
    ) -> List[EmailModel]:
        """
        根据多个标签获取邮箱

        Args:
            tag_names: 标签名称列表
            match_all: True=必须包含所有标签，False=包含任一标签
            limit: 限制数量

        Returns:
            List[EmailModel]: 邮箱模型列表
        """
        pass

    def get_emails_by_date_range(
        self,
        start_date: str,
        end_date: str,
        date_field: str = "created_at",
        limit: int = 100
    ) -> List[EmailModel]:
        """
        根据日期范围获取邮箱

        Args:
            start_date: 开始日期 (YYYY-MM-DD)
            end_date: 结束日期 (YYYY-MM-DD)
            date_field: 日期字段 ("created_at", "last_used", "updated_at")
            limit: 限制数量

        Returns:
            List[EmailModel]: 邮箱模型列表
        """
        pass

    def get_email_statistics_by_period(
        self,
        period: str = "month",
        limit: int = 12
    ) -> List[Dict[str, Any]]:
        """
        获取按时间段的邮箱统计

        Args:
            period: 时间段 ("day", "week", "month", "year")
            limit: 限制数量

        Returns:
            List[Dict[str, Any]]: 统计数据列表
        """
        pass

    def export_emails_advanced(
        self,
        format_type: str = "json",
        filters: Optional[Dict[str, Any]] = None,
        fields: Optional[List[str]] = None,
        include_tags: bool = True,
        include_metadata: bool = False
    ) -> str:
        """
        高级邮箱数据导出

        Args:
            format_type: 导出格式 ("json", "csv", "xlsx")
            filters: 过滤条件
            fields: 要导出的字段列表
            include_tags: 是否包含标签信息
            include_metadata: 是否包含元数据

        Returns:
            str: 导出的数据字符串
        """
        pass


### 3. TagService API

#### 3.1 标签管理接口

```python
class TagService:

    def create_tag(
        self,
        name: str,
        description: str = "",
        color: str = "#3498db",
        icon: str = "🏷️"
    ) -> Optional[TagModel]:
        """
        创建新标签

        Args:
            name: 标签名称（必须唯一）
            description: 标签描述
            color: 标签颜色（十六进制）
            icon: 标签图标

        Returns:
            Optional[TagModel]: 创建成功返回标签模型，失败返回None
        """
        pass

    def get_tag_by_id(self, tag_id: int) -> Optional[TagModel]:
        """
        根据ID获取标签

        Args:
            tag_id: 标签ID

        Returns:
            Optional[TagModel]: 标签模型或None
        """
        pass

    def get_all_tags(self) -> List[TagModel]:
        """
        获取所有活跃标签

        Returns:
            List[TagModel]: 标签列表
        """
        pass

    def update_tag(self, tag_model: TagModel) -> bool:
        """
        更新标签信息

        Args:
            tag_model: 包含更新数据的标签模型

        Returns:
            bool: 更新是否成功
        """
        pass

    def delete_tag(self, tag_id: int) -> bool:
        """
        删除标签（软删除）

        Args:
            tag_id: 标签ID

        Returns:
            bool: 删除是否成功
        """
        pass

    def get_tag_statistics(self) -> Dict[str, Any]:
        """
        获取标签统计信息

        Returns:
            Dict[str, Any]: 统计信息
        """
        pass

    # ==================== Phase 3A: 高级标签功能 ====================

    def add_tag_to_email(self, email_id: int, tag_id: int) -> bool:
        """
        为邮箱添加标签

        Args:
            email_id: 邮箱ID
            tag_id: 标签ID

        Returns:
            bool: 是否添加成功
        """
        pass

    def remove_tag_from_email(self, email_id: int, tag_id: int) -> bool:
        """
        从邮箱移除标签

        Args:
            email_id: 邮箱ID
            tag_id: 标签ID

        Returns:
            bool: 是否移除成功
        """
        pass

    def batch_add_tags_to_email(self, email_id: int, tag_ids: List[int]) -> Dict[str, Any]:
        """
        批量为邮箱添加标签

        Args:
            email_id: 邮箱ID
            tag_ids: 标签ID列表

        Returns:
            Dict[str, Any]: 操作结果统计
        """
        pass

    def batch_remove_tags_from_email(self, email_id: int, tag_ids: List[int]) -> Dict[str, Any]:
        """
        批量从邮箱移除标签

        Args:
            email_id: 邮箱ID
            tag_ids: 标签ID列表

        Returns:
            Dict[str, Any]: 操作结果统计
        """
        pass

    def replace_email_tags(self, email_id: int, new_tag_ids: List[int]) -> bool:
        """
        替换邮箱的所有标签

        Args:
            email_id: 邮箱ID
            new_tag_ids: 新的标签ID列表

        Returns:
            bool: 是否替换成功
        """
        pass

    def get_tag_usage_details(self, tag_id: int) -> Dict[str, Any]:
        """
        获取标签使用详情

        Args:
            tag_id: 标签ID

        Returns:
            Dict[str, Any]: 标签使用详情
        """
        pass

    def get_tags_with_pagination(
        self,
        page: int = 1,
        page_size: int = 20,
        keyword: str = "",
        sort_by: str = "name",
        sort_order: str = "asc"
    ) -> Dict[str, Any]:
        """
        分页获取标签列表

        Args:
            page: 页码（从1开始）
            page_size: 每页大小
            keyword: 搜索关键词
            sort_by: 排序字段 ("name", "created_at", "usage_count")
            sort_order: 排序方向 ("asc", "desc")

        Returns:
            Dict[str, Any]: 分页结果
        """
        pass

    def export_tags(self, format_type: str = "json", include_usage: bool = False) -> str:
        """
        导出标签数据

        Args:
            format_type: 导出格式 ("json" 或 "csv")
            include_usage: 是否包含使用统计

        Returns:
            str: 导出的数据字符串
        """
        pass

    def merge_tags(self, source_tag_id: int, target_tag_id: int, delete_source: bool = True) -> bool:
        """
        合并标签（将源标签的所有关联转移到目标标签）

        Args:
            source_tag_id: 源标签ID
            target_tag_id: 目标标签ID
            delete_source: 是否删除源标签

        Returns:
            bool: 是否合并成功
        """
        pass
```

### 4. BatchService API

#### 4.1 批量操作接口

```python
class BatchService:

    def batch_create_emails(
        self,
        count: int,
        prefix_type: str = "random_name",
        base_prefix: str = "",
        tags: Optional[List[str]] = None,
        notes: str = "",
        created_by: str = "batch_system"
    ) -> Dict[str, Any]:
        """
        批量创建邮箱

        Args:
            count: 创建数量
            prefix_type: 前缀类型 ("random_name", "sequence", "timestamp", "custom")
            base_prefix: 基础前缀（用于sequence和custom类型）
            tags: 标签列表
            notes: 备注信息
            created_by: 创建者

        Returns:
            Dict[str, Any]: {
                "total": int,
                "success": int,
                "failed": int,
                "emails": List[EmailModel],
                "errors": List[str]
            }
        """
        pass

    def batch_update_emails(
        self,
        email_ids: List[int],
        updates: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        批量更新邮箱

        Args:
            email_ids: 邮箱ID列表
            updates: 更新字段字典

        Returns:
            Dict[str, Any]: 批量更新结果
        """
        pass

    def batch_delete_emails(self, email_ids: List[int], hard_delete: bool = False) -> Dict[str, Any]:
        """
        批量删除邮箱

        Args:
            email_ids: 邮箱ID列表
            hard_delete: 是否硬删除（物理删除）

        Returns:
            Dict[str, Any]: 批量删除结果
        """
        pass

    def batch_apply_tags(
        self,
        email_ids: List[int],
        tag_names: List[str],
        operation: str = "add"
    ) -> Dict[str, Any]:
        """
        批量应用标签操作

        Args:
            email_ids: 邮箱ID列表
            tag_names: 标签名称列表
            operation: 操作类型 ("add", "remove", "replace")

        Returns:
            Dict[str, Any]: 批量操作结果
        """
        pass

    def batch_create_tags(self, tag_data_list: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        批量创建标签

        Args:
            tag_data_list: 标签数据列表，每个元素包含name, description, color, icon

        Returns:
            Dict[str, Any]: 批量创建结果
        """
        pass

    def batch_import_emails_from_data(
        self,
        import_data: List[Dict[str, Any]],
        conflict_strategy: str = "skip"
    ) -> Dict[str, Any]:
        """
        从数据批量导入邮箱

        Args:
            import_data: 导入数据列表
            conflict_strategy: 冲突处理策略 ("skip", "update", "error")

        Returns:
            Dict[str, Any]: 批量导入结果
        """
        pass
```

### 5. ExportService API

#### 5.1 数据导出接口

```python
class ExportService:

    def export_all_data(
        self,
        format_type: str = "json",
        output_path: Optional[str] = None,
        include_deleted: bool = False
    ) -> Union[str, bytes]:
        """
        导出所有数据（邮箱、标签、配置等）

        Args:
            format_type: 导出格式 ("json", "csv", "xlsx")
            output_path: 输出文件路径（可选）
            include_deleted: 是否包含已删除的数据

        Returns:
            Union[str, bytes]: 导出的数据内容
        """
        pass

    def export_emails_with_template(
        self,
        template_name: str,
        filters: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        使用预定义模板导出邮箱数据

        Args:
            template_name: 模板名称 ("simple", "detailed", "report")
            filters: 过滤条件

        Returns:
            str: 导出的数据字符串
        """
        pass

    def set_services(self, email_service: EmailService, tag_service: TagService):
        """
        设置依赖的服务实例

        Args:
            email_service: 邮箱服务实例
            tag_service: 标签服务实例
        """
        pass
```
```

## 📊 数据模型定义

### 1. 核心数据模型

```python
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any, Union
from datetime import datetime
from enum import Enum

class EmailStatus(Enum):
    """邮箱状态枚举"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    ARCHIVED = "archived"

@dataclass
class EmailModel:
    """邮箱核心数据模型 - Phase 3A增强版"""
    id: Optional[int] = None
    email_address: str = ""
    domain: str = ""
    prefix: str = ""
    timestamp_suffix: str = ""
    created_at: Optional[datetime] = None
    last_used: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    status: EmailStatus = EmailStatus.ACTIVE
    tags: List[str] = field(default_factory=list)
    notes: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    is_active: bool = True
    created_by: str = "system"

@dataclass
class TagModel:
    """标签数据模型"""
    id: Optional[int] = None
    name: str = ""
    description: str = ""
    color: str = "#3498db"
    icon: str = "🏷️"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    is_system: bool = False
    is_active: bool = True
    usage_count: int = 0  # Phase 3A新增：使用统计

# Phase 3A新增：分页响应模型
@dataclass
class PaginationInfo:
    """分页信息模型"""
    current_page: int = 1
    page_size: int = 20
    total_items: int = 0
    total_pages: int = 0
    has_next: bool = False
    has_prev: bool = False

@dataclass
class SearchResponse:
    """搜索响应模型"""
    emails: List[EmailModel] = field(default_factory=list)
    pagination: PaginationInfo = field(default_factory=PaginationInfo)
    filters: Dict[str, Any] = field(default_factory=dict)

@dataclass
class BatchOperationResult:
    """批量操作结果模型"""
    total: int = 0
    success: int = 0
    failed: int = 0
    skipped: int = 0
    updated: int = 0
    emails: List[EmailModel] = field(default_factory=list)
    tags: List[TagModel] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
```

## 🔧 核心服务API

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

## 🔒 安全功能API (Phase 3A)

### 1. 加密管理

```python
class EncryptionManager:

    def __init__(self, password: str):
        """
        初始化加密管理器

        Args:
            password: 主密码
        """
        pass

    def encrypt(self, data: str) -> str:
        """
        加密数据

        Args:
            data: 要加密的数据

        Returns:
            str: 加密后的数据
        """
        pass

    def decrypt(self, encrypted_data: str) -> str:
        """
        解密数据

        Args:
            encrypted_data: 加密的数据

        Returns:
            str: 解密后的数据
        """
        pass

    def is_encrypted(self, data: str) -> bool:
        """
        检查数据是否已加密

        Args:
            data: 要检查的数据

        Returns:
            bool: 是否已加密
        """
        pass
```

### 2. 日志脱敏

```python
class LogSanitizer:

    def sanitize_log_message(self, message: str) -> str:
        """
        脱敏日志消息

        Args:
            message: 原始日志消息

        Returns:
            str: 脱敏后的日志消息
        """
        pass

    def sanitize_dict(self, data: dict) -> dict:
        """
        脱敏字典数据

        Args:
            data: 原始字典

        Returns:
            dict: 脱敏后的字典
        """
        pass
```

### 3. 安全配置管理

```python
class SecureConfigManager:

    def encrypt_config_section(self, config_data: dict, section_name: str) -> dict:
        """
        加密配置段

        Args:
            config_data: 配置数据
            section_name: 配置段名称

        Returns:
            dict: 加密后的配置数据
        """
        pass

    def decrypt_config_section(self, config_data: dict, section_name: str) -> dict:
        """
        解密配置段

        Args:
            config_data: 配置数据
            section_name: 配置段名称

        Returns:
            dict: 解密后的配置数据
        """
        pass

    def secure_log_config(self, config_data: dict) -> dict:
        """
        安全记录配置（脱敏）

        Args:
            config_data: 配置数据

        Returns:
            dict: 脱敏后的配置数据
        """
        pass
```

## 📝 API使用示例

### 1. 邮箱管理示例

```python
# 初始化服务
email_service = EmailService(config, db_service)

# 创建邮箱
email = email_service.create_email(
    prefix_type="custom",
    custom_prefix="test_user",
    tags=["开发", "测试"],
    notes="测试邮箱"
)

# 高级搜索
search_result = email_service.advanced_search_emails(
    keyword="test",
    tags=["开发"],
    page=1,
    page_size=10,
    sort_by="created_at",
    sort_order="desc"
)

# 获取搜索结果
emails = search_result["emails"]
pagination = search_result["pagination"]
```

### 2. 标签管理示例

```python
# 初始化标签服务
tag_service = TagService(db_service)

# 创建标签
tag = tag_service.create_tag(
    name="开发环境",
    description="开发环境相关邮箱",
    color="#3498db",
    icon="💻"
)

# 为邮箱添加标签
success = tag_service.add_tag_to_email(email.id, tag.id)

# 分页获取标签
tag_result = tag_service.get_tags_with_pagination(
    page=1,
    page_size=20,
    keyword="开发",
    sort_by="usage_count",
    sort_order="desc"
)
```

### 3. 批量操作示例

```python
# 初始化批量服务
batch_service = BatchService(db_service, config)

# 批量创建邮箱
result = batch_service.batch_create_emails(
    count=10,
    prefix_type="sequence",
    base_prefix="batch_test",
    tags=["批量测试"],
    notes="批量创建的邮箱"
)

# 批量应用标签
tag_result = batch_service.batch_apply_tags(
    email_ids=[1, 2, 3, 4, 5],
    tag_names=["生产环境", "重要"],
    operation="add"
)
```

### 4. 数据导出示例

```python
# 初始化导出服务
export_service = ExportService(db_service)
export_service.set_services(email_service, tag_service)

# 导出所有数据
json_data = export_service.export_all_data("json")

# 使用模板导出
report_data = export_service.export_emails_with_template(
    "report",
    filters={"tags": ["生产环境"]}
)

# 高级邮箱导出
csv_data = email_service.export_emails_advanced(
    format_type="csv",
    fields=["id", "email_address", "domain", "status"],
    include_tags=True
)
```

### 5. 安全功能示例

```python
# 加密管理
encryption_manager = EncryptionManager("master_password")
encrypted_data = encryption_manager.encrypt("sensitive_data")
decrypted_data = encryption_manager.decrypt(encrypted_data)

# 日志脱敏
sanitizer = LogSanitizer()
safe_message = sanitizer.sanitize_log_message("password=secret123")

# 便捷脱敏函数
from utils.encryption import sanitize_for_log
safe_log = sanitize_for_log({"password": "secret", "username": "test"})
```

## 🚀 前端集成建议

### 1. API调用封装

建议前端创建API调用封装类，统一处理：
- 请求/响应格式化
- 错误处理
- 分页数据处理
- 加载状态管理

### 2. 数据状态管理

建议使用状态管理库（如Vuex/Pinia）管理：
- 邮箱列表数据
- 标签数据
- 搜索筛选状态
- 分页状态

### 3. 组件设计

建议创建以下核心组件：
- `EmailList` - 邮箱列表组件
- `EmailSearch` - 搜索筛选组件
- `TagManager` - 标签管理组件
- `BatchOperations` - 批量操作组件
- `DataExport` - 数据导出组件

### 4. 性能优化

- 使用虚拟滚动处理大量数据
- 实现搜索防抖
- 缓存常用数据
- 分页加载数据

---

**API文档版本**: Phase 3A
**最后更新**: 2025年1月23日
**状态**: ✅ 已完成并测试通过
