# 域名邮箱管理器 - 前端API使用指南

## 📋 概述

本文档为前端开发者提供详细的后端API使用指南，包含所有可用的接口、数据格式、错误处理和最佳实践。

**后端版本**: Phase 3A  
**API状态**: ✅ 已完成并测试通过  
**更新时间**: 2025年1月23日

## 🚀 快速开始

### 1. 服务初始化

```python
# 后端服务初始化示例
from services.email_service import EmailService
from services.tag_service import TagService
from services.batch_service import BatchService
from services.export_service import ExportService

# 初始化数据库和配置
db_service = DatabaseService("path/to/database.db")
config = ConfigModel()

# 初始化各个服务
email_service = EmailService(config, db_service)
tag_service = TagService(db_service)
batch_service = BatchService(db_service, config)
export_service = ExportService(db_service)
export_service.set_services(email_service, tag_service)
```

### 2. 基础数据结构

```typescript
// TypeScript 接口定义（前端参考）
interface EmailModel {
  id?: number;
  email_address: string;
  domain: string;
  prefix: string;
  timestamp_suffix: string;
  created_at?: string;
  last_used?: string;
  updated_at?: string;
  status: 'active' | 'inactive' | 'archived';
  tags: string[];
  notes: string;
  metadata: Record<string, any>;
  is_active: boolean;
  created_by: string;
}

interface TagModel {
  id?: number;
  name: string;
  description: string;
  color: string;
  icon: string;
  created_at?: string;
  updated_at?: string;
  is_system: boolean;
  is_active: boolean;
  usage_count: number;
}

interface PaginationInfo {
  current_page: number;
  page_size: number;
  total_items: number;
  total_pages: number;
  has_next: boolean;
  has_prev: boolean;
}

interface SearchResponse {
  emails: EmailModel[];
  pagination: PaginationInfo;
  filters: Record<string, any>;
}
```

## 📧 邮箱管理API

### 1. 创建邮箱

```python
# 创建单个邮箱
email = email_service.create_email(
    prefix_type="custom",           # "random_name", "timestamp", "custom"
    custom_prefix="test_user",      # 自定义前缀
    tags=["开发", "测试"],           # 标签列表
    notes="测试邮箱"                # 备注
)

# 返回: EmailModel 对象
```

### 2. 高级搜索（推荐使用）

```python
# 高级搜索 - 支持分页和多条件筛选
search_result = email_service.advanced_search_emails(
    keyword="test",                 # 搜索关键词
    domain="example.com",           # 域名筛选
    status="active",                # 状态筛选
    tags=["开发", "测试"],           # 标签筛选
    date_from="2025-01-01",         # 开始日期
    date_to="2025-01-31",           # 结束日期
    created_by="admin",             # 创建者筛选
    has_notes=True,                 # 是否有备注
    page=1,                         # 页码
    page_size=20,                   # 每页大小
    sort_by="created_at",           # 排序字段
    sort_order="desc"               # 排序方向
)

# 返回: SearchResponse 对象
# {
#   "emails": [EmailModel, ...],
#   "pagination": PaginationInfo,
#   "filters": {...}
# }
```

### 3. 多标签搜索

```python
# 搜索包含任一标签的邮箱
emails = email_service.get_emails_by_multiple_tags(
    tag_names=["开发", "测试"],
    match_all=False,                # False=任一标签, True=所有标签
    limit=100
)

# 返回: List[EmailModel]
```

### 4. 日期范围搜索

```python
# 按日期范围搜索
emails = email_service.get_emails_by_date_range(
    start_date="2025-01-01",
    end_date="2025-01-31",
    date_field="created_at",        # "created_at", "last_used", "updated_at"
    limit=100
)

# 返回: List[EmailModel]
```

### 5. 统计分析

```python
# 获取时间段统计
stats = email_service.get_email_statistics_by_period(
    period="month",                 # "day", "week", "month", "year"
    limit=12
)

# 返回: List[Dict] - 统计数据
# [
#   {
#     "period": "2025-01",
#     "total_count": 150,
#     "active_count": 120,
#     "inactive_count": 20,
#     "archived_count": 10
#   },
#   ...
# ]
```

### 6. 邮箱更新和删除

```python
# 更新邮箱
success = email_service.update_email(email_model)

# 删除邮箱（软删除）
success = email_service.delete_email(email_id)

# 获取单个邮箱
email = email_service.get_email_by_id(email_id)
```

## 🏷️ 标签管理API

### 1. 标签基础操作

```python
# 创建标签
tag = tag_service.create_tag(
    name="开发环境",
    description="开发环境相关邮箱",
    color="#3498db",
    icon="💻"
)

# 获取所有标签
tags = tag_service.get_all_tags()

# 更新标签
success = tag_service.update_tag(tag_model)

# 删除标签
success = tag_service.delete_tag(tag_id)
```

### 2. 标签分页查询

```python
# 分页获取标签
result = tag_service.get_tags_with_pagination(
    page=1,
    page_size=20,
    keyword="开发",                 # 搜索关键词
    sort_by="usage_count",          # "name", "created_at", "usage_count"
    sort_order="desc"
)

# 返回: 
# {
#   "tags": [TagModel, ...],
#   "pagination": PaginationInfo,
#   "filters": {...}
# }
```

### 3. 标签与邮箱关联

```python
# 为邮箱添加单个标签
success = tag_service.add_tag_to_email(email_id, tag_id)

# 批量为邮箱添加标签
result = tag_service.batch_add_tags_to_email(email_id, [tag_id1, tag_id2])

# 从邮箱移除标签
success = tag_service.remove_tag_from_email(email_id, tag_id)

# 替换邮箱的所有标签
success = tag_service.replace_email_tags(email_id, [new_tag_id1, new_tag_id2])
```

### 4. 标签统计和分析

```python
# 获取标签使用详情
details = tag_service.get_tag_usage_details(tag_id)

# 返回:
# {
#   "tag": TagModel,
#   "usage": {
#     "total_emails": 50,
#     "active_emails": 40,
#     "archived_emails": 10,
#     "recent_usage": [...]
#   }
# }

# 获取未使用的标签
unused_tags = tag_service.get_unused_tags()

# 获取标签统计
stats = tag_service.get_tag_statistics()
```

### 5. 标签导出

```python
# JSON格式导出
json_data = tag_service.export_tags("json", include_usage=True)

# CSV格式导出
csv_data = tag_service.export_tags("csv", include_usage=True)
```

## ⚡ 批量操作API

### 1. 批量创建邮箱

```python
# 批量创建邮箱
result = batch_service.batch_create_emails(
    count=10,                       # 创建数量
    prefix_type="sequence",         # 前缀类型
    base_prefix="batch_test",       # 基础前缀
    tags=["批量测试"],              # 标签
    notes="批量创建的邮箱",         # 备注
    created_by="admin"              # 创建者
)

# 返回: BatchOperationResult
# {
#   "total": 10,
#   "success": 10,
#   "failed": 0,
#   "emails": [EmailModel, ...],
#   "errors": []
# }
```

### 2. 批量更新邮箱

```python
# 批量更新邮箱
result = batch_service.batch_update_emails(
    email_ids=[1, 2, 3, 4, 5],
    updates={
        "status": "inactive",
        "notes": "批量更新测试"
    }
)

# 返回: BatchOperationResult
```

### 3. 批量标签操作

```python
# 批量应用标签
result = batch_service.batch_apply_tags(
    email_ids=[1, 2, 3, 4, 5],
    tag_names=["生产环境", "重要"],
    operation="add"                 # "add", "remove", "replace"
)

# 返回: BatchOperationResult
```

### 4. 批量数据导入

```python
# 从数据导入邮箱
import_data = [
    {
        "email_address": "test1@example.com",
        "tags": ["导入测试"],
        "notes": "导入的邮箱1",
        "status": "active"
    },
    {
        "email_address": "test2@example.com",
        "tags": ["导入测试"],
        "notes": "导入的邮箱2",
        "status": "active"
    }
]

result = batch_service.batch_import_emails_from_data(
    import_data,
    conflict_strategy="skip"        # "skip", "update", "error"
)

# 返回: BatchOperationResult
```

## 📤 数据导出API

### 1. 全量数据导出

```python
# 导出所有数据
json_data = export_service.export_all_data(
    format_type="json",             # "json", "csv", "xlsx"
    output_path=None,               # 可选：保存路径
    include_deleted=False           # 是否包含已删除数据
)

# 返回: str (JSON/CSV) 或 bytes (Excel)
```

### 2. 模板导出

```python
# 简单模板导出
simple_data = export_service.export_emails_with_template(
    template_name="simple",         # "simple", "detailed", "report"
    filters={"tags": ["生产环境"]}   # 可选：过滤条件
)

# 详细模板导出
detailed_data = export_service.export_emails_with_template("detailed")

# 报告模板导出
report_data = export_service.export_emails_with_template("report")
```

### 3. 高级邮箱导出

```python
# 自定义字段导出
csv_data = email_service.export_emails_advanced(
    format_type="csv",
    filters={"status": "active"},
    fields=["id", "email_address", "domain", "status"],
    include_tags=True,
    include_metadata=False
)

# Excel导出
excel_data = email_service.export_emails_advanced(
    format_type="xlsx",
    include_tags=True
)
```

## 🔒 安全功能API

### 1. 数据加密

```python
from utils.encryption import EncryptionManager

# 初始化加密管理器
encryption_manager = EncryptionManager("master_password")

# 加密敏感数据
encrypted_data = encryption_manager.encrypt("sensitive_information")

# 解密数据
decrypted_data = encryption_manager.decrypt(encrypted_data)

# 检查数据是否已加密
is_encrypted = encryption_manager.is_encrypted(data)
```

### 2. 日志脱敏

```python
from utils.encryption import LogSanitizer, sanitize_for_log

# 初始化脱敏器
sanitizer = LogSanitizer()

# 脱敏日志消息
safe_message = sanitizer.sanitize_log_message("password=secret123 token=abc123")

# 脱敏字典数据
safe_dict = sanitizer.sanitize_dict({
    "username": "admin",
    "password": "secret123",
    "email": "admin@example.com"
})

# 便捷脱敏函数
safe_log = sanitize_for_log({"password": "secret", "username": "test"})
```

## ❌ 错误处理

### 1. 异常类型

```python
# 基础异常
class EmailManagerException(Exception):
    """应用程序的基础异常类"""
    pass

# 数据库错误
class DatabaseError(EmailManagerException):
    """数据库操作相关的错误"""
    pass

# 配置错误
class ConfigurationError(EmailManagerException):
    """配置加载或保存时发生的错误"""
    pass
```

### 2. 错误处理示例

```python
try:
    # 创建邮箱
    email = email_service.create_email(
        prefix_type="custom",
        custom_prefix="test_user"
    )

    if email is None:
        # 处理创建失败
        print("邮箱创建失败")
    else:
        print(f"邮箱创建成功: {email.email_address}")

except DatabaseError as e:
    print(f"数据库错误: {e}")
except ConfigurationError as e:
    print(f"配置错误: {e}")
except Exception as e:
    print(f"未知错误: {e}")
```

### 3. 批量操作错误处理

```python
# 批量操作总是返回详细的结果信息
result = batch_service.batch_create_emails(count=10)

print(f"总计: {result['total']}")
print(f"成功: {result['success']}")
print(f"失败: {result['failed']}")

# 检查错误信息
if result['errors']:
    print("错误详情:")
    for error in result['errors']:
        print(f"  - {error}")
```

## 🎯 前端集成最佳实践

### 1. API调用封装

```typescript
// TypeScript API封装示例
class EmailAPI {
  private baseService: any;

  constructor(baseService: any) {
    this.baseService = baseService;
  }

  // 高级搜索
  async searchEmails(params: SearchParams): Promise<SearchResponse> {
    try {
      const result = await this.baseService.advanced_search_emails(params);
      return result;
    } catch (error) {
      console.error('搜索邮箱失败:', error);
      throw error;
    }
  }

  // 创建邮箱
  async createEmail(params: CreateEmailParams): Promise<EmailModel> {
    try {
      const email = await this.baseService.create_email(params);
      if (!email) {
        throw new Error('邮箱创建失败');
      }
      return email;
    } catch (error) {
      console.error('创建邮箱失败:', error);
      throw error;
    }
  }

  // 批量操作
  async batchCreateEmails(params: BatchCreateParams): Promise<BatchResult> {
    try {
      const result = await this.baseService.batch_create_emails(params);
      return result;
    } catch (error) {
      console.error('批量创建失败:', error);
      throw error;
    }
  }
}
```

### 2. 状态管理

```typescript
// Pinia/Vuex 状态管理示例
interface EmailState {
  emails: EmailModel[];
  tags: TagModel[];
  pagination: PaginationInfo;
  loading: boolean;
  searchFilters: SearchFilters;
}

const useEmailStore = defineStore('email', {
  state: (): EmailState => ({
    emails: [],
    tags: [],
    pagination: {
      current_page: 1,
      page_size: 20,
      total_items: 0,
      total_pages: 0,
      has_next: false,
      has_prev: false
    },
    loading: false,
    searchFilters: {}
  }),

  actions: {
    async searchEmails(filters: SearchFilters) {
      this.loading = true;
      try {
        const result = await emailAPI.searchEmails(filters);
        this.emails = result.emails;
        this.pagination = result.pagination;
        this.searchFilters = result.filters;
      } catch (error) {
        console.error('搜索失败:', error);
      } finally {
        this.loading = false;
      }
    },

    async loadTags() {
      try {
        const result = await tagAPI.getTagsWithPagination({
          page: 1,
          page_size: 100
        });
        this.tags = result.tags;
      } catch (error) {
        console.error('加载标签失败:', error);
      }
    }
  }
});
```

### 3. 组件设计建议

```vue
<!-- EmailList.vue - 邮箱列表组件 -->
<template>
  <div class="email-list">
    <!-- 搜索筛选区域 -->
    <EmailSearch @search="handleSearch" />

    <!-- 批量操作区域 -->
    <BatchOperations
      :selected-emails="selectedEmails"
      @batch-operation="handleBatchOperation"
    />

    <!-- 邮箱列表 -->
    <div class="email-items">
      <EmailItem
        v-for="email in emails"
        :key="email.id"
        :email="email"
        :selected="selectedEmails.includes(email.id)"
        @select="handleSelect"
        @update="handleUpdate"
      />
    </div>

    <!-- 分页组件 -->
    <Pagination
      :pagination="pagination"
      @page-change="handlePageChange"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useEmailStore } from '@/stores/email';

const emailStore = useEmailStore();
const selectedEmails = ref<number[]>([]);

const handleSearch = async (filters: SearchFilters) => {
  await emailStore.searchEmails(filters);
};

const handleBatchOperation = async (operation: BatchOperation) => {
  // 处理批量操作
  const result = await emailAPI.batchOperation(operation);
  if (result.success > 0) {
    // 刷新列表
    await emailStore.searchEmails(emailStore.searchFilters);
  }
};

onMounted(() => {
  emailStore.searchEmails({});
  emailStore.loadTags();
});
</script>
```

### 4. 性能优化建议

```typescript
// 1. 搜索防抖
import { debounce } from 'lodash-es';

const debouncedSearch = debounce(async (keyword: string) => {
  await emailStore.searchEmails({ keyword });
}, 300);

// 2. 虚拟滚动（大量数据）
import { VirtualList } from '@tanstack/vue-virtual';

// 3. 数据缓存
const cache = new Map<string, any>();

const getCachedData = async (key: string, fetcher: () => Promise<any>) => {
  if (cache.has(key)) {
    return cache.get(key);
  }

  const data = await fetcher();
  cache.set(key, data);
  return data;
};

// 4. 分页预加载
const preloadNextPage = async () => {
  if (pagination.has_next) {
    const nextPageData = await emailAPI.searchEmails({
      ...currentFilters,
      page: pagination.current_page + 1
    });
    // 缓存下一页数据
    cache.set(`page_${pagination.current_page + 1}`, nextPageData);
  }
};
```

## 📊 数据格式参考

### 1. 搜索筛选参数

```typescript
interface SearchFilters {
  keyword?: string;           // 搜索关键词
  domain?: string;            // 域名筛选
  status?: EmailStatus;       // 状态筛选
  tags?: string[];            // 标签筛选
  date_from?: string;         // 开始日期 (YYYY-MM-DD)
  date_to?: string;           // 结束日期 (YYYY-MM-DD)
  created_by?: string;        // 创建者筛选
  has_notes?: boolean;        // 是否有备注
  page?: number;              // 页码
  page_size?: number;         // 每页大小
  sort_by?: string;           // 排序字段
  sort_order?: 'asc' | 'desc'; // 排序方向
}
```

### 2. 批量操作参数

```typescript
interface BatchCreateParams {
  count: number;
  prefix_type: 'random_name' | 'sequence' | 'timestamp' | 'custom';
  base_prefix?: string;
  tags?: string[];
  notes?: string;
  created_by?: string;
}

interface BatchUpdateParams {
  email_ids: number[];
  updates: {
    status?: EmailStatus;
    notes?: string;
    last_used?: string;
  };
}

interface BatchTagParams {
  email_ids: number[];
  tag_names: string[];
  operation: 'add' | 'remove' | 'replace';
}
```

---

**前端API指南版本**: Phase 3A
**最后更新**: 2025年1月23日
**状态**: ✅ 已完成并测试通过

如需更多详细信息，请参考 `docs/api-specification.md` 完整API文档。
```
