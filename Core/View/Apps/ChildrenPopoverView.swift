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
                ChildAppRow(app: childApp)
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
