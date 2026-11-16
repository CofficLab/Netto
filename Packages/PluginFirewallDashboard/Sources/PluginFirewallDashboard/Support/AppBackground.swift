import LumiUI
import SwiftUI

/// 原生渐变背景集合（原生实现，替代 MagicBackground）
enum AppBackground {
    /// 樱桃色对角渐变
    static var cherry: some View {
        LinearGradient(
            colors: [
                Color(hex: "EB3349").opacity(0.7),
                Color(hex: "F45C43").opacity(0.7),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }

    /// 青色垂直渐变
    static var colorTeal: some View {
        LinearGradient(
            colors: [
                Color(hex: "008080").opacity(0.7),
                Color(hex: "006666").opacity(0.7),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }

    /// 森林色对角渐变
    static var forest: some View {
        LinearGradient(
            colors: [
                Color(hex: "134E5E").opacity(0.7),
                Color(hex: "71B280").opacity(0.7),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}
