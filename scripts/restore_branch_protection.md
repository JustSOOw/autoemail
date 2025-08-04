# 恢复分支保护规则指南

## 当前测试配置

为了方便测试4平台构建，当前配置允许PR到main分支时直接触发构建和发布流程。

## 测试完成后的恢复步骤

### 1. 恢复main-release.yml工作流

将以下条件从：
```yaml
if: github.event_name == 'push' || github.event_name == 'workflow_dispatch' || github.event_name == 'pull_request'
```

恢复为：
```yaml
if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
```

需要修改的位置：
- `create-release` job (第305行)
- `deploy-docs` job (第416行)

### 2. 移除PR版本号生成逻辑

在 `确定版本号` 步骤中，移除PR相关的版本号生成逻辑：

```yaml
elif [[ "${{ github.event_name }}" == "pull_request" ]]; then
  # PR测试版本：包含PR编号
  VERSION="v$(date +'%Y.%m.%d')-pr${{ github.event.number }}-test${{ github.run_number }}"
```

### 3. 恢复Release预发布设置

将：
```yaml
prerelease: ${{ github.event_name == 'pull_request' }}
```

恢复为：
```yaml
prerelease: false
```

### 4. 更新README.md

移除测试模式相关的说明，恢复正常的分支保护规则描述。

### 5. 设置GitHub分支保护规则

在GitHub仓库设置中启用分支保护：

**main分支保护规则：**
- ✅ Require pull request reviews before merging
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Include administrators

**develop分支保护规则：**
- ✅ Require pull request reviews before merging
- ✅ Require status checks to pass before merging

## 测试建议

1. 创建PR到main分支测试4平台构建
2. 验证所有平台的构建产物
3. 测试下载和运行各平台版本
4. 确认ARM64版本正常工作后，将experimental改为false
5. 测试完成后按上述步骤恢复分支保护

## 注意事项

- 测试期间会创建多个预发布版本，测试完成后可以删除
- 确保在恢复分支保护前完成所有必要的测试
- 建议在feature分支中准备好恢复配置的PR
