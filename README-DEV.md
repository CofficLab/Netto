# 开发文档

## 注意事项

- 确保已卸载应用目录中的软件
- 在运行前，有脚本将构建后的 APP 移动到 Application 目录下，这个脚本配置在了 Xcode 的构建流程中
- 如需升级版本，既要修改 APP 的版本，又要修改扩展的版本

## 问题

- 有几个构建产物？

  2 个，一个 APP 和一个扩展。

- Could not attach to pid : “4226” 打开控制台 APP，搜索相关日志。

## 架构设计 Architecture Design

### 整体架构 Overall Architecture

```bash
UI Layer (用户界面)
    ↓ 调用
Core/Service/ (业务逻辑层)
    ↓ 调用
Core/Repository/ (数据访问层)
    ↓ 操作
Model Layer (数据模型)
    ↓ 存储
SwiftData/CoreData
```

### 层级职责 Layer Responsibilities

- **UI Layer**: 用户界面展示和交互处理
- **Service Layer**: 业务逻辑封装、事务管理、数据验证
- **Repository Layer**: 数据访问、CRUD 操作、数据库管理
- **Model Layer**: 数据模型定义和关系映射

## 参考资料

- [macOS System Preference Panes](https://gist.github.com/rmcdongit/f66ff91e0dad78d4d6346a75ded4b751)
- [Network Extension Debugging on macOS]<https://www.avanderlee.com/debugging/network-extension-debugging-macos/>
- [Filtering Network Traffic]<https://developer.apple.com/documentation/networkextension/filtering-network-traffic>
