# 域名邮箱管理器 - 系统架构设计文档

## 🏗️ 架构概述

本项目采用经典的**MVC (Model-View-Controller)** 架构模式，结合**分层架构**设计，确保代码的可维护性、可扩展性和可测试性。

## 📐 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer (视图层)                │
├─────────────────────────────────────────────────────────────┤
│  MainWindow  │  EmailGenerationPage  │  EmailManagementPage │
│              │  ConfigurationPage    │  Common Components   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Controller Layer (控制层)                   │
├─────────────────────────────────────────────────────────────┤
│          EmailController     │     ConfigController         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Service Layer (服务层)                      │
├─────────────────────────────────────────────────────────────┤
│      EmailService      │     ConfigService      │ DatabaseService │
│                        │     LoggingService     │                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Model Layer (模型层)                       │
├─────────────────────────────────────────────────────────────┤
│        EmailModel        │      ConfigModel      │    TagModel    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Data Layer (数据层)                         │
├─────────────────────────────────────────────────────────────┤
│          SQLite Database          │      Configuration Files │
│          Encrypted Storage        │      Log Files           │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 核心设计原则

### 1. 单一职责原则 (SRP)
每个类和模块都有明确的单一职责：
- **EmailService**: 只负责邮箱生成和管理
- **ConfigService**: 只负责配置管理
- **DatabaseService**: 只负责数据持久化

### 2. 依赖倒置原则 (DIP)
高层模块不依赖低层模块，都依赖于抽象：
- 使用接口定义服务契约
- 通过依赖注入实现解耦

### 3. 开闭原则 (OCP)
对扩展开放，对修改关闭：
- 可扩展的导出格式支持
- 可自定义的生成规则

## 📦 详细模块设计

### 1. Presentation Layer (视图层)

**主要职责**: 用户界面展示和用户交互处理

#### 1.1 MainWindow (主窗口)
```python
class MainWindow(QMainWindow):
    """主应用程序窗口"""
    
    def __init__(self):
        # 初始化UI组件
        # 设置菜单栏、工具栏、状态栏
        # 创建标签页容器
        
    def setup_ui(self):
        # 创建三个主要页面
        # 设置布局和样式
        
    def handle_page_switch(self, index):
        # 处理页面切换逻辑
```

#### 1.2 EmailGenerationPage (邮箱申请页面)
```python
class EmailGenerationPage(QWidget):
    """邮箱生成页面"""
    
    # 信号定义
    email_generation_requested = pyqtSignal()
    
    def __init__(self, email_controller):
        self.email_controller = email_controller
        self.setup_ui()
        self.connect_signals()
        
    def setup_ui(self):
        # 左侧：配置信息展示
        # 中央：生成按钮和交互反馈
        
    def on_generate_email(self):
        # 触发邮箱生成请求
        
    def update_status(self, message):
        # 更新状态信息
```

#### 1.3 EmailManagementPage (邮箱管理页面)
```python
class EmailManagementPage(QWidget):
    """邮箱管理页面"""
    
    def __init__(self, email_controller):
        self.email_controller = email_controller
        self.email_table = EmailTableWidget()
        self.tag_panel = TagManagementPanel()
        self.setup_ui()
        
    def setup_ui(self):
        # 顶部：搜索和筛选工具栏
        # 中央：邮箱列表表格
        # 右侧：标签管理面板
        # 底部：操作按钮
        
    def refresh_email_list(self):
        # 刷新邮箱列表显示
        
    def handle_search(self, query):
        # 处理搜索请求
```

#### 1.4 ConfigurationPage (配置管理页面)
```python
class ConfigurationPage(QWidget):
    """配置管理页面"""
    
    def __init__(self, config_controller):
        self.config_controller = config_controller
        self.setup_ui()
        
    def setup_ui(self):
        # 域名配置组
        # 安全设置组
        # 系统设置组
        
    def save_config(self):
        # 保存配置更改
```

### 2. Controller Layer (控制层)

**主要职责**: 协调视图和模型，处理业务逻辑

#### 2.1 EmailController (邮箱控制器)
```python
class EmailController:
    """邮箱相关业务逻辑控制器"""
    
    def __init__(self, email_service):
        self.email_service = email_service
        
    def generate_email(self, config):
        """生成新邮箱"""
        # 调用邮箱服务生成并保存邮箱
        
    def get_email_list(self, filters=None):
        """获取邮箱列表"""
        # 从邮箱服务获取邮箱列表
        
    def search_emails(self, query):
        """搜索邮箱"""
        # 调用邮箱服务执行搜索逻辑
```

#### 2.2 ConfigController (配置控制器)
```python
class ConfigController:
    """配置管理控制器"""
    
    def __init__(self, config_service):
        self.config_service = config_service
        
    def load_config(self):
        """加载配置"""
        
    def save_config(self, config_data):
        """保存配置"""
```

### 3. Service Layer (服务层)

**主要职责**: 核心业务逻辑实现

#### 3.1 EmailService (邮箱服务)
```python
class EmailService:
    """邮箱生成和管理服务"""
    
    def __init__(self, config: ConfigModel, db_service: DatabaseService):
        self.config = config
        self.db_service = db_service
        self.email_generator = EmailGenerator(config)
        
    def create_email(
        self, 
        prefix_type: str = "random_name",
        custom_prefix: Optional[str] = None,
        tags: Optional[List[str]] = None,
        notes: str = ""
    ) -> EmailModel:
        """创建新邮箱并持久化到数据库"""
        pass
        
    def get_email_by_id(self, email_id: int) -> Optional[EmailModel]:
        """根据ID获取单个邮箱记录"""
        pass

    def search_emails(
        self, 
        keyword: str = "",
        status: Optional[EmailStatus] = None,
        tags: Optional[List[str]] = None,
        limit: int = 100
    ) -> List[EmailModel]:
        """根据条件搜索邮箱记录"""
        pass

    def update_email(self, email_model: EmailModel) -> bool:
        """更新一个已存在的邮箱记录"""
        pass

    def delete_email(self, email_id: int) -> bool:
        """软删除一个邮箱记录"""
        pass
```

#### 3.2 ConfigService (配置服务)
```python
class ConfigService:
    """配置管理服务"""
    
    def __init__(self, db_service: DatabaseService):
        self.db_service = db_service
        
    def load_config(self, master_password: Optional[str] = None) -> ConfigModel:
        """从数据库加载完整的应用程序配置"""
        pass
        
    def save_config(self, config: ConfigModel, master_password: Optional[str] = None) -> bool:
        """将完整的配置模型保存到数据库"""
        pass

    def export_config(self, include_sensitive: bool = False) -> str:
        """将当前配置导出为JSON字符串"""
        pass

    def import_config(self, config_json: str, master_password: Optional[str] = None) -> bool:
        """从JSON字符串导入配置并保存"""
        pass
```

#### 3.3 DatabaseService (数据库服务)
```python
class DatabaseService:
    """数据库操作服务"""
    
    def __init__(self, db_path="data/app.db"):
        self.db_path = db_path
        self.init_database()
        
    def init_database(self):
        """初始化数据库表结构"""
        
    def execute_query(self, query: str, params: tuple = (), fetch_one: bool = False) -> Optional[List[sqlite3.Row]]:
        """执行查询语句"""
        pass

    def execute_update(self, query: str, params: tuple = ()) -> int:
        """执行更新语句"""
        pass
```

### 4. Model Layer (模型层)

**主要职责**: 数据结构定义和业务规则

#### 4.1 数据模型定义
```python
from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional, Any, Dict
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
class ConfigModel:
    """应用程序所有配置的统一数据模型"""
    domain_config: dict = field(default_factory=dict)
    security_config: dict = field(default_factory=dict)
    system_config: dict = field(default_factory=dict)

@dataclass
class TagModel:
    """标签数据模型"""
    id: Optional[int] = None
    name: str = ""
    color: str = "#3498db"
    icon: str = ""
    description: str = ""
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    is_system: bool = False
    sort_order: int = 0
    usage_count: int = 0
```

## 🔐 安全架构设计

### 1. 数据加密
- 敏感配置数据（如主密码哈希）加密存储
- 内存中敏感数据及时清理

### 2. 敏感数据保护
- 日志文件脱敏处理

### 3. 配置文件安全
- 配置文件权限控制
- 敏感配置项加密
- 配置文件完整性校验

## 📊 性能优化设计

### 1. 异步处理
- 针对耗时操作（如数据库批量处理、文件导入导出）考虑异步化，避免阻塞UI。

### 2. 数据库优化
- 索引优化
- 连接池管理
- 批量操作支持
- 查询结果缓存

### 3. UI响应性
- 长时间操作使用工作线程
- 进度条和状态提示
- 异步加载大量数据

## 🧪 测试架构

### 1. 单元测试
```python
import unittest
from unittest.mock import Mock, patch

class TestEmailService(unittest.TestCase):
    
    def setUp(self):
        self.config = Mock()
        self.db_service = Mock()
        self.email_service = EmailService(self.config, self.db_service)
        
    def test_create_email(self):
        # 测试邮箱创建
        pass
```

### 2. 集成测试
- 数据库集成测试
- 配置服务集成测试
- UI组件集成测试

### 3. 端到端测试
- 完整业务流程测试
- 用户场景测试

## 🚀 部署架构

### 1. 打包配置
```python
# build.py
import PyInstaller.__main__

PyInstaller.__main__.run([
    'src/main.py',
    '--onefile',
    '--windowed',
    '--icon=resources/icons/app.ico',
    '--name=EmailDomainManager',
    '--add-data=resources;resources',
    '--hidden-import=PyQt6',
])
```

### 2. 安装程序
- NSIS安装脚本
- 自动创建桌面快捷方式
- 卸载程序支持

### 3. 更新机制
- 版本检查
- 自动更新下载
- 增量更新支持

## 📈 扩展性设计

### 1. 插件架构
- 考虑未来功能扩展的插件化机制，例如自定义邮箱生成规则插件。

### 2. 配置扩展
- 支持多种配置格式
- 配置模板系统
- 配置验证规则扩展

### 3. 导出格式扩展
- 插件化导出格式
- 自定义导出模板
- 批量导出支持

这个架构设计确保了系统的可维护性、可扩展性和安全性，为后续的开发提供了清晰的指导。
