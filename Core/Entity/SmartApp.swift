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
}

// MARK: - Initialization

extension SmartApp {
    /// 使用ID和名称初始化SmartApp
    /// - Parameters:
    ///   - id: 应用程序唯一标识符
    ///   - name: 应用程序名称
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    /// 使用ID、名称和可选图标初始化SmartApp
    /// - Parameters:
    ///   - id: 应用程序唯一标识符
    ///   - name: 应用程序名称
    ///   - icon: 可选的NSImage图标
    init(id: String, name: String, icon: NSImage? = nil) {
        self.id = id
        self.name = name
        if let i = icon {
            self.icon = AnyView(Image(nsImage: i).resizable())
        }
    }

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
                icon: runningApp.icon ?? NSImage()
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
            icon: app.icon
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

// MARK: - Helpers

extension SmartApp {
    /// 获取当前系统中所有正在运行的应用程序列表
    ///
    /// - Returns: 包含所有正在运行的应用程序的数组
    private static func getRunningAppList() -> [NSRunningApplication] {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications

        return runningApps
    }

    /// 根据标识符查找正在运行的应用程序
    ///
    /// 该方法通过提供的标识符在当前运行的应用程序中查找匹配的应用程序。
    /// 查找规则如下：
    /// - 如果标识符以点(.)开头，会自动移除开头的点
    /// - 匹配规则（满足任一即匹配成功）：
    ///   - 完全匹配应用程序的bundle identifier
    ///   - 完全匹配原始输入的标识符
    ///   - 输入的标识符包含应用程序的bundle identifier
    ///   - 输入的标识符以应用程序的bundle identifier结尾
    ///
    /// - Parameter id: 要查找的应用程序标识符
    /// - Returns: 找到的应用程序实例，如果未找到则返回nil
    private static func getApp(_ id: String) -> NSRunningApplication? {
        var workId = id

        if workId.hasPrefix(".") {
            workId = String(workId.dropFirst())
        }

        let apps = getRunningAppList()

        for app in apps {
            let bundleIdentifier = app.bundleIdentifier

            guard let bundleIdentifier = bundleIdentifier else {
                continue
            }

            if
                bundleIdentifier == workId ||
                bundleIdentifier == id ||
                id.contains(bundleIdentifier) ||
                id.hasSuffix(bundleIdentifier) {
                return app
            }
        }

        return nil
    }
}

// MAKR: - Unknown App

extension SmartApp {
    static func unknownApp(_ id: String) -> SmartApp {
        SmartApp(id: id, name: "未知", icon: ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.cyan]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            Image(systemName: "app")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .foregroundColor(.white)
        }
        .frame(width: 34, height: 34)
        .clipped())
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 800)
}
