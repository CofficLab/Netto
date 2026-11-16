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

```text
App/  SwiftUI/AppKit 应用宿主与组合根（源码、配置平铺存放）
    ↓ 通过
Packages/FactoryNetto  唯一装配点
    ↓ 创建并启动
Packages/KernelCore  插件生命周期与 Provider 注册
    ├─ Packages/Provider*  能力协议与中立数据类型
    └─ Packages/Plugin*    功能实现、UI 与系统服务

Extension/ + Bridge/  独立的 Network Extension 进程与 IPC 边界
Assets.xcassets/     App 图标与界面资源
```

### 层级职责 Layer Responsibilities

- **App**：创建 SwiftUI 场景、处理 AppKit 生命周期与状态栏承载，并调用 FactoryNetto 启动唯一 Kernel。
- **FactoryNetto**：显式装配 Provider 与 Plugin，控制依赖和启动顺序。
- **KernelCore**：管理插件生命周期、Provider 注册解析及贡献清理，不依赖具体功能包。
- **Provider packages**：定义跨插件能力契约和中立数据类型。
- **Plugin packages**：拥有各自的业务逻辑、存储、系统 API 与功能界面。
- **Extension / Bridge**：保持与 App Kernel 隔离的进程边界，只通过 IPC 契约通信。

## 参考资料

- [macOS System Preference Panes](https://gist.github.com/rmcdongit/f66ff91e0dad78d4d6346a75ded4b751)
- [Network Extension Debugging on macOS]<https://www.avanderlee.com/debugging/network-extension-debugging-macos/>
- [Filtering Network Traffic]<https://developer.apple.com/documentation/networkextension/filtering-network-traffic>
