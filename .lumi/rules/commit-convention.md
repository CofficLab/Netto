# Commit 规范

> 本规范定义了项目的 Git 提交信息编写约定。

---

## 格式

```
<type>(<scope>): <description>
```

- **type** 和 **description** 必填，使用英文
- **scope** 可选，但推荐填写
- description 使用小写开头，不加句号，使用祈使语气（如 `add ...`、`fix ...`）

---

## Type

| type | 用途 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(PluginFirewall): add rule import from clipboard` |
| `fix` | 修复 bug | `fix(Extension): always answer paused flow with deadline` |
| `refactor` | 重构（不改变行为） | `refactor(ProviderShell): simplify navigation layout` |
| `style` | 样式/格式调整（不改变行为） | `style(Dashboard): match toolbar switch to settings button` |
| `perf` | 性能优化 | `perf(EventStore): delete events in batches` |
| `chore` | 杂务、依赖更新、构建脚本 | `chore: update Package.resolved` |
| `docs` | 文档变更 | `docs: update README with new features` |
| `test` | 测试相关 | `test(PluginFirewall): add rule parsing tests` |

---

## Scope

scope 为**模块名或组件名**，使用 PascalCase 或 kebab-case，与代码中的组件/插件命名保持一致。

### 常见 scope 示例

| 范围 | scope 示例 |
|------|-----------|
| 核心框架 | `FactoryNetto`、`LumiKernel`、`NettoIPCContracts` |
| App & Extension | `App`、`Extension`、`Bridge` |
| UI 组件 | `Dashboard`、`ProviderFirewallEvents`、`ViewEnvironment` |
| 插件 | `PluginFirewall`、`PluginPersistence`、`PluginStore`、`PluginAppSettings` |
| Provider | `ProviderShell`、`ProviderAppCatalog`、`ProviderFirewall`、`ProviderStoreKit` |

### 规则

- 插件相关变更使用插件名作为 scope（如 `PluginFirewall`）
- 跨多个模块的变更可省略 scope（如 `chore: update dependencies`）
- 单个 scope 无法覆盖时，选择最核心的模块，或将变更拆分为多次提交

---

## Description 规范

- 使用**祈使语气**：`add ...`、`fix ...`、`remove ...`、`update ...`
- **小写开头**，结尾**不加句号**
- 简明扼要，一句话概括变更内容
- 如需更多细节，在空行后添加正文（body），但通常一句话即可

### ✅ 好的 description

```
feat(PluginFirewall): add rule import from clipboard
fix(Extension): always answer a paused flow with a deadline fallback
perf(PluginEventStore): delete events in batches and project only app identifiers
```

### ❌ 避免的 description

```
feat: Added new feature.    ← 不要过去式，不要句号
fix: 修复了一个 bug          ← 不要中文，不要过于模糊
chore                       ← 缺少 description
```

---

## 完整示例

```
feat(PluginFirewall): add rule import from clipboard

fix(Extension): always answer a paused flow with a deadline fallback

perf(PluginEventStore): delete events in batches and project only app identifiers

chore: update Package.resolved

docs: update README with installation guide
```

---

## 拆分提交

- 一个提交只做**一件事**
- 不相关的变更拆分为多次提交
- 重构和功能新增分开提交