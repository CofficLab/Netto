import MagicBackground
import MagicContainer
import MagicCore
import MagicUI
import SwiftUI

/**
 * App Store 主页面
 * 展示应用核心价值和主要功能
 */
struct AppStoreHero: View {
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 60) {
                Spacer()

                // 左侧：应用介绍
                VStack(alignment: .leading, spacing: 40) {
                    Spacer()

                    // Logo 和标题
                    VStack(alignment: .leading, spacing: 24) {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)

                        VStack(alignment: .leading, spacing: 48) {
                            Text(AppConfig.appName)
                                .font(.system(size: 120, weight: .bold, design: .rounded))
                                .magicBluePurpleGradient()

                            Text("网络监控工具")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                        }
                    }

                    // 主要功能
                    VStack(alignment: .leading, spacing: 32) {
                        MagicFeature(title: "实时监控", description:"监控所有应用的网络连接", iconName: "eye.fill",color: .blue)
                        MagicFeature(title: "智能过滤", description: "自动识别并阻止可疑连接", iconName: "shield.checkered", color: .green)
                        MagicFeature(title: "流量分析", description: "详细的网络使用统计报告", iconName: "chart.bar.fill", color: .orange)
                        MagicFeature(title: "隐私保护", description: "本地处理，保护用户隐私", iconName: "lock.shield.fill", color: .purple)
                    }

                    Spacer()
                }
                .frame(width: geo.size.width * 0.3)

                // 右侧：应用界面预览
                AppListDemo(maxCount: 10, scaleLevel: 2)
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
    }
}

// MARK: - Preview

#Preview("App Store Hero") {
    AppStoreHero()
        .inMagicContainer(.macBook13, scale: 0.3)
}
