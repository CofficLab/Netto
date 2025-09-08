import MagicBackground
import MagicContainer
import MagicCore
import MagicUI
import SwiftUI

/// 第二个宣传图：一键禁止联网
struct AppStoreHeroBlock: View {
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 60) {
                Spacer()

                // 左侧
                VStack(alignment: .leading, spacing: 40) {
                    Spacer()

                    // 标题
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 48) {
                            Text("一键禁止联网")
                                .font(.system(size: 110, weight: .bold, design: .rounded))
                                .magicBluePurpleGradient()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("点击，即安心。")
                                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("无需设置，重要时刻，立刻静音网络。")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()
                }
                .frame(width: geo.size.width * 0.3)

                // 右侧：列表视图示意（在某个应用右侧显示“禁止联网”按钮）
                AppDemo(maxCount: 8, scaleLevel: 1.8, showBlockButtonAt: 4)
                    .background(.background.opacity(0.5))
                    .magicRoundedLarge()
                .inMagicVStackCenter()
                .inMagicHStackCenter()
                .frame(height: geo.size.height * 0.5)
                .frame(width: geo.size.width * 0.3)

                Spacer()
            }
            .inMagicBackgroundMint(0.9)
        }
        .overlay(alignment: .topLeading) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
                .padding(16)
        }
    }
}

// MARK: - Preview

#Preview("App Store Hero") {
    AppStoreHero()
        .inMagicContainer(.macBook13, scale: 0.3)
}

#Preview("App Store Hero - One Tap Block") {
    AppStoreHeroBlock()
        .inMagicContainer(.macBook13, scale: 0.3)
}


