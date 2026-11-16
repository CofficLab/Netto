import LumiUI
import SwiftUI

/// 原生渐变背景集合（原生实现，替代 MagicBackground）
enum AppBackground {
    /// 海洋色垂直渐变
    static var ocean: some View {
        LinearGradient(
            colors: [
                Color(hex: "1CB5E0").opacity(0.7),
                Color(hex: "000046").opacity(0.7),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }

    /// 极光效果背景
    static var aurora: some View {
        ZStack {
            Color.black.opacity(0.8)

            GeometryReader { geometry in
                ForEach(0 ..< 3) { index in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.4))
                        path.addCurve(
                            to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.4),
                            control1: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.3),
                            control2: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.5)
                        )
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "00ff87").opacity(0.3),
                                Color(hex: "60efff").opacity(0.3),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 50
                    )
                    .blur(radius: 30)
                    .offset(y: CGFloat(index) * 30)
                }
            }
        }
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}
