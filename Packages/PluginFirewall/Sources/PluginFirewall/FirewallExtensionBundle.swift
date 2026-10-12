import Foundation

/// 系统扩展 Bundle 定位（迁移自旧 `ExtensionConfig`）。
///
/// 语义与原实现一致：从 App bundle 的 Contents/Library/SystemExtensions 下
/// 取第一个扩展 bundle。生产装配（宿主为 App bundle）下缺失即 fatalError
/// （启动期配置错误，与旧行为一致）；宿主非 App bundle（如 xctest runner）
/// 时没有系统扩展目录属预期环境，返回 nil 由适配器按"扩展缺失"降级。
enum FirewallExtensionBundle {
    /// 定位随 App 分发的系统扩展 Bundle。
    ///
    /// - Returns: 扩展 Bundle；仅当宿主非 App bundle 且目录缺失时返回 nil。
    static func load() -> Bundle? {
        let extensionsDirectoryURL = URL(
            fileURLWithPath: "Contents/Library/SystemExtensions",
            relativeTo: Bundle.main.bundleURL
        )
        let extensionURLs: [URL]
        do {
            extensionURLs = try FileManager.default.contentsOfDirectory(
                at: extensionsDirectoryURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
        } catch {
            // 生产 App 内：目录缺失 = 打包配置错误，启动期暴露。
            // 非 App 宿主（如 xctest runner）：无扩展目录属预期，降级运行。
            guard isAppHost else { return nil }
            fatalError("Failed to get the contents of \(extensionsDirectoryURL.absoluteString): \(error.localizedDescription)")
        }

        guard let extensionURL = extensionURLs.first else {
            guard isAppHost else { return nil }
            fatalError("Failed to find any system extensions")
        }

        guard let extensionBundle = Bundle(url: extensionURL) else {
            fatalError("Failed to create a bundle with URL \(extensionURL.absoluteString)")
        }

        return extensionBundle
    }

    /// 宿主是否为 App bundle（.app）。xctest runner 等非 App 宿主不视为
    /// 打包配置错误。
    private static var isAppHost: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }
}
