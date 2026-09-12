import Foundation

/// 系统扩展 Bundle 定位（迁移自旧 `ExtensionConfig`）。
///
/// 语义与原实现一致：从 App bundle 的 Contents/Library/SystemExtensions 下
/// 取第一个扩展 bundle；缺失即 fatalError（启动期配置错误，与旧行为一致）。
enum FirewallExtensionBundle {
    /// 定位随 App 分发的系统扩展 Bundle。
    static func load() -> Bundle {
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
            fatalError("Failed to get the contents of \(extensionsDirectoryURL.absoluteString): \(error.localizedDescription)")
        }

        guard let extensionURL = extensionURLs.first else {
            fatalError("Failed to find any system extensions")
        }

        guard let extensionBundle = Bundle(url: extensionURL) else {
            fatalError("Failed to create a bundle with URL \(extensionURL.absoluteString)")
        }

        return extensionBundle
    }
}
