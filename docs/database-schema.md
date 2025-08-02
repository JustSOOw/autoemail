# 域名邮箱管理器 - 数据库表结构设计

## 📊 数据库概述

本项目使用SQLite作为数据库，设计了5个核心表来存储邮箱记录、标签信息、配置数据等。数据库文件位置：`data/email_manager.db`

## 🗃️ 表结构设计

### 1. emails表 - 邮箱记录

存储所有生成的邮箱记录和相关元数据。

```sql
CREATE TABLE emails (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email_address VARCHAR(255) NOT NULL UNIQUE,
    domain VARCHAR(100) NOT NULL,
    prefix VARCHAR(50) NOT NULL,
    timestamp_suffix VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_used DATETIME,
    verification_status VARCHAR(20) DEFAULT 'pending',
    verification_code VARCHAR(10),
    verification_method VARCHAR(20),
    verification_attempts INTEGER DEFAULT 0,
    last_verification_at DATETIME,
    notes TEXT,
    is_active BOOLEAN DEFAULT 1,
    metadata TEXT, -- JSON格式存储额外信息
    created_by VARCHAR(50) DEFAULT 'system',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_emails_domain ON emails(domain);
CREATE INDEX idx_emails_created_at ON emails(created_at);
CREATE INDEX idx_emails_verification_status ON emails(verification_status);
CREATE INDEX idx_emails_is_active ON emails(is_active);
CREATE UNIQUE INDEX idx_emails_address ON emails(email_address);
```

**字段说明：**
- `id`: 主键，自增ID
- `email_address`: 完整邮箱地址，唯一约束
- `domain`: 域名部分
- `prefix`: 邮箱前缀（用户名部分）
- `timestamp_suffix`: 时间戳后缀
- `verification_status`: 验证状态 (pending, verified, failed, expired)
- `verification_code`: 最后获取的验证码
- `verification_method`: 验证码获取方式 (tempmail, imap, pop3)
- `metadata`: JSON格式存储扩展信息

### 2. tags表 - 标签定义

存储用户自定义的标签信息。

```sql
CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    color VARCHAR(7) DEFAULT '#3498db', -- 十六进制颜色值
    icon VARCHAR(50), -- 图标名称或Unicode
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_system BOOLEAN DEFAULT 0, -- 是否为系统预定义标签
    sort_order INTEGER DEFAULT 0 -- 排序顺序
);

-- 索引
CREATE UNIQUE INDEX idx_tags_name ON tags(name);
CREATE INDEX idx_tags_sort_order ON tags(sort_order);
```

**字段说明：**
- `name`: 标签名称，唯一约束
- `color`: 标签颜色，十六进制格式
- `icon`: 标签图标
- `is_system`: 区分用户标签和系统预定义标签
- `sort_order`: 显示排序顺序

### 3. email_tags表 - 邮箱标签关联

实现邮箱和标签的多对多关系。

```sql
CREATE TABLE email_tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) DEFAULT 'user',
    FOREIGN KEY (email_id) REFERENCES emails(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
    UNIQUE(email_id, tag_id) -- 防止重复关联
);

-- 索引
CREATE INDEX idx_email_tags_email_id ON email_tags(email_id);
CREATE INDEX idx_email_tags_tag_id ON email_tags(tag_id);
CREATE UNIQUE INDEX idx_email_tags_unique ON email_tags(email_id, tag_id);
```

**字段说明：**
- `email_id`: 邮箱记录ID，外键
- `tag_id`: 标签ID，外键
- 联合唯一约束防止重复关联

### 4. configurations表 - 配置管理

存储应用程序配置信息和历史版本。

```sql
CREATE TABLE configurations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT, -- 可能包含加密数据
    config_type VARCHAR(50) NOT NULL, -- domain, imap, tempmail, security
    is_encrypted BOOLEAN DEFAULT 0,
    is_active BOOLEAN DEFAULT 1,
    version INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- 索引
CREATE INDEX idx_config_key_type ON configurations(config_key, config_type);
CREATE INDEX idx_config_active ON configurations(is_active);
CREATE INDEX idx_config_type ON configurations(config_type);
```

**字段说明：**
- `config_key`: 配置键名
- `config_value`: 配置值，可能是加密的
- `config_type`: 配置类型分类
- `is_encrypted`: 标识是否为加密数据
- `version`: 配置版本号，支持配置历史

### 5. operation_logs表 - 操作日志

记录用户操作和系统事件日志。

```sql
CREATE TABLE operation_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    operation_type VARCHAR(50) NOT NULL, -- CREATE, UPDATE, DELETE, GENERATE, VERIFY
    target_type VARCHAR(50) NOT NULL, -- EMAIL, TAG, CONFIG
    target_id INTEGER,
    operation_details TEXT, -- JSON格式详细信息
    result VARCHAR(20) NOT NULL, -- SUCCESS, FAILED, PARTIAL
    error_message TEXT,
    user_agent TEXT,
    ip_address VARCHAR(45),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    execution_time REAL -- 执行时间（毫秒）
);

-- 索引
CREATE INDEX idx_logs_operation_type ON operation_logs(operation_type);
CREATE INDEX idx_logs_target_type ON operation_logs(target_type);
CREATE INDEX idx_logs_created_at ON operation_logs(created_at);
CREATE INDEX idx_logs_result ON operation_logs(result);
```

**字段说明：**
- `operation_type`: 操作类型
- `target_type`: 操作目标类型
- `target_id`: 目标记录ID
- `operation_details`: JSON格式的操作详情
- `execution_time`: 操作执行时间

## 🔧 数据库初始化脚本

### 1. 创建表结构

```sql
-- database/init.sql

-- 启用外键约束
PRAGMA foreign_keys = ON;

-- 创建所有表
-- (上述CREATE TABLE语句)

-- 插入系统预定义标签
INSERT INTO tags (name, color, icon, description, is_system, sort_order) VALUES
('测试用', '#e74c3c', '🧪', '用于测试目的的邮箱', 1, 1),
('开发用', '#3498db', '💻', '开发环境使用的邮箱', 1, 2),
('生产用', '#27ae60', '🚀', '生产环境使用的邮箱', 1, 3),
('临时用', '#f39c12', '⏰', '临时使用的邮箱', 1, 4),
('重要', '#9b59b6', '⭐', '重要的邮箱记录', 1, 5);

-- 插入默认配置
INSERT INTO configurations (config_key, config_value, config_type, description) VALUES
('app_version', '1.0.0', 'system', '应用程序版本'),
('database_version', '1.0.0', 'system', '数据库版本'),
('auto_cleanup_days', '30', 'system', '自动清理天数'),
('max_verification_attempts', '5', 'system', '最大验证尝试次数'),
('default_timeout', '300', 'system', '默认超时时间（秒）');
```

### 2. 数据库升级脚本

```sql
-- database/migrations/v1.0.1.sql
-- 示例：添加新字段

ALTER TABLE emails ADD COLUMN last_activity_at DATETIME;
CREATE INDEX idx_emails_last_activity ON emails(last_activity_at);

-- 更新数据库版本
UPDATE configurations 
SET config_value = '1.0.1', updated_at = CURRENT_TIMESTAMP 
WHERE config_key = 'database_version';
```

## 📈 数据库性能优化

### 1. 索引策略

**主要查询场景：**
- 按域名筛选邮箱
- 按创建时间排序
- 按验证状态筛选
- 标签关联查询
- 全文搜索邮箱地址

**索引优化：**
```sql
-- 复合索引优化常用查询
CREATE INDEX idx_emails_domain_status ON emails(domain, verification_status);
CREATE INDEX idx_emails_active_created ON emails(is_active, created_at DESC);

-- 全文搜索索引（SQLite FTS5）
CREATE VIRTUAL TABLE emails_fts USING fts5(
    email_address, 
    domain, 
    notes,
    content='emails',
    content_rowid='id'
);

-- FTS索引触发器
CREATE TRIGGER emails_fts_insert AFTER INSERT ON emails BEGIN
    INSERT INTO emails_fts(rowid, email_address, domain, notes) 
    VALUES (new.id, new.email_address, new.domain, new.notes);
END;

CREATE TRIGGER emails_fts_delete AFTER DELETE ON emails BEGIN
    DELETE FROM emails_fts WHERE rowid = old.id;
END;

CREATE TRIGGER emails_fts_update AFTER UPDATE ON emails BEGIN
    DELETE FROM emails_fts WHERE rowid = old.id;
    INSERT INTO emails_fts(rowid, email_address, domain, notes) 
    VALUES (new.id, new.email_address, new.domain, new.notes);
END;
```

### 2. 查询优化

**常用查询示例：**

```sql
-- 获取邮箱列表（分页）
SELECT 
    e.id, e.email_address, e.domain, e.created_at, 
    e.verification_status, e.last_used,
    GROUP_CONCAT(t.name) as tags
FROM emails e
LEFT JOIN email_tags et ON e.id = et.email_id
LEFT JOIN tags t ON et.tag_id = t.id
WHERE e.is_active = 1
GROUP BY e.id
ORDER BY e.created_at DESC
LIMIT 50 OFFSET 0;

-- 按标签筛选邮箱
SELECT DISTINCT e.*
FROM emails e
JOIN email_tags et ON e.id = et.email_id
JOIN tags t ON et.tag_id = t.id
WHERE t.name IN ('测试用', '开发用')
AND e.is_active = 1;

-- 全文搜索
SELECT e.*, rank
FROM emails e
JOIN emails_fts fts ON e.id = fts.rowid
WHERE emails_fts MATCH 'test*'
ORDER BY rank;

-- 统计信息查询
SELECT 
    COUNT(*) as total_emails,
    COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified_count,
    COUNT(CASE WHEN created_at >= date('now', '-7 days') THEN 1 END) as recent_count
FROM emails 
WHERE is_active = 1;
```

## 🔒 数据安全设计

### 1. 敏感数据加密

```sql
-- 配置表中的敏感数据标记
UPDATE configurations 
SET is_encrypted = 1 
WHERE config_key IN ('imap_password', 'tempmail_epin', 'api_keys');
```

### 2. 数据清理策略

```sql
-- 自动清理过期数据
DELETE FROM emails 
WHERE created_at < date('now', '-30 days') 
AND verification_status = 'failed'
AND is_active = 0;

-- 清理操作日志
DELETE FROM operation_logs 
WHERE created_at < date('now', '-90 days');
```

### 3. 数据备份

```sql
-- 备份重要数据
CREATE TABLE emails_backup AS SELECT * FROM emails;
CREATE TABLE tags_backup AS SELECT * FROM tags;
CREATE TABLE configurations_backup AS SELECT * FROM configurations;
```

## 📊 数据库维护

### 1. 定期维护任务

```sql
-- 重建索引
REINDEX;

-- 清理碎片
VACUUM;

-- 分析统计信息
ANALYZE;
```

### 2. 数据完整性检查

```sql
-- 检查外键约束
PRAGMA foreign_key_check;

-- 检查数据库完整性
PRAGMA integrity_check;

-- 检查孤立记录
SELECT et.* FROM email_tags et
LEFT JOIN emails e ON et.email_id = e.id
WHERE e.id IS NULL;
```

这个数据库设计支持了应用程序的所有核心功能，并考虑了性能优化和数据安全性。
