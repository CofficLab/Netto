import SwiftUI

struct ChildAppRow: View {
    @EnvironmentObject var data: DataProvider
    
    var app: SmartApp
    
    @State var hovering: Bool = false
    @State var shouldAllow: Bool = true
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
            shouldAllow: $shouldAllow,
            hovering: $hovering,
            showCopyMessage: $showCopyMessage
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(hovering ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            self.hovering = hovering
        }
        .onAppear {
            self.shouldAllow = data.shouldAllow(app.id)
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
