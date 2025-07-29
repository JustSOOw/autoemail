# 后端API接口总结 - 前端开发参考

## 📋 接口概览

**后端版本**: Phase 3A  
**接口状态**: ✅ 已完成并测试通过  
**总接口数**: 35+ 个核心接口

## 🚀 核心服务接口

### 1. EmailService - 邮箱管理服务

| 接口方法 | 功能描述 | 参数 | 返回值 |
|---------|---------|------|--------|
| `create_email()` | 创建邮箱 | prefix_type, custom_prefix, tags, notes | EmailModel |
| `get_email_by_id()` | 获取单个邮箱 | email_id | EmailModel \| None |
| `search_emails()` | 基础搜索 | keyword, status, tags, limit | List[EmailModel] |
| `update_email()` | 更新邮箱 | email_model | bool |
| `delete_email()` | 删除邮箱 | email_id | bool |
| **`advanced_search_emails()`** | **高级搜索** | **多条件+分页** | **SearchResponse** |
| `get_emails_by_multiple_tags()` | 多标签搜索 | tag_names, match_all, limit | List[EmailModel] |
| `get_emails_by_date_range()` | 日期范围搜索 | start_date, end_date, date_field | List[EmailModel] |
| `get_email_statistics_by_period()` | 时间段统计 | period, limit | List[Dict] |
| `export_emails_advanced()` | 高级导出 | format_type, filters, fields | str |

### 2. TagService - 标签管理服务

| 接口方法 | 功能描述 | 参数 | 返回值 |
|---------|---------|------|--------|
| `create_tag()` | 创建标签 | name, description, color, icon | TagModel \| None |
| `get_tag_by_id()` | 获取单个标签 | tag_id | TagModel \| None |
| `get_all_tags()` | 获取所有标签 | - | List[TagModel] |
| `update_tag()` | 更新标签 | tag_model | bool |
| `delete_tag()` | 删除标签 | tag_id | bool |
| `get_tag_statistics()` | 标签统计 | - | Dict[str, Any] |
| **`add_tag_to_email()`** | **添加标签到邮箱** | **email_id, tag_id** | **bool** |
| `remove_tag_from_email()` | 从邮箱移除标签 | email_id, tag_id | bool |
| `batch_add_tags_to_email()` | 批量添加标签 | email_id, tag_ids | Dict[str, Any] |
| `batch_remove_tags_from_email()` | 批量移除标签 | email_id, tag_ids | Dict[str, Any] |
| `replace_email_tags()` | 替换邮箱标签 | email_id, new_tag_ids | bool |
| **`get_tags_with_pagination()`** | **分页获取标签** | **page, page_size, keyword** | **Dict[str, Any]** |
| `get_tag_usage_details()` | 标签使用详情 | tag_id | Dict[str, Any] |
| `export_tags()` | 导出标签 | format_type, include_usage | str |
| `merge_tags()` | 合并标签 | source_tag_id, target_tag_id | bool |

### 3. BatchService - 批量操作服务

| 接口方法 | 功能描述 | 参数 | 返回值 |
|---------|---------|------|--------|
| **`batch_create_emails()`** | **批量创建邮箱** | **count, prefix_type, tags** | **BatchResult** |
| `batch_update_emails()` | 批量更新邮箱 | email_ids, updates | BatchResult |
| `batch_delete_emails()` | 批量删除邮箱 | email_ids, hard_delete | BatchResult |
| **`batch_apply_tags()`** | **批量应用标签** | **email_ids, tag_names, operation** | **BatchResult** |
| `batch_create_tags()` | 批量创建标签 | tag_data_list | BatchResult |
| `batch_import_emails_from_data()` | 批量导入邮箱 | import_data, conflict_strategy | BatchResult |

### 4. ExportService - 数据导出服务

| 接口方法 | 功能描述 | 参数 | 返回值 |
|---------|---------|------|--------|
| **`export_all_data()`** | **导出所有数据** | **format_type, include_deleted** | **str \| bytes** |
| `export_emails_with_template()` | 模板导出 | template_name, filters | str |
| `set_services()` | 设置依赖服务 | email_service, tag_service | void |

### 5. ConfigService - 配置管理服务

| 接口方法 | 功能描述 | 参数 | 返回值 |
|---------|---------|------|--------|
| `load_config()` | 加载配置 | master_password | ConfigModel |
| `save_config()` | 保存配置 | config, master_password | bool |
| `export_config()` | 导出配置 | include_sensitive | str |
| `import_config()` | 导入配置 | config_json, master_password | bool |

## 📊 核心数据结构

### 1. EmailModel - 邮箱数据模型

```typescript
interface EmailModel {
  id?: number;                    // 邮箱ID
  email_address: string;          // 邮箱地址
  domain: string;                 // 域名
  prefix: string;                 // 前缀
  timestamp_suffix: string;       // 时间戳后缀
  created_at?: string;            // 创建时间
  last_used?: string;             // 最后使用时间
  updated_at?: string;            // 更新时间
  status: EmailStatus;            // 状态
  tags: string[];                 // 标签列表
  notes: string;                  // 备注
  metadata: Record<string, any>;  // 元数据
  is_active: boolean;             // 是否活跃
  created_by: string;             // 创建者
}

type EmailStatus = 'active' | 'inactive' | 'archived';
```

### 2. TagModel - 标签数据模型

```typescript
interface TagModel {
  id?: number;                    // 标签ID
  name: string;                   // 标签名称
  description: string;            // 标签描述
  color: string;                  // 标签颜色
  icon: string;                   // 标签图标
  created_at?: string;            // 创建时间
  updated_at?: string;            // 更新时间
  is_system: boolean;             // 是否系统标签
  is_active: boolean;             // 是否活跃
  usage_count: number;            // 使用次数
}
```

### 3. SearchResponse - 搜索响应模型

```typescript
interface SearchResponse {
  emails: EmailModel[];           // 邮箱列表
  pagination: PaginationInfo;     // 分页信息
  filters: Record<string, any>;   // 筛选条件
}

interface PaginationInfo {
  current_page: number;           // 当前页码
  page_size: number;              // 每页大小
  total_items: number;            // 总条目数
  total_pages: number;            // 总页数
  has_next: boolean;              // 是否有下一页
  has_prev: boolean;              // 是否有上一页
}
```

### 4. BatchResult - 批量操作结果

```typescript
interface BatchResult {
  total: number;                  // 总数
  success: number;                // 成功数
  failed: number;                 // 失败数
  skipped?: number;               // 跳过数
  updated?: number;               // 更新数
  emails?: EmailModel[];          // 邮箱列表
  tags?: TagModel[];              // 标签列表
  errors: string[];               // 错误信息
}
```

## 🎯 常用接口组合

### 1. 邮箱管理页面

```typescript
// 页面初始化
const initEmailPage = async () => {
  // 1. 加载标签列表
  const tagResult = await tagService.get_tags_with_pagination({
    page: 1,
    page_size: 100
  });
  
  // 2. 搜索邮箱
  const emailResult = await emailService.advanced_search_emails({
    page: 1,
    page_size: 20,
    sort_by: "created_at",
    sort_order: "desc"
  });
  
  return {
    tags: tagResult.tags,
    emails: emailResult.emails,
    pagination: emailResult.pagination
  };
};
```

### 2. 搜索筛选功能

```typescript
// 高级搜索
const searchEmails = async (filters: SearchFilters) => {
  const result = await emailService.advanced_search_emails({
    keyword: filters.keyword,
    domain: filters.domain,
    status: filters.status,
    tags: filters.tags,
    date_from: filters.dateFrom,
    date_to: filters.dateTo,
    page: filters.page || 1,
    page_size: filters.pageSize || 20,
    sort_by: filters.sortBy || "created_at",
    sort_order: filters.sortOrder || "desc"
  });
  
  return result;
};
```

### 3. 批量操作流程

```typescript
// 批量创建邮箱
const batchCreateEmails = async (params: BatchCreateParams) => {
  const result = await batchService.batch_create_emails(params);
  
  if (result.success > 0) {
    // 刷新邮箱列表
    await refreshEmailList();
    
    // 显示成功消息
    showMessage(`成功创建 ${result.success} 个邮箱`);
  }
  
  if (result.errors.length > 0) {
    // 显示错误信息
    showErrors(result.errors);
  }
  
  return result;
};
```

### 4. 数据导出流程

```typescript
// 导出数据
const exportData = async (format: 'json' | 'csv' | 'xlsx') => {
  try {
    // 显示加载状态
    setLoading(true);
    
    // 导出数据
    const data = await exportService.export_all_data(format);
    
    // 下载文件
    downloadFile(data, `emails_export.${format}`);
    
    showMessage('导出成功');
  } catch (error) {
    showError('导出失败: ' + error.message);
  } finally {
    setLoading(false);
  }
};
```

## 🔍 搜索筛选参数

### 高级搜索参数

```typescript
interface AdvancedSearchParams {
  keyword?: string;               // 搜索关键词
  domain?: string;                // 域名筛选
  status?: EmailStatus;           // 状态筛选
  tags?: string[];                // 标签筛选（包含任一）
  date_from?: string;             // 开始日期 (YYYY-MM-DD)
  date_to?: string;               // 结束日期 (YYYY-MM-DD)
  created_by?: string;            // 创建者筛选
  has_notes?: boolean;            // 是否有备注
  page?: number;                  // 页码（从1开始）
  page_size?: number;             // 每页大小
  sort_by?: SortField;            // 排序字段
  sort_order?: 'asc' | 'desc';    // 排序方向
}

type SortField = 'created_at' | 'email_address' | 'domain' | 'status';
```

### 标签分页参数

```typescript
interface TagPaginationParams {
  page?: number;                  // 页码（从1开始）
  page_size?: number;             // 每页大小
  keyword?: string;               // 搜索关键词
  sort_by?: TagSortField;         // 排序字段
  sort_order?: 'asc' | 'desc';    // 排序方向
}

type TagSortField = 'name' | 'created_at' | 'usage_count';
```

## ⚡ 性能建议

### 1. 分页加载
- 使用 `advanced_search_emails()` 进行分页查询
- 推荐每页20-50条数据
- 实现虚拟滚动处理大量数据

### 2. 搜索优化
- 使用防抖处理搜索输入
- 缓存搜索结果
- 预加载下一页数据

### 3. 批量操作
- 大批量操作时显示进度条
- 分批处理避免超时
- 提供操作结果详情

### 4. 数据导出
- 大量数据导出时异步处理
- 提供导出进度反馈
- 支持导出任务取消

---

**接口总结版本**: Phase 3A  
**最后更新**: 2025年1月23日  
**状态**: ✅ 已完成并测试通过

**推荐阅读顺序**:
1. 本文档 - 快速了解所有接口
2. `docs/frontend-api-guide.md` - 详细使用指南
3. `docs/api-specification.md` - 完整API规范
