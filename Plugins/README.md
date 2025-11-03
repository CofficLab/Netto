# 插件系统架构文档

## 概述

本项目的插件系统采用基于协议（Protocol）的架构设计，支持动态注册和自动发现。插件系统使得应用功能模块化，每个功能可以作为独立插件开发和维护，通过统一的接口与主应用集成。

## 核心组件

### 1. SuperPlugin 协议

`SuperPlugin` 是所有插件必须遵循的基础协议，位于 `Core/Contract/SuperPlugin.swift`。

**特性：**

- 使用 `Actor` 确保并发安全
- 定义了插件的生命周期和功能接口
- 提供可选方法的默认实现

**核心方法：**

```swift
protocol SuperPlugin: Actor {
    // 插件标识符
    nonisolated var label: String { get }
    
    // 添加工具栏按钮
    @MainActor func addToolBarButtons() -> [(id: String, view: AnyView)]
    
    // 提供 RootView 包装器（用于注入环境变量等）
    @MainActor func provideRootView<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> AnyView?
    
    // 添加设置按钮
    @MainActor func addSettingsButtons() -> [(id: String, view: AnyView)]
    
    // 获取工具栏位置（left/center/right）
    @MainActor func getTopBarPosition() -> TopBarPosition
    
    // 提供独立窗口内容
    @MainActor func provideWindowContent() -> (any PluginWindowContent)?
}
```

**TopBarPosition 枚举：**

- `left` - 左侧位置
- `center` - 中心位置  
- `right` - 右侧位置

### 2. PluginRegistry（插件注册中心）

`PluginRegistry` 是一个 Actor，负责插件的注册和构建管理，位于 `Core/Providers/PluginRegistry.swift`。

**功能：**

- 注册插件工厂函数
- 按 `order` 排序构建所有插件
- 支持按 ID 获取特定插件

**注册方式：**

```swift
actor PluginRegistry {
    static let shared = PluginRegistry()
    
    func register(id: String, order: Int = 0, factory: @escaping () -> any SuperPlugin)
    func buildAll() -> [any SuperPlugin]
    func getPlugin(id: String) -> (any SuperPlugin)?
}
```

### 3. 自动发现机制

系统使用 Objective-C Runtime 实现插件的自动发现和注册。

**实现原理：**

```swift
@objc protocol PluginRegistrant {
    static func register()
}

@MainActor
func autoRegisterPlugins() {
    // 扫描所有实现了 PluginRegistrant 协议的类
    // 自动调用其 register() 方法
}
```

**插件注册器示例：**

```swift
@objc(PluginNameRegistrant)
class PluginNameRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { 
            await PluginRegistry.shared.register(
                id: "PluginName", 
                order: 10  // 控制插件加载顺序
            ) { 
                PluginNamePlugin() 
            } 
        }
    }
}
```

### 4. PluginProvider（插件提供者）

`PluginProvider` 是主应用与插件系统交互的核心类，位于 `Core/Providers/PluginProvider.swift`。

**功能：**

- 自动发现并加载所有插件
- 收集插件提供的工具栏按钮、设置按钮、RootView
- 按位置（left/center/right）分类工具栏按钮
- 提供视图包装功能

**初始化流程：**

1. 调用 `autoRegisterPlugins()` 自动发现插件
2. 异步构建所有插件实例
3. 收集各插件提供的 UI 组件
4. 按位置分类工具栏按钮

**主要方法：**

- `getLeftButtons()` / `getCenterButtons()` / `getRightButtons()` - 获取分类的工具栏按钮
- `getSettingsButtons()` - 获取所有设置按钮
- `wrapContent(_:)` - 用插件的 RootView 包裹内容视图

## 插件集成点

### 1. RootView 集成

在 `Core/Bootstrap/RootView.swift` 中，应用使用 `PluginProvider` 包裹整个应用内容：

```swift
@StateObject private var p = PluginProvider()

// 包裹内容视图，应用所有插件的 RootView
p.wrapContent(
    content
        .environmentObject(p)
        // ... 其他环境变量
)
```

这样，插件可以通过 `provideRootView` 方法注入环境变量或包装视图层次结构。

### 2. TopBar 集成

在 `Core/View/Layout/TopBar.swift` 中，工具栏显示插件提供的按钮：

```swift
@EnvironmentObject var p: PluginProvider

HStack {
    p.getLeftButtons()    // 左侧按钮
    Spacer()
    p.getCenterButtons()  // 中心按钮
    Spacer()
    p.getRightButtons()   // 右侧按钮
}
```

### 3. 设置按钮集成

在 `Core/View/Buttons/BtnSettings.swift` 中，设置弹窗显示插件提供的设置按钮：

```swift
@EnvironmentObject private var p: PluginProvider

.popover(isPresented: $isPresented) {
    p.getSettingsButtons()  // 所有插件的设置按钮
}
```

### 4. 插件窗口集成

在 `Core/Bootstrap/TheApp.swift` 中，应用处理插件的独立窗口：

```swift
@StateObject private var pluginWindowManager = PluginWindowManager.shared

// 监听插件窗口打开通知
.onReceive(nc.publisher(for: .shouldOpenPluginWindow)) { notification in
    if let data = notification.object as? PluginWindowNotificationData {
        // 获取插件并打开其窗口内容
        if let plugin = await PluginRegistry.shared.getPlugin(id: data.pluginId),
           let windowContent = plugin.provideWindowContent() {
            pluginWindowManager.showWindow(with: windowContent)
            openWindow(id: "plugin-window")
        }
    }
}
```

## 插件开发指南

### 创建新插件

1. **创建插件文件夹**
   在 `Plugins` 目录下创建新的插件文件夹，例如 `MyPlugin/`

2. **实现插件类**
   创建一个 Actor 实现 `SuperPlugin` 协议：

```swift
actor MyPlugin: SuperPlugin {
    nonisolated let label: String = "MyPlugin"
    
    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: label, view: AnyView(MyToolbarButton()))
        ]
    }
    
    @MainActor
    func getTopBarPosition() -> TopBarPosition {
        return .left  // 或 .center, .right
    }
    
    // 可选：提供设置按钮
    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: "myPlugin", view: AnyView(MySettingsButton()))
        ]
    }
    
    // 可选：提供 RootView 包装器
    @MainActor
    func provideRootView<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> AnyView? {
        return AnyView(MyPluginRootView(content: content))
    }
    
    // 可选：提供独立窗口内容
    @MainActor
    func provideWindowContent() -> (any PluginWindowContent)? {
        return MyPluginWindowContent()
    }
}
```

3. **创建注册器**
   实现 `PluginRegistrant` 协议用于自动注册：

```swift
@objc(MyPluginRegistrant)
class MyPluginRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { 
            await PluginRegistry.shared.register(
                id: "MyPlugin", 
                order: 30  // 根据依赖关系设置合适的顺序
            ) { 
                MyPlugin() 
            } 
        }
    }
}
```

### 插件功能示例

#### 示例 1：简单工具栏按钮插件

```swift
actor SimpleButtonPlugin: SuperPlugin {
    nonisolated let label: String = "SimpleButton"
    
    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: label, view: AnyView(Button("点击我") {
                print("按钮被点击")
            }))
        ]
    }
}
```

#### 示例 2：设置按钮插件

```swift
actor SettingsPlugin: SuperPlugin {
    nonisolated let label: String = "Settings"
    
    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: "mySettings", view: AnyView(Button("我的设置") {
                // 打开设置
            }))
        ]
    }
}
```

#### 示例 3：提供 RootView 的插件

```swift
actor EnvironmentPlugin: SuperPlugin {
    nonisolated let label: String = "Environment"
    
    @MainActor
    func provideRootView<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> AnyView? {
        // 注入自定义环境变量
        return AnyView(
            content()
                .environmentObject(MyCustomEnvironment())
        )
    }
}
```

#### 示例 4：提供独立窗口的插件

```swift
actor WindowPlugin: SuperPlugin {
    nonisolated let label: String = "Window"
    
    @MainActor
    func provideWindowContent() -> (any PluginWindowContent)? {
        return MyWindowContent()
    }
}

// 实现 PluginWindowContent 协议
class MyWindowContent: PluginWindowContent {
    var windowTitle: String { "我的窗口" }
    
    @ViewBuilder
    func windowView() -> AnyView {
        AnyView(
            VStack {
                Text("窗口内容")
            }
        )
    }
}

// 打开窗口的方式
static func openMyWindow() {
    let data = PluginWindowNotificationData(pluginId: "Window")
    NotificationCenter.default.post(name: .shouldOpenPluginWindow, object: data)
}
```

## 现有插件列表

| 插件名称 | 功能 | 位置 | Order |
|---------|------|------|-------|
| StartButton | 启动按钮 | - | 10 |
| Switcher | 切换器 | left | 10 |
| Filter | 应用过滤器 | center | 20 |
| Store | 应用商店 | - | 40 |
| AboutButton | 关于按钮 | - | 50 |
| StopButton | 停止按钮 | - | - |
| QuitButton | 退出按钮 | - | - |
| GuideButton | 引导按钮 | - | - |
| SettingButton | 设置按钮 | - | - |
| InstallExtensionButton | 安装扩展按钮 | - | - |
| ClearLogsButton | 清除日志按钮 | - | - |
| DataFolderButton | 数据文件夹按钮 | - | - |
| DB | 数据库管理（Debug） | - | 20 |

## 架构优势

1. **模块化设计**：每个功能独立为插件，便于维护和测试
2. **自动发现**：基于 Runtime 的自动注册，无需手动配置
3. **类型安全**：使用 Swift 的协议和泛型保证类型安全
4. **并发安全**：使用 Actor 确保插件状态访问的线程安全
5. **灵活扩展**：插件可以以多种方式集成到应用中（按钮、窗口、RootView）
6. **排序控制**：通过 `order` 参数控制插件加载顺序，处理依赖关系

## 注意事项

1. **Actor 隔离**：插件类必须是 Actor，所有方法调用需要考虑并发上下文
2. **MainActor 要求**：UI 相关方法必须标记为 `@MainActor`
3. **注册顺序**：通过 `order` 参数控制插件初始化顺序，确保依赖关系正确
4. **资源清理**：如果插件持有资源，应在适当的时机清理（当前通过 `PluginProvider.cleanup()` 统一管理）
5. **插件 ID**：每个插件的 `label` 应该唯一，作为插件的标识符

