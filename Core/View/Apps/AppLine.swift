import MagicCore
import OSLog
import SwiftUI

struct AppLine: View, SuperEvent {
    @EnvironmentObject var data: DataProvider

    var app: SmartApp

    @State var hovering: Bool = false
    @State var shouldAllow: Bool = true
    @State var showCopyMessage: Bool = false
    @State var showChildrenPopover: Bool = false
    @State var popoverHovering: Bool = false

    init(app: SmartApp) {
        self.app = app
    }

    var body: some View {
        AppInfo(
            app: app,
            iconSize: 40,
            isCompact: false,
            shouldAllow: $shouldAllow,
            hovering: $hovering,
            showCopyMessage: $showCopyMessage
        )
        .onHover(perform: { hovering in
            self.hovering = hovering
            // 当有children且hover时显示popover
            if !app.children.isEmpty {
                if hovering {
                    showChildrenPopover = true
                } else {
                    // 延迟关闭，给用户时间移动到popover
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !popoverHovering {
                            showChildrenPopover = false
                        }
                    }
                }
            }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: onAppear)
        .popover(isPresented: $showChildrenPopover, arrowEdge: .trailing) {
            ChildrenPopoverView(
                children: app.children,
                popoverHovering: $popoverHovering,
                showChildrenPopover: $showChildrenPopover
            )
        }
    }
}

// MARK: - 事件

extension AppLine {
    /// 页面出现时的处理
    func onAppear() {
        self.shouldAllow = data.shouldAllow(app.id)
    }
}

// MARK: - 子应用弹出视图组件

struct ChildrenPopoverView: View {
    @EnvironmentObject var data: DataProvider
    
    var children: [SmartApp]
    @Binding var popoverHovering: Bool
    @Binding var showChildrenPopover: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Child Applications")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(children) { childApp in
                ChildAppRow(app: childApp)
            }
        }
        .padding(12)
        .frame(minWidth: 300, maxWidth: 400)
        .onHover { hovering in
            popoverHovering = hovering
            // 当鼠标离开popover时，延迟关闭
            if !hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !popoverHovering {
                        showChildrenPopover = false
                    }
                }
            }
        }
    }
}
#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
