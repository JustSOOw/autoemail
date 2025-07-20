---
type: "always_apply"
---

#基础规则
- 始终使用中文回答问题和注释
- 在本地开发环境中使用“npm run dev” 命令在docker容器中启动整个项目 
- 不要频繁书写文档，小问题，小修改不要单独写一个文档，重视文档的文件夹结构
- 小问题不要写在README文档中，不要随便创建脚本
- 始终确保README.md文档的即使更新，但只有在重要内容被修改时才能更新，避免频繁的更新，避免小事件的更新。


#必须要遵守的git规则
- 严禁直接在develop和main分支上直接推送代码
- 必须通过pr合并feature分支上的修改到develop分支上
- 必须通过pr合并develop分支上的修改到main分支上


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
