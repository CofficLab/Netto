# Commit 规范

> 本规范定义了 Netto 项目的 Git 提交信息编写约定。

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
| `feat` | 新功能 | `feat(AppFilter): add per-app rule toggle` |
| `fix` | 修复 bug | `fix(FirewallService): avoid crash on invalid rule update` |
| `refactor` | 重构（不改变行为） | `refactor(Extension): move daemon into system extension` |
| `style` | 样式/格式调整（不改变行为） | `style(AppList): align empty state layout` |
| `perf` | 性能优化 | `perf(FilterDataProvider): cache resolved flow rules` |
| `chore` | 杂务、依赖更新、构建脚本 | `chore: update Package.resolved` |
| `docs` | 文档变更 | `docs(Plugins): add plugin README` |
| `test` | 测试相关 | `test(FirewallService): add rule validation tests` |

---

## Scope

scope 为**模块名或组件名**，使用 PascalCase 或 kebab-case，与代码中的组件/插件命名保持一致。

### 常见 scope 示例

| 范围 | scope 示例 |
|------|-----------|
| 核心层 | `Core`、`AppHost`、`Bootstrap`、`Contract` |
| 服务 | `FirewallService`、`VersionService` |
| 系统扩展 | `Extension`、`FilterDataProvider` |
| UI 组件 | `AppList`、`AppDetail`、`Guide`、`Layout` |
| 插件 | `AppFilter`、`Switcher`、`Store`、`StartButton` |
| Package | `PluginFirewall`、`PluginShell`、`PluginStore`、`KernelCore`、`FactoryNetto` |

### 规则

- 插件相关变更使用插件名作为 scope（如 `AppFilter`）
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
feat(AppFilter): add per-app rule toggle
fix(FirewallService): avoid crash on invalid rule update
refactor(Extension): move daemon into system extension
```

### ❌ 避免的 description

```
feat(AppFilter): Added per-app rule toggle.    ← 不要过去式，不要句号
fix: 修复了一个 bug                              ← 不要中文，不要过于模糊
chore                                           ← 缺少 description
```

---

## 完整示例

```
feat(AppFilter): add per-app rule toggle

fix(FirewallService): avoid crash on invalid rule update

refactor(Extension): move daemon into system extension

perf(FilterDataProvider): cache resolved flow rules

chore: update Package.resolved
```

---

## 拆分提交

- 一个提交只做**一件事**
- 不相关的变更拆分为多次提交
- 重构和功能新增分开提交
