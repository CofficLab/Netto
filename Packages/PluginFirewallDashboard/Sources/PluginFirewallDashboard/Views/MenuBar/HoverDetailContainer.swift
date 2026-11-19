import LumiUI
import SwiftUI

/// 行级 hover 子界面：悬停应用行后，在弹窗左侧打开独立 popover 展示详情。
///
/// 复用 Lumi 的 `HoverCoordinator`：同一时间只显示一个面板，指针离开后
/// 保留 0.3s 宽限，移入面板即可保持打开。展示前额外等待 120ms，
/// 避免鼠标掠过列表时连续闪出多个面板。
struct HoverDetailContainer<Content: View, Detail: View>: View {
    @ObservedObject private var coordinator = HoverCoordinator.shared
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isPresented = false
    @State private var isHovering = false
    @State private var showTask: Task<Void, Never>?

    private let id: String
    private let popoverWidth: CGFloat
    private let detailView: Detail
    private let content: Content

    init(
        id: String,
        popoverWidth: CGFloat = 360,
        @ViewBuilder detail: () -> Detail,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self.popoverWidth = popoverWidth
        self.detailView = detail()
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background {
                if isHovering || isPresented {
                    Rectangle()
                        .fill(Color(nsColor: .selectedContentBackgroundColor).opacity(0.18))
                }
            }
            .animation(
                LumiMotion.enabled(LumiMotion.hover, preference: motionPreference),
                value: isHovering || isPresented
            )
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    scheduleShow()
                } else {
                    showTask?.cancel()
                    showTask = nil
                    coordinator.onHover(id: id, isHovering: false)
                }
            }
            .popover(isPresented: $isPresented, arrowEdge: .leading) {
                detailView
                    .onHover { hovering in
                        if hovering {
                            coordinator.open(id: id)
                        } else {
                            coordinator.onHover(id: id, isHovering: false)
                        }
                    }
                    .padding(16)
                    .frame(width: popoverWidth)
                    .background(HoverPopoverWindowConfigurator())
            }
            .onReceive(coordinator.$visibleID) { visibleID in
                let shouldShow = visibleID == id
                guard isPresented != shouldShow else { return }
                withAnimation(
                    LumiMotion.enabled(LumiMotion.statusPresentation, preference: motionPreference)
                ) {
                    isPresented = shouldShow
                }
            }
            .onChange(of: isPresented) { _, newValue in
                if !newValue, coordinator.visibleID == id {
                    coordinator.close(id: id)
                }
            }
            .onDisappear {
                showTask?.cancel()
                showTask = nil
                if coordinator.visibleID == id {
                    coordinator.close(id: id)
                }
            }
    }

    private func scheduleShow() {
        showTask?.cancel()
        showTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            coordinator.open(id: id)
        }
    }
}

#if os(macOS)
/// 让详情 popover 在切换桌面与全屏时保持可见。
private struct HoverPopoverWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ConfigView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class ConfigView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.collectionBehavior.insert(.canJoinAllSpaces)
            window.collectionBehavior.insert(.fullScreenAuxiliary)
        }
    }
}
#endif
