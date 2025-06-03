import AppKit
import Foundation
import SwiftUI

struct SmartApp: Identifiable, Sendable {
    // MARK: - Properties
    
    static let emoji = "🐒"

    var id: String
    var name: String

    /// 是否是系统应用
    var isSystemApp: Bool = false

    /// 是否是示例应用
    var isSample: Bool = false

    /// 是否是代理软件
    var isProxy: Bool = false

    /// the URL to the application's bundle
    var bundleURL: URL?

    var isNotSample: Bool { !isSample }
    var hasId: Bool { id.isNotEmpty }
    var hasNoId: Bool { id.isEmpty }
}

// MARK: - Instance Methods

extension SmartApp {
    /// 获取应用图标
    /// - Returns: 应用图标视图
    func getIcon() -> some View {
        // 优先检查系统应用图标
        if isSystemApp, let systemIcon = Self.getSystemAppIcon(self.id) {
            return AnyView(systemIcon)
        }
        
        // 检查运行中的应用图标
        if let runningApp = Self.getApp(self.id), let icon = runningApp.icon {
            return AnyView(Image(nsImage: icon))
        }
        
        return AnyView(SmartApp.getDefaultIcon())
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
                isProxy: Self.isProxyApp(runningApp),
                bundleURL: runningApp.bundleURL
            )
        }

        if let systemApp = Self.getSystemApp(id) {
            return systemApp
        }
        
        let unknownApp = Self.unknownApp(id)

        return unknownApp
    }

    /// 从NSRunningApplication创建SmartApp实例
    /// - Parameter app: 正在运行的应用程序对象
    /// - Returns: 对应的SmartApp实例
    static func fromRunningApp(_ app: NSRunningApplication) -> Self {
        return SmartApp(
            id: app.bundleIdentifier ?? "-",
            name: app.localizedName ?? "-",
            isProxy: Self.isProxyApp(app),
            bundleURL: app.bundleURL,
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
