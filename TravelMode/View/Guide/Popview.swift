import MagicCore
import SwiftUI

struct Popview<Content: View>: View {
    @State private var isAnimating = false
    
    let iconName: String
    let title: String
    let iconColor: Color
    let content: Content
    
    init(
        iconName: String,
        title: String,
        iconColor: Color = .yellow,
        @ViewBuilder content: () -> Content
    ) {
        self.iconName = iconName
        self.title = title
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .symbolEffect(.bounce.down, value: isAnimating)
                .foregroundStyle(iconColor)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            Text(title)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

            content
                .scaleEffect(isAnimating ? 1 : 0.9)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .frame(minWidth: 400)
        .frame(minHeight: 500)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    Popview(
        iconName: "exclamationmark.shield",
        title: "需要配置系统扩展"
    ) {
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
        }
    }
    .padding()
    .frame(width: 400)
}
