import SwiftUI

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
                AppInfo(
                    app: childApp,
                    iconSize: 24,
                    nameFont: .subheadline,
                    idFont: .caption2,
                    countFont: .caption2,
                    isCompact: true,
                    copyMessageDuration: 1.5,
                    copyMessageText: "App ID 已复制"
                )
            }
        }
        .padding(12)
        .onHover { hovering in
            popoverHovering = hovering
            if !hovering {
                if !popoverHovering {
                    showChildrenPopover = false
                }
            }
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
