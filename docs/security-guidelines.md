# 代码安全规范文档

## 📋 概述

本文档定义了域名邮箱管理器项目的代码安全规范，包含安全编码最佳实践、常见安全问题及解决方案、bandit扫描规则说明和代码审查检查清单。

## 🔒 安全编码最佳实践

### 1. 敏感数据处理

#### 1.1 避免硬编码敏感信息
**问题**: 在代码中直接使用空字符串或明文密码
```python
# ❌ 错误做法
password = ""
api_key = "hardcoded_key"
```

**解决方案**: 使用安全常量或配置项
```python
# ✅ 正确做法
SENSITIVE_DATA_PLACEHOLDER = "[REDACTED]"
password = SENSITIVE_DATA_PLACEHOLDER

# 或使用环境变量
import os
api_key = os.getenv('API_KEY', '')
```

#### 1.2 敏感数据清理
- 导出配置时使用占位符替换敏感数据
- 日志记录时避免输出敏感信息
- 内存中的敏感数据使用后及时清理

### 2. SQL注入防护

#### 2.1 使用参数化查询
**问题**: 使用字符串拼接构建SQL查询
```python
# ❌ 错误做法
query = f"SELECT * FROM users WHERE name = '{user_name}'"
cursor.execute(query)
```

**解决方案**: 使用参数化查询
```python
# ✅ 正确做法
query = "SELECT * FROM users WHERE name = ?"
cursor.execute(query, (user_name,))
```

#### 2.2 输入验证和白名单
**问题**: 直接使用用户输入构建动态SQL
```python
# ❌ 错误做法
cursor.execute(f"PRAGMA table_info({table_name})")
```

**解决方案**: 使用白名单验证
```python
# ✅ 正确做法
ALLOWED_TABLE_NAMES = {'emails', 'tags', 'configurations'}

if table_name not in ALLOWED_TABLE_NAMES:
    raise ValueError(f"不允许的表名: {table_name}")

if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', table_name):
    raise ValueError(f"表名格式不安全: {table_name}")

cursor.execute(f"PRAGMA table_info({table_name})")  # nosec B608
```

### 3. 随机数生成

#### 3.1 使用加密安全的随机数
**问题**: 使用标准random模块生成安全相关的随机数
```python
# ❌ 错误做法
import random
token = random.choice(chars)
```

**解决方案**: 使用secrets模块
```python
# ✅ 正确做法
import secrets
token = secrets.choice(chars)
```

#### 3.2 随机数使用场景
- **邮箱前缀生成**: 使用secrets模块确保唯一性
- **会话令牌**: 必须使用加密安全的随机数
- **密码盐值**: 使用secrets.token_bytes()

### 4. 异常处理

#### 4.1 避免空异常处理
**问题**: 使用try-except-pass模式
```python
# ❌ 错误做法
try:
    risky_operation()
except:
    pass
```

**解决方案**: 具体的异常处理和日志记录
```python
# ✅ 正确做法
try:
    risky_operation()
except SpecificException as e:
    logger.error(f"操作失败: {e}")
    # 适当的错误处理逻辑
except Exception as e:
    logger.error(f"未预期的错误: {e}")
    raise
```

## 🛡️ 常见安全问题及解决方案

### 1. Bandit检测的安全问题

#### B105: 硬编码密码字符串
- **问题**: 使用空字符串或硬编码密码
- **解决**: 使用常量SENSITIVE_DATA_PLACEHOLDER
- **影响**: 低风险，但可能泄露敏感信息结构

#### B110: try-except-pass
- **问题**: 忽略所有异常
- **解决**: 具体异常处理和日志记录
- **影响**: 中风险，可能隐藏重要错误

#### B608: SQL注入
- **问题**: 使用字符串格式化构建SQL
- **解决**: 参数化查询 + 输入验证
- **影响**: 高风险，可能导致数据泄露

#### B311: 标准随机数生成器
- **问题**: 使用random模块生成安全相关随机数
- **解决**: 使用secrets模块
- **影响**: 中风险，可能被预测

### 2. 输入验证

#### 2.1 数据类型验证
```python
def validate_email_id(email_id: Any) -> int:
    """验证邮箱ID"""
    if not isinstance(email_id, int):
        raise ValueError("邮箱ID必须是整数")
    if email_id <= 0:
        raise ValueError("邮箱ID必须大于0")
    return email_id
```

#### 2.2 字符串长度限制
```python
def validate_domain(domain: str) -> str:
    """验证域名"""
    if not isinstance(domain, str):
        raise ValueError("域名必须是字符串")
    if len(domain) > 253:
        raise ValueError("域名长度不能超过253字符")
    if not re.match(r'^[a-zA-Z0-9.-]+$', domain):
        raise ValueError("域名包含非法字符")
    return domain.lower()
```

### 3. 日志安全

#### 3.1 避免记录敏感信息
```python
# ❌ 错误做法
logger.info(f"用户登录: {username}, 密码: {password}")

# ✅ 正确做法
logger.info(f"用户登录: {username}")
```

#### 3.2 结构化日志
```python
logger.info("用户操作", extra={
    'user_id': user_id,
    'action': 'create_email',
    'timestamp': datetime.now().isoformat()
})
```

## 🔍 Bandit扫描规则说明

### 1. 高优先级规则

- **B301-B324**: SQL注入相关
- **B501-B506**: 请求相关安全问题
- **B601-B612**: Shell注入

### 2. 中优先级规则

- **B101-B112**: 硬编码和配置问题
- **B201-B210**: Flask相关安全问题
- **B311**: 随机数生成

### 3. 低优先级规则

- **B401-B413**: 导入和模块相关
- **B701-B703**: Jinja2模板

### 4. 扫描命令

```bash
# 基本扫描
bandit -r src/

# 详细报告
bandit -r src/ -f json -o security_report.json

# 排除特定规则
bandit -r src/ -s B101,B601

# 包含置信度
bandit -r src/ -i
```

## ✅ 代码审查检查清单

### 1. 安全检查项

#### 输入验证
- [ ] 所有用户输入都经过验证
- [ ] 使用白名单而非黑名单验证
- [ ] 数据类型和长度检查
- [ ] 特殊字符过滤

#### SQL安全
- [ ] 使用参数化查询
- [ ] 避免动态SQL构建
- [ ] 表名和列名使用白名单
- [ ] 数据库连接使用最小权限

#### 敏感数据
- [ ] 无硬编码密码或密钥
- [ ] 敏感数据加密存储
- [ ] 日志不包含敏感信息
- [ ] 内存中敏感数据及时清理

#### 随机数和加密
- [ ] 安全相关随机数使用secrets模块
- [ ] 密码使用强哈希算法
- [ ] 加密算法使用推荐标准
- [ ] 密钥管理安全

### 2. 代码质量检查

#### 异常处理
- [ ] 避免空异常处理
- [ ] 具体异常类型捕获
- [ ] 适当的错误日志记录
- [ ] 异常信息不泄露敏感数据

#### 函数安全
- [ ] 函数参数验证
- [ ] 返回值类型检查
- [ ] 边界条件处理
- [ ] 资源正确释放

### 3. 配置安全

#### 环境配置
- [ ] 敏感配置使用环境变量
- [ ] 生产环境禁用调试模式
- [ ] 默认配置安全
- [ ] 配置文件权限控制

#### 依赖安全
- [ ] 定期更新依赖包
- [ ] 使用安全版本
- [ ] 避免已知漏洞的包
- [ ] 最小化依赖

## 🚀 安全工具集成

### 1. 静态分析工具

```bash
# Bandit - Python安全扫描
pip install bandit
bandit -r src/

# Safety - 依赖漏洞检查
pip install safety
safety check

# Semgrep - 多语言静态分析
pip install semgrep
semgrep --config=auto src/
```

### 2. 代码质量工具

```bash
# Pylint - 代码质量检查
pip install pylint
pylint src/

# MyPy - 类型检查
pip install mypy
mypy src/

# Black - 代码格式化
pip install black
black src/
```

### 3. 持续集成

```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.9
      - name: Install dependencies
        run: |
          pip install bandit safety
      - name: Run Bandit
        run: bandit -r src/
      - name: Run Safety
        run: safety check
```

## 📚 参考资源

### 1. 官方文档
- [OWASP Python Security](https://owasp.org/www-project-python-security/)
- [Python Security Best Practices](https://python.org/dev/security/)
- [Bandit Documentation](https://bandit.readthedocs.io/)

### 2. 安全标准
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**文档版本**: 1.0  
**最后更新**: 2025-01-22  
**维护者**: 开发团队
