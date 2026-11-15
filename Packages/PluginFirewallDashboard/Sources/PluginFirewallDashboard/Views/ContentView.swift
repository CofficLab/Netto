import SwiftUI

/// 主窗口内容区 —— 工具栏由宿主的共享根视图（`ProviderToolbar`）提供，
/// 这里只渲染应用列表。内容区不再包一层 `netto.dashboard` 标识：只剩单个
/// 子视图时 SwiftUI 会把容器标识覆盖到列表上，导致 `netto.apps.list` 丢失。
public struct ContentView: View {
    public init() {}

    public var body: some View {
        AppList()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("")
    }
}

#Preview("APP") {
    DashboardPreviewHost { ContentView() }
    .frame(width: 700)
    .frame(height: 800)
}
