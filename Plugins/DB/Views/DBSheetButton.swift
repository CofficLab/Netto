import MagicCore
import MagicUI
import SwiftUI

struct DBSheetButton: View {
    @State private var showSheet: Bool = false

    var body: some View {
        MagicButton.simple(action: {
            showSheet = true
        })
        .magicIcon(.iconDebug)
        .magicTitle("查看数据库")
        .magicSize(.auto)
        .frame(width: 150)
        .frame(height: 50)
        .sheet(isPresented: $showSheet) {
            DBMainSheet()
                .frame(width: 900, height: 700)
        }
    }
}

private struct DBMainSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("数据库")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding()

            Divider()

            DBEventView()
        }
    }
}

#Preview {
    RootView {
        DBSheetButton()
    }
}

#Preview("APP") {
    ContentView().inRootView()
}


