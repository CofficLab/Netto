import MagicBackground
import MagicContainer
import MagicCore
import MagicUI
import SwiftUI

/// 第三个宣传图：常驻菜单栏（Menu Bar）
struct AppStoreHeroMenuBar: View {
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 80) {
                Spacer()

                // 左侧：标题与文案（Apple 风格）
                VStack(alignment: .leading, spacing: 56) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 56) {
                            Text("常驻菜单栏")
                                .font(.system(size: 150, weight: .bold, design: .rounded))
                                .magicBluePurpleGradient()

                            VStack(alignment: .leading, spacing: 14) {
                                Text("轻盈，不打扰。")
                                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("就在屏幕顶端，抬眼可见的安心。")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()
                }
                .frame(width: geo.size.width * 0.36)

                // 右侧：菜单栏与状态项静态示意
                MenuBarStaticMock()
                    .background(.background.opacity(0.5))
                    .magicRoundedLarge()
                .inMagicVStackCenter()
                .inMagicHStackCenter()
                .frame(height: geo.size.height * 0.7)
                .frame(width: geo.size.width * 0.42)

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

private struct MenuBarStaticMock: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部菜单栏条
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: 96)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )

                HStack(spacing: 24) {
                    // 左侧 Apple 菜单等（占位）
                    HStack(spacing: 10) {
                        Text("")
                        Text("File")
                        Text("Edit")
                        Text("View")
                        Text("Window")
                        Text("Help")
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 22, weight: .regular))

                    Spacer()

                    // 右侧状态项（包括我们的 App 图标）
                    HStack(spacing: 14) {
                        Image(systemName: "wifi")
                        Image(systemName: "bolt.fill")
                        Image(systemName: "moon")

                        // 我们的 App 图标（高亮）
                        HStack(spacing: 6) {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundColor(.white)
                            Text("Netto")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.accentColor)
                        )
                    }
                    .font(.system(size: 24, weight: .medium))
                }
                .padding(.horizontal, 16)
            }

            // 下方弹出面板（静态）
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Text("Netto")
                        .font(.system(size: 34, weight: .semibold))
                    Spacer()
                    // 模拟一个禁用按钮（静态）
                    HStack(spacing: 12) {
                        Image(systemName: "nosign")
                            .foregroundColor(.white)
                        Text("禁止联网")
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red)
                    )
                }

                Divider()

                // 列表中展示数个应用的快速状态（静态）
                VStack(spacing: 20) {
                    ForEach(0..<3) { i in
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.secondary.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(Image(systemName: "app.fill").font(.system(size: 22)).foregroundStyle(.secondary))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("示例应用 \(i+1)")
                                    .font(.system(size: 20))
                                Text("com.example.app\(i+1)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // 右侧状态标签
                            Text(i == 0 ? "已禁止" : "允许")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(i == 0 ? .white : .secondary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(i == 0 ? Color.red : Color.secondary.opacity(0.15))
                                )
                        }
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
            )
            .padding(.top, 18)

            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Preview

#Preview("App Store Hero") {
    AppStoreHero()
        .inMagicContainer(.macBook13, scale: 0.4)
}

#Preview("App Store Hero - One Tap Block") {
    AppStoreHeroBlock()
        .inMagicContainer(.macBook13, scale: 0.4)
}

#Preview("App Store Hero - Menu Bar") {
    AppStoreHeroMenuBar()
        .inMagicContainer(.macBook13, scale: 0.4)
}


