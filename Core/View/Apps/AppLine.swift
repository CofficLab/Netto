import MagicCore
import OSLog
import SwiftUI

struct AppLine: View, SuperEvent {
    @EnvironmentObject var data: DataProvider

    var app: SmartApp

    @State var hovering: Bool = false
    @State var showChildrenPopover: Bool = false
    @State var popoverHovering: Bool = false

    init(app: SmartApp) {
        self.app = app
    }

    var body: some View {
        AppInfo(
            app: app,
            iconSize: 40,
            isCompact: false
        )
        .onHover(perform: { hovering in
            self.hovering = hovering
            // 当hover时显示popover
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
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .popover(isPresented: $showChildrenPopover, arrowEdge: .trailing) {
            AppDetail(
                popoverHovering: $popoverHovering,
                showChildrenPopover: $showChildrenPopover,
                app: app,
            ).frame(width: 600)
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
