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
│     EmailController     │     ConfigController              │
│     DatabaseController  │     ValidationController          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Service Layer (服务层)                      │
├─────────────────────────────────────────────────────────────┤
│   EmailService    │   ConfigService    │   DatabaseService   │
│   ValidationService │   CryptoService  │   LoggingService    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Model Layer (模型层)                       │
├─────────────────────────────────────────────────────────────┤
│     EmailModel      │     ConfigModel     │     TagModel     │
│     UserModel       │     LogModel        │     BaseModel    │
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
- **EmailService**: 只负责邮箱生成和验证
- **ConfigService**: 只负责配置管理
- **DatabaseService**: 只负责数据持久化

### 2. 依赖倒置原则 (DIP)
高层模块不依赖低层模块，都依赖于抽象：
- 使用接口定义服务契约
- 通过依赖注入实现解耦

### 3. 开闭原则 (OCP)
对扩展开放，对修改关闭：
- 插件化的验证码获取机制
- 可扩展的导出格式支持

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
    verification_code_requested = pyqtSignal(str)
    
    def __init__(self, email_controller):
        self.email_controller = email_controller
        self.setup_ui()
        self.connect_signals()
        
    def setup_ui(self):
        # 左侧：配置信息展示
        # 中央：生成按钮和进度条
        # 右侧：日志输出区域
        
    def on_generate_email(self):
        # 触发邮箱生成请求
        
    def update_progress(self, value, message):
        # 更新进度条和状态信息
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
        # IMAP配置组
        # tempmail配置组
        # 安全设置组
        
    def validate_config(self):
        # 验证配置有效性
        
    def save_config(self):
        # 保存配置更改
```

### 2. Controller Layer (控制层)

**主要职责**: 协调视图和模型，处理业务逻辑

#### 2.1 EmailController (邮箱控制器)
```python
class EmailController:
    """邮箱相关业务逻辑控制器"""
    
    def __init__(self, email_service, database_service):
        self.email_service = email_service
        self.database_service = database_service
        
    async def generate_email(self, config):
        """生成新邮箱"""
        try:
            # 1. 验证配置
            # 2. 生成邮箱地址
            # 3. 保存到数据库
            # 4. 返回结果
            pass
        except Exception as e:
            # 错误处理和日志记录
            pass
            
    async def get_verification_code(self, email_address):
        """获取验证码"""
        # 调用邮箱服务获取验证码
        
    def get_email_list(self, filters=None):
        """获取邮箱列表"""
        # 从数据库获取邮箱列表
        
    def search_emails(self, query):
        """搜索邮箱"""
        # 执行搜索逻辑
```

#### 2.2 ConfigController (配置控制器)
```python
class ConfigController:
    """配置管理控制器"""
    
    def __init__(self, config_service, validation_service):
        self.config_service = config_service
        self.validation_service = validation_service
        
    def load_config(self):
        """加载配置"""
        
    def save_config(self, config_data):
        """保存配置"""
        
    def validate_config(self, config_data):
        """验证配置"""
        
    def test_connection(self, config_type, config_data):
        """测试连接"""
```

### 3. Service Layer (服务层)

**主要职责**: 核心业务逻辑实现

#### 3.1 EmailService (邮箱服务)
```python
class EmailService:
    """邮箱生成和验证服务"""
    
    def __init__(self, config_service):
        self.config_service = config_service
        self.name_generator = NameGenerator()
        
    def generate_email_address(self, domain, prefix_length=4):
        """生成邮箱地址"""
        # 重构自cursor-auto-free的EmailGenerator
        
    async def get_verification_code(self, email_address, method='auto'):
        """获取验证码"""
        # 支持多种获取方式：tempmail.plus, IMAP, POP3
        
    def validate_email_format(self, email):
        """验证邮箱格式"""
        
class VerificationCodeHandler:
    """验证码处理器基类"""
    
    async def get_code(self, email_address):
        raise NotImplementedError
        
class TempMailHandler(VerificationCodeHandler):
    """tempmail.plus处理器"""
    
class IMAPHandler(VerificationCodeHandler):
    """IMAP处理器"""
    
class POP3Handler(VerificationCodeHandler):
    """POP3处理器"""
```

#### 3.2 ConfigService (配置服务)
```python
class ConfigService:
    """配置管理服务"""
    
    def __init__(self, crypto_service):
        self.crypto_service = crypto_service
        self.config_file_path = "config/app.conf"
        
    def load_config(self):
        """加载配置文件"""
        
    def save_config(self, config_data):
        """保存配置文件"""
        
    def encrypt_sensitive_data(self, data):
        """加密敏感数据"""
        
    def decrypt_sensitive_data(self, encrypted_data):
        """解密敏感数据"""
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
        
    def create_email_record(self, email_data):
        """创建邮箱记录"""
        
    def get_email_records(self, filters=None):
        """获取邮箱记录"""
        
    def update_email_record(self, email_id, update_data):
        """更新邮箱记录"""
        
    def delete_email_record(self, email_id):
        """删除邮箱记录"""
        
    # 标签相关操作
    def create_tag(self, tag_data):
        """创建标签"""
        
    def get_tags(self):
        """获取所有标签"""
        
    def associate_email_tag(self, email_id, tag_id):
        """关联邮箱和标签"""
```

### 4. Model Layer (模型层)

**主要职责**: 数据结构定义和业务规则

#### 4.1 数据模型定义
```python
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional

@dataclass
class EmailModel:
    """邮箱数据模型"""
    id: Optional[int] = None
    email_address: str = ""
    domain: str = ""
    created_at: datetime = None
    last_used: Optional[datetime] = None
    verification_status: str = "pending"  # pending, verified, failed
    tags: List[str] = None
    notes: str = ""
    
    def __post_init__(self):
        if self.tags is None:
            self.tags = []
        if self.created_at is None:
            self.created_at = datetime.now()

@dataclass
class ConfigModel:
    """配置数据模型"""
    domain: str = ""
    temp_mail_config: dict = None
    imap_config: dict = None
    security_config: dict = None
    
    def __post_init__(self):
        if self.temp_mail_config is None:
            self.temp_mail_config = {}
        if self.imap_config is None:
            self.imap_config = {}
        if self.security_config is None:
            self.security_config = {}

@dataclass
class TagModel:
    """标签数据模型"""
    id: Optional[int] = None
    name: str = ""
    color: str = "#3498db"
    description: str = ""
    created_at: datetime = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()
```

## 🔐 安全架构设计

### 1. 数据加密
```python
class CryptoService:
    """加密服务"""
    
    def __init__(self, master_password):
        self.master_password = master_password
        self.key = self.derive_key(master_password)
        
    def encrypt(self, data: str) -> str:
        """AES加密"""
        
    def decrypt(self, encrypted_data: str) -> str:
        """AES解密"""
        
    def derive_key(self, password: str) -> bytes:
        """从密码派生加密密钥"""
```

### 2. 敏感数据保护
- IMAP密码加密存储
- API密钥加密存储
- 内存中敏感数据及时清理
- 日志文件脱敏处理

### 3. 配置文件安全
- 配置文件权限控制
- 敏感配置项加密
- 配置文件完整性校验

## 📊 性能优化设计

### 1. 异步处理
```python
import asyncio
from PyQt6.QtCore import QThread, pyqtSignal

class EmailGenerationWorker(QThread):
    """邮箱生成工作线程"""
    
    progress_updated = pyqtSignal(int, str)
    generation_completed = pyqtSignal(dict)
    error_occurred = pyqtSignal(str)
    
    def run(self):
        # 在后台线程执行邮箱生成
        pass
```

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
        self.config_service = Mock()
        self.email_service = EmailService(self.config_service)
        
    def test_generate_email_address(self):
        # 测试邮箱地址生成
        pass
        
    def test_get_verification_code(self):
        # 测试验证码获取
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
```python
class VerificationPlugin:
    """验证码获取插件接口"""
    
    def get_name(self) -> str:
        """获取插件名称"""
        
    async def get_verification_code(self, email: str) -> str:
        """获取验证码"""
        
class PluginManager:
    """插件管理器"""
    
    def load_plugins(self):
        """加载所有插件"""
        
    def get_plugin(self, name: str) -> VerificationPlugin:
        """获取指定插件"""
```

### 2. 配置扩展
- 支持多种配置格式
- 配置模板系统
- 配置验证规则扩展

### 3. 导出格式扩展
- 插件化导出格式
- 自定义导出模板
- 批量导出支持

这个架构设计确保了系统的可维护性、可扩展性和安全性，为后续的开发提供了清晰的指导。
