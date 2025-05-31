import AppKit
import Foundation
import SwiftUI

struct SmartApp: Identifiable, Sendable {
    // MARK: - Properties
    
    static let emoji = "🐒"

    var id: String
    var name: String
    var events: [FirewallEvent] = []
    var isSystemApp: Bool = false
    var isSample: Bool = false
    var children: [SmartApp] = []

    var isNotSample: Bool { !isSample }
    var hasId: Bool { id.isNotEmpty }
    var hasNoId: Bool { id.isEmpty }
}

// MARK: - Initialization

extension SmartApp {
    /// 使用ID、名称和SwiftUI视图图标初始化SmartApp
    /// - Parameters:
    ///   - id: 应用程序唯一标识符
    ///   - name: 应用程序名称
    ///   - icon: SwiftUI视图作为图标
    ///   - isSystemApp: 是否为系统应用程序（默认值为false）
    ///   - isSample: 是否为示例应用程序（默认值为false）
    init(
        id: String, 
        name: String, 
        icon: some View, 
        isSystemApp: Bool = false, 
        isSample: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isSystemApp = isSystemApp
        self.isSample = isSample
    }
}

// MARK: - Instance Methods

extension SmartApp {
    func getIcon() -> some View {
        if let runningApp = Self.getApp(self.id), let icon = runningApp.icon {
            return AnyView(Image(nsImage: icon))
        }
        
        return AnyView(SmartApp.getDefaultIcon())
    }
    
    /// 向应用添加防火墙事件
    /// - Parameter e: 要添加的防火墙事件
    /// - Returns: 包含新事件的SmartApp副本
    func appendEvent(_ e: FirewallEvent) -> Self {
        var cloned = self
        cloned.events.append(e)

        return cloned
    }

    /// 向应用添加多个防火墙事件
    /// - Parameter events: 要添加的防火墙事件数组
    /// - Returns: 包含新事件的SmartApp副本
    func appendEvents(_ events: [FirewallEvent]) -> Self {
        var cloned = self
        cloned.events.append(contentsOf: events)
        return cloned
    }

    /// 检查应用程序是否包含子应用程序
    /// - Parameter id: 子应用程序ID
    /// - Returns: 如果应用程序包含子应用程序，则返回true；否则返回false
    func containsChild(_ id: String) -> Bool {
        children.contains(where: { $0.id == id })
    }

    /// 检查应用程序是否包含子应用程序
    /// - Parameter id: 子应用程序ID
    /// - Returns: 如果应用程序包含子应用程序，则返回true；否则返回false
    func getChild(_ id: String) -> SmartApp? {
        children.first(where: { $0.id == id })
    }

    /// 删除子应用程序
    /// - Parameter id: 子应用程序ID
    /// - Returns: 包含删除子应用程序的SmartApp副本
    func removeChild(_ id: String) -> Self {
        var cloned = self
        cloned.children.removeAll(where: { $0.id == id })
        return cloned
    }
}

// MARK: - Factory Methods

extension SmartApp {
    /// 根据应用ID创建SmartApp实例
    /// - Parameter id: 应用程序ID
    /// - Returns: 对应的SmartApp实例
    static func fromId(_ id: String) -> Self {
        if let runningApp = getApp(id) {
            return SmartApp(
                id: runningApp.bundleIdentifier ?? "",
                name: runningApp.localizedName ?? "",
                icon: AnyView(Image(nsImage: runningApp.icon ?? NSImage()).resizable())
            )
        }

        if let systemApp = Self.getSystemApp(id) {
            return systemApp
        }
        
        let unknownApp = Self.unknownApp(id)

        // 尝试寻找Package
        if let packageApp = Self.getPackage(id) {
            return SmartApp(
                id: packageApp.bundleIdentifier ?? "",
                name: packageApp.localizedName ?? "",
                icon: AnyView(Image(nsImage: packageApp.icon ?? NSImage()).resizable())
            ).addChild(unknownApp)
        }

        return unknownApp
    }

    /// 从NSRunningApplication创建SmartApp实例
    /// - Parameter app: 正在运行的应用程序对象
    /// - Returns: 对应的SmartApp实例
    static func fromRunningApp(_ app: NSRunningApplication) -> Self {
        return SmartApp(
            id: app.bundleIdentifier ?? "-",
            name: app.localizedName ?? "-",
            icon: AnyView(Image(nsImage: app.icon ?? NSImage()).resizable())
        )
    }
}

// MARK: - Static Properties

extension SmartApp {
    /// 当前运行的应用程序列表（去重后）
    static let appList: [SmartApp] = getRunningAppList().map {
        Self.fromRunningApp($0)
    }.reduce(into: []) { result, app in
        if !result.contains(where: { $0.id == app.id }) {
            result.append(app)
        }
    }
}

// MARK: - Modifiers

extension SmartApp {
    /// 为应用程序添加子应用程序
    /// - Parameter child: 子应用程序
    /// - Returns: 包含子应用程序的SmartApp副本
    func addChild(_ child: SmartApp) -> Self {
        // 如果已经存在了，则将child中的events添加到当前应用程序的events中
        if let existingChild = self.getChild(child.id) {
            let cloned = self.removeChild(child.id)
            return cloned.addChild(existingChild.appendEvents(child.events))
        }
        
        // 如果不存在，则直接添加
        var cloned = self
        cloned.children.append(child)
        return cloned
    }

    /// 为应用程序添加多个子应用程序
    /// - Parameter children: 子应用程序数组
    /// - Returns: 包含子应用程序的SmartApp副本
    func addChildren(_ children: [SmartApp]) -> Self {
        children.reduce(self) { result, child in
            result.addChild(child)
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 800)
}
