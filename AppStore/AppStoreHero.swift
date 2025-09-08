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
                        featureRow("实时监控", "监控所有应用的网络连接", "eye.fill", .blue)
                        featureRow("智能过滤", "自动识别并阻止可疑连接", "shield.checkered", .green)
                        featureRow("流量分析", "详细的网络使用统计报告", "chart.bar.fill", .orange)
                        featureRow("隐私保护", "本地处理，保护用户隐私", "lock.shield.fill", .purple)
                    }

                    Spacer()
                }
                .frame(width: geo.size.width * 0.3)

                // 右侧：应用界面预览
                AppListDemo(maxCount: 15)
                    .inMagicBackgroundGalaxySpiral(0.9)
                    .inMagicVStackCenter()
                    .inMagicHStackCenter()
                    .frame(height: geo.size.height * 0.5)
                    .frame(width: geo.size.width * 0.3)

                Spacer()
            }
            .inMagicBackgroundForest(0.9)
        }
    }

    private func featureRow(_ title: String, _ description: String, _ iconName: String, _ color: Color) -> some View {
        HStack(spacing: 32) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(color)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.system(size: 32))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 30))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("App Store Hero") {
    AppStoreHero()
        .inMagicContainer(.macBook13, scale: 0.5)
}
