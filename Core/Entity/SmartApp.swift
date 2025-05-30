import AppKit
import Foundation
import SwiftUI

struct SmartApp: Identifiable {
    // MARK: - Properties

    var id: String
    var name: String
    var icon: AnyView? = nil
    var events: [FirewallEvent] = []
    var isSystemApp: Bool = false
    var isSample: Bool = false

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
    init(id: String, name: String, icon: some View, isSystemApp: Bool = false, isSample: Bool = false) {
        self.id = id
        self.name = name
        self.icon = AnyView(icon)
        self.isSystemApp = isSystemApp
        self.isSample = isSample
    }
}

// MARK: - Instance Methods

extension SmartApp {
    /// 向应用添加防火墙事件
    /// - Parameter e: 要添加的防火墙事件
    /// - Returns: 包含新事件的SmartApp副本
    func appendEvent(_ e: FirewallEvent) -> Self {
        var cloned = self
        cloned.events.append(e)

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

        return Self.unknownApp(id)
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

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 800)
}
