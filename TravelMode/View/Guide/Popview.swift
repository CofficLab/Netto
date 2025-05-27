import MagicCore
import SwiftUI

struct Popview<Content: View>: View {
    @State private var isAnimating = false
    @State private var isHovered = false
    @State private var isPressed = false
    
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
                .symbolEffect(.pulse, value: isHovered)
                .foregroundStyle(iconColor)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .scaleEffect(isPressed ? 0.8 : 1)
            
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
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    RootView {
        ExtensionNotReady()
    }
    .frame(height: 500)
}
