import MagicCore
import SwiftUI

struct ExtensionNotReady: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 48))
                .symbolEffect(.bounce.down, value: isAnimating)
                .foregroundStyle(.yellow)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            Text("需要配置系统扩展")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

            HStack {
                MagicButton(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.system_extension.network_extension.extension-point") {
                        NSWorkspace.shared.open(url)
                    }
                })
                .magicIcon(.iconSettings)
                .magicTitle("打开系统设置")
                .magicSize(.auto)
                .frame(width: 150)
                .frame(height: 50)
                .scaleEffect(isAnimating ? 1 : 0.9)
                
//                MagicButton(title: "学习如何设置")
//                    .magicSize(.auto)
//                    .magicIcon(.iconStar)
//                    .magicPopover(content: {
//                        ExtGuide()
//                    })
//                    .frame(width: 150)
//                    .frame(height: 50)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .frame(minWidth: 400)
    }
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}

#Preview {
    RootView {
        ExtensionNotReady()
    }
    .frame(height: 800)
}
