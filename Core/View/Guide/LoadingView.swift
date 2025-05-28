import SwiftUI

/**
 * 加载视图
 * 用于在应用启动时展示加载状态
 */
struct LoadingView: View {
    @Binding var isPresented: Bool
    let message: String
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 24) {
            // 加载动画
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        scale = 1
                    }
                }
            
            // 加载提示
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 300, height: 200)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    LoadingView(isPresented: .constant(true), message: "正在启动...")
}