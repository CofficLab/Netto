import SwiftUI

/// 应用图标视图：系统应用使用内置图标，其余应用从 `AppCatalog` 的缓存取图。
///
/// 目录由界面根视图注入环境；缺失（例如脱离上下文的预览）时回退默认图标，
/// 不触发 `NSWorkspace` 扫描。
struct AppIcon: View {
    @Environment(\.appCatalog) private var catalog

    let app: SmartApp

    var body: some View {
        Group {
            if app.isSystemApp, let systemIcon = SmartApp.getSystemAppIcon(app.id) {
                systemIcon
            } else if let image = catalog?.icon(for: app.id) {
                Image(nsImage: image)
            } else {
                SmartApp.getDefaultIcon()
            }
        }
    }
}