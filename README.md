# 域名邮箱管理器 (Email Domain Manager)

## 📧 项目简介

域名邮箱管理器是一个基于PyQt6的桌面应用程序，专门用于管理和生成基于Cloudflare域名的邮箱地址。本项目从开源项目cursor-auto-free中提取核心邮箱功能，重构为独立的用户友好的GUI应用程序。

## ✨ 主要功能

### 🎯 核心功能
- **邮箱自动生成**: 基于配置域名自动生成唯一邮箱地址
- **验证码获取**: 支持tempmail.plus和IMAP/POP3两种验证码获取方式
- **邮箱管理**: 完整的邮箱记录管理，包括搜索、筛选、标签系统
- **配置管理**: 图形化配置界面，支持多种邮箱服务配置

### 🛠️ 高级功能
- **标签系统**: 自定义标签分类管理邮箱
- **数据导出**: 支持CSV/JSON格式导出邮箱数据
- **安全加密**: 敏感配置信息AES加密存储
- **实时日志**: 详细的操作日志和状态反馈
- **批量操作**: 支持批量删除、标签管理等操作

## 🏗️ 技术架构

### 技术栈
- **前端框架**: PyQt6 + QML - 现代化声明式UI
- **UI设计**: Material Design + 流畅动画
- **数据库**: SQLite - 轻量级本地数据库
- **加密**: cryptography - AES加密保护敏感数据
- **异步处理**: asyncio + asyncqt - 非阻塞UI操作
- **打包工具**: PyInstaller - 单文件exe分发

### 架构模式
- **MVC架构**: Model-View-Controller分层设计
- **QML界面**: 声明式UI + GPU加速渲染
- **服务层**: 业务逻辑与UI分离
- **事件驱动**: 基于信号槽的事件处理
- **插件化**: 可扩展的验证码获取机制

## 📦 快速开始

### 环境要求
- Python 3.9+
- Windows 10+ (主要支持平台)
- 4GB+ RAM
- 100MB+ 磁盘空间

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/your-username/email-domain-manager.git
cd email-domain-manager
```

2. **设置虚拟环境** (重要！)
```bash
# 方式1: 使用自动设置脚本
python scripts/setup_env.py

# 方式2: 手动设置
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

3. **运行测试**
```bash
python run.py test
```

4. **启动应用**
```bash
python run.py
```

### ⚠️ 重要提醒

**必须使用虚拟环境！** 这是Python开发的最佳实践：
- 避免依赖包冲突
- 保持系统环境整洁
- 确保项目依赖隔离
- 便于部署和分发

如果您已经在使用venv，项目会自动检测并正常运行。

### 首次配置

1. **启动应用程序**
   - 双击运行 `src/main.py` 或使用命令行启动

2. **配置域名**
   - 切换到"配置管理"页面
   - 输入您在Cloudflare托管的域名
   - 点击"验证"按钮确认域名配置

3. **配置邮箱服务**
   - 选择验证方式（tempmail.plus 或 IMAP）
   - 填写相应的服务器配置信息
   - 测试连接确保配置正确

4. **开始使用**
   - 应用程序将启动现代化QML界面
   - 享受Material Design风格和流畅动画
   - 切换到"邮箱申请"页面
   - 点击"生成新邮箱"开始使用

### 🎨 QML界面特性

- **Material Design**: 现代化设计语言
- **流畅动画**: GPU加速的过渡效果
- **响应式布局**: 自适应窗口大小
- **声明式语法**: 易于维护和扩展
- **高性能渲染**: 优秀的视觉体验

## 🔧 开发说明

### 项目结构
```
email-domain-manager/
├── src/                          # 源代码
│   ├── main.py                   # 应用入口
│   ├── models/                   # 数据模型
│   │   ├── email_model.py        # 邮箱数据模型
│   │   ├── config_model.py       # 配置数据模型
│   │   └── tag_model.py          # 标签数据模型
│   ├── services/                 # 业务服务
│   │   └── database_service.py   # 数据库服务
│   ├── controllers/              # 控制器
│   ├── views/                    # QML视图组件
│   │   ├── modern_main_window.py # QML主窗口控制器
│   │   └── qml/                  # QML界面文件
│   ├── utils/                    # 工具类
│   │   ├── logger.py             # 日志工具
│   │   └── config_manager.py     # 配置管理
│   └── resources/                # 资源文件
├── scripts/                      # 脚本工具
│   ├── build.py                  # 构建脚本
│   ├── run_tests.py              # 测试脚本
│   ├── start.py                  # 启动脚本
│   └── start.bat                 # Windows启动脚本
├── docs/                         # 文档
├── tests/                        # 测试代码
├── data/                         # 数据目录
├── logs/                         # 日志目录
├── requirements.txt              # 依赖列表
├── run.py                        # 主启动脚本
└── run.bat                       # Windows主启动脚本
```

### 开发环境搭建
1. 安装Python 3.9+
2. 安装依赖：`pip install -r requirements.txt`
3. 运行测试：`python run.py test`
4. 启动开发服务器：`python run.py`

### 构建打包
```bash
# 构建exe文件
python run.py build

# 运行测试
python run.py test

# 启动应用
python run.py start
```


## 🧪 测试

### 运行所有测试
```bash
python run.py test
```

### 运行特定测试
```bash
python -m pytest tests/test_basic.py -v
```

### 测试覆盖率
```bash
python -m pytest tests/ --cov=src --cov-report=html
```

## 🎨 UI界面特性

### 现代化QML界面
- **Material Design**: 现代化设计语言
- **流畅动画**: GPU加速的过渡效果
- **响应式布局**: 自适应窗口大小
- **声明式语法**: 易于维护和扩展
- **高性能渲染**: 优秀的视觉体验
