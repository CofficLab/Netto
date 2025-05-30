import MagicCore
import OSLog
import SwiftUI



// MARK: - 应用行组件

struct AppLine: View, SuperEvent {
    @EnvironmentObject var data: DataProvider

    var app: SmartApp

    @State var hovering: Bool = false
    @State var shouldAllow: Bool = true
    @State var showCopyMessage: Bool = false
    @State var showChildrenPopover: Bool = false

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
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(Group {
            if !shouldAllow {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red.opacity(0.2),
                        Color.red.opacity(0.05),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if hovering {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.mint.opacity(0.2),
                        Color.mint.opacity(0.05),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        })
        .scaleEffect(hovering ? 1 : 1)
        .onHover(perform: { hovering in
            self.hovering = hovering
            // 当有children且hover时显示popover
            if !app.children.isEmpty {
                showChildrenPopover = hovering
            }
        })
        .frame(height: 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: onAppear)
        .popover(isPresented: $showChildrenPopover, arrowEdge: .trailing) {
            ChildrenPopoverView(children: app.children)
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
    }
}
#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
