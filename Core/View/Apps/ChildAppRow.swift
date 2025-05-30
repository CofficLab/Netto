import SwiftUI

struct ChildAppRow: View {
    @EnvironmentObject var data: DataProvider
    
    var app: SmartApp
    
    @State var hovering: Bool = false
    @State var showCopyMessage: Bool = false
    
    var body: some View {
        AppInfo(
            app: app,
            iconSize: 24,
            nameFont: .subheadline,
            idFont: .caption2,
            countFont: .caption2,
            isCompact: true,
            copyMessageDuration: 1.5,
            copyMessageText: "App ID 已复制",
            hovering: $hovering,
            showCopyMessage: $showCopyMessage
        )
        .onHover { hovering in
            self.hovering = hovering
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
