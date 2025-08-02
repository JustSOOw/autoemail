# 域名邮箱管理器 (Email Domain Manager)

## 📧 项目简介

域名邮箱管理器是一个简单实用的桌面应用程序，专注于域名邮箱地址的生成、存储和管理。这是一个轻量级的邮箱管理工具，帮助用户高效地组织和管理基于自定义域名的邮箱地址。

## ✨ 主要功能

### 🎯 核心功能
- **邮箱生成**: 基于配置域名自动生成唯一邮箱地址
- **邮箱存储**: 安全地存储和管理生成的邮箱地址
- **邮箱管理**: 完整的邮箱生命周期管理（创建、查看、编辑、删除）
- **状态管理**: 邮箱状态跟踪（活跃、非活跃、归档）
- **搜索过滤**: 强大的搜索和过滤功能

### 🛠️ 高级功能
- **标签系统**: 灵活的标签分类和组织功能
- **数据导出**: 支持JSON和CSV格式的数据导出
- **统计信息**: 详细的使用统计和分析
- **配置管理**: 安全的配置存储和管理
- **批量操作**: 支持批量创建和管理邮箱

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

## 📋 开发进度

### Phase 1A: 后端核心功能开发 ✅ 已完成

**完成时间**: 2024年12月

**主要成果**:
- ✅ 完整的后端项目目录结构
- ✅ Python开发环境和依赖配置
- ✅ 简化的邮箱生成器 (`EmailGenerator`) - 支持多种生成策略
- ✅ 邮箱服务模块 (`EmailService`) - 专注于存储和管理功能
- ✅ 配置服务模块 (`ConfigService`) - 配置管理和持久化
- ✅ 数据库服务 (`DatabaseService`) - SQLite数据库操作
- ✅ 加密工具 (`EncryptionManager`) - 敏感数据加密保护
- ✅ 简化的数据模型定义 (Email, Config, Tag)
- ✅ 优化的数据库表结构
- ✅ 完整的测试用例和验证脚本
- ✅ 代码质量检查和中文注释

**技术特性**:
- 🔐 敏感配置数据AES加密存储
- 🗄️ SQLite数据库，支持事务和索引优化
- 🏷️ 灵活的标签系统
- 📊 详细的统计和日志功能
- 🔄 支持数据导出(JSON/CSV)
- 📱 简洁的状态管理（活跃/非活跃/归档）
- 🧪 完整的单元测试覆盖

**验证状态**: 所有核心功能测试通过 ✅

### Phase 2B: 前端界面开发 ✅ 已完成

**完成时间**: 2025年1月

**主要成果**:
- ✅ 完整的QML页面架构重构
- ✅ 邮箱申请页面 (`email_generation_page.qml`) - 支持单个和批量生成
- ✅ 邮箱管理页面 (`email_management_page.qml`) - 完整的CRUD操作和批量管理
- ✅ 标签管理页面 (`tag_management_page.qml`) - 标签创建、编辑、删除功能
- ✅ 配置管理页面 (`configuration_page.qml`) - 增强的配置选项和验证
- ✅ 通用UI组件库 - 加载动画、状态提示、确认对话框、分页等
- ✅ 页面导航和数据传递机制 - 流畅的页面切换和全局状态管理
- ✅ 键盘快捷键支持 - 提升用户操作效率
- ✅ 调试面板和性能监控 - 开发和维护工具
- ✅ 错误处理和恢复机制 - 提升应用稳定性

**技术特性**:
- 🎨 Material Design风格的现代化界面
- 🔄 流畅的页面切换动画和过渡效果
- 📱 响应式布局设计，适配不同窗口大小
- ⌨️ 完整的键盘快捷键支持
- 🔧 内置调试面板和性能监控工具
- 🛡️ 完善的错误处理和用户反馈机制
- 🧩 模块化的组件设计，易于维护和扩展
- 💾 智能的内存管理和性能优化

**界面功能**:
- 🎯 邮箱生成: 支持随机名字、随机字符串、自定义前缀三种模式
- 📋 邮箱管理: 搜索筛选、分页显示、批量操作、导出功能
- 🏷️ 标签管理: 标签CRUD、颜色和图标自定义、使用统计
- ⚙️ 配置管理: 域名配置、安全设置、系统配置、导入导出
- 🔍 高级搜索: 多条件筛选、实时搜索、结果高亮
- 📊 数据可视化: 统计图表、使用趋势、性能指标

**验证状态**: 所有界面功能开发完成，CI测试通过 ✅

**最新更新**: 2025年1月 - 修复标签创建UI测试失败问题，所有测试现已通过

## 🔧 开发说明

### Git分支环境说明

#### 当前分支结构

本项目采用多分支并行开发模式，当前维护以下分支：

- **main**: 主分支，包含稳定的生产代码
- **develop**: 开发分支，用于集成各功能分支的代码
- **feature-A-xxx**: 功能分支A系列，在主工作区开发
- **feature-B-xxx**: 功能分支B系列，在辅助工作区开发

#### 分支命名规则

采用 `feature-{工作区标识}-{功能描述}` 的命名格式：

- **工作区标识**: A/B等字母，对应不同的工作区
- **功能描述**: 简短英文，描述具体功能
- **示例**:
  - `feature-A-email-validation` (邮箱验证功能)
  - `feature-B-ui-redesign` (UI重设计)
  - `feature-A-config-manager` (配置管理器)

#### 开发环境配置

项目使用 `git worktree` 实现多功能并行开发：

- **主工作区**: 当前目录，开发 `feature-A-xxx` 系列分支
- **辅助工作区**: `../autoemail-A-feature-B` 目录，开发 `feature-B-xxx` 系列分支
- **共享Git数据库**: 两个工作区共享同一个底层Git仓库
- **工作区复用**: 功能完成后保留工作区，切换到新功能分支继续开发

#### 分支管理策略

- **功能开发**: 在各自的feature分支上独立开发
- **代码同步**: 使用rebase方式保持与develop分支同步
- **合并流程**: feature → develop → main 的两级PR合并流程
- **环境隔离**: 每个功能分支对应独立的工作目录
- **分支复用**: 功能完成后在同一工作区开始新功能开发

#### 新功能开发流程

1. **在工作区内切换**: `git checkout develop`
2. **同步最新代码**: `git pull origin develop`
3. **创建新功能分支**: `git checkout -b feature-A-新功能`
4. **开始开发**: 在熟悉的工作区环境中开发新功能

### CI/CD流程说明

#### GitHub Actions工作流

项目配置了完整的CI/CD流程，包含以下工作流：

##### 1. PR基础检查 (`pr-checks.yml`)
**触发条件**: 向develop或main分支提交PR时
**检查内容**:
- 🎨 代码格式检查 (Black, isort)
- 🔍 代码风格检查 (Flake8)
- 🧪 单元测试执行
- 🔨 构建测试验证
- 🔒 安全漏洞扫描
- 🌿 分支命名规则检查
- 📝 提交信息格式检查

##### 2. Develop分支CI (`develop-ci.yml`)
**触发条件**: 代码推送到develop分支时
**执行内容**:
- 🧪 完整测试套件
- 🔄 多平台构建测试 (Windows/Linux/macOS)
- ⚡ 性能基准测试
- 📈 代码质量分析
- 🛡️ 深度安全扫描
- 📚 文档完整性检查

##### 3. Main分支发布 (`main-release.yml`)
**触发条件**: 代码合并到main分支时
**执行内容**:
- 🔍 发布前完整检查
- 📦 多平台构建发布版本
- 🎉 自动创建GitHub Release
- 📚 部署项目文档到GitHub Pages

#### 分支保护规则

- **main分支**: 需要PR审查，所有检查通过后才能合并
- **develop分支**: 需要PR审查，基础检查通过后才能合并
- **feature分支**: 遵循命名规则，必须通过CI检查

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

## 📚 API文档

### 后端接口文档 (Phase 3A)

为前端开发提供完整的后端API接口文档：

- **[API接口总结](docs/api-summary-for-frontend.md)** - 快速参考所有接口
- **[前端API使用指南](docs/frontend-api-guide.md)** - 详细使用说明和示例
- **[完整API规范](docs/api-specification.md)** - 技术规范文档

#### 核心功能接口

- 🔍 **高级搜索**: `advanced_search_emails()` - 支持多条件筛选和分页
- 🏷️ **标签管理**: `TagService` - 完整的标签CRUD和关联操作
- ⚡ **批量操作**: `BatchService` - 邮箱和标签的批量处理
- 📤 **数据导出**: `ExportService` - 多格式数据导出功能
- 🔒 **安全功能**: 加密、脱敏、安全配置管理

#### 接口特性

- **35+ 核心接口**: 覆盖所有业务功能
- **分页查询**: 支持大数据量处理
- **多条件筛选**: 灵活的搜索和筛选
- **批量操作**: 高效的批量处理
- **数据导出**: JSON/CSV/Excel多格式支持
- **安全保护**: 数据加密和日志脱敏

## 🎨 UI界面特性

### 现代化QML界面
- **Material Design**: 现代化设计语言
- **流畅动画**: GPU加速的过渡效果
- **响应式布局**: 自适应窗口大小
- **声明式语法**: 易于维护和扩展
- **高性能渲染**: 优秀的视觉体验
