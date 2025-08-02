---
type: "always_apply"
---

#基础规则
- 始终使用中文回答问题和注释
- 绝对禁止任何简单或则简化的方案和建议
- 不要频繁书写文档，小问题，小修改不要单独写一个文档，重视文档的文件夹结构
- 小问题不要写在README文档中，不要随便创建脚本
- 始终确保README.md文档的即使更新，但只有在重要内容被修改时才能更新，避免频繁的更新，避免小事件的更新。


#必须要遵守的git规则
- 严禁直接在develop和main分支上直接推送代码
- 必须通过pr合并feature分支上的修改到develop分支上
- 必须通过pr合并develop分支上的修改到main分支上

#Git多分支开发规则

##分支命名规则
- 功能分支必须使用格式：feature-{工作区标识}-{功能描述}
- 工作区标识使用A/B等字母，功能描述使用简短英文
- 示例：feature-A-email-validation, feature-B-ui-redesign

##并行开发要求
- 必须使用git worktree进行多功能并行开发
- 严禁频繁切换分支，必须为每个功能创建独立的工作区
- 每个工作区必须对应一个独立的功能分支
- 工作区目录长期保留，不要频繁删除重建

##代码同步规则
- 必须每天开始工作前使用rebase同步develop分支最新代码
- 严禁使用merge合并develop分支代码，必须使用rebase保持历史整洁
- 遇到冲突时必须手动解决，不得跳过或强制推送

##分支合并流程规则
- 功能分支必须先通过PR合并到develop分支
- develop分支再通过PR合并到main分支
- 严禁功能分支直接合并到main分支
- 合并完成后必须删除远程功能分支，本地分支可在工作区内复用

##工作区管理规则
- 功能完成后保留工作区，在同一工作区切换到新功能分支
- 新功能开发流程：checkout develop -> pull -> checkout -b 新功能分支
- 只有长期不使用时才删除worktree工作区

##CI/CD规则
- 所有PR必须通过CI检查才能合并
- 代码必须通过格式化检查（black, isort, flake8）
- 必须通过单元测试和构建测试
- 必须通过安全扫描检查
- PR模板必须完整填写，包含测试说明和检查清单


##git提交时需要遵循一下规范

### Commit Message 格式
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Type 类型
- `feat`: 新功能
- `fix`: Bug修复
- `docs`: 文档更新
- `style`: 代码格式化
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 测试相关
- `build`: 构建相关
- `ci`: CI配置
- `chore`: 其他杂项
