import MagicCore
import MagicUI
import MagicBackground
import SwiftUI

struct ExtGuide: View {
    @State private var isAnimating = false
    @State private var currentStep = 1

    var body: some View {
        VStack {
            // 标题
            titleView

            // 示意图
            heroView
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .frame(minWidth: 600)
    }

    private var heroView: some View {
        VStack {
            if currentStep == 1 {
                makeStepView(detail: step1Detail())
            } else if currentStep == 2 {
                makeStepView(detail: step2Detail())
            }
        }
        .cornerRadius(12)
        .padding()
    }

    private var titleView: some View {
        // 导航按钮
        HStack {
            Button(action: {
                withAnimation(.spring()) {
                    currentStep -= 1
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("上一步")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(currentStep == 1 ? .gray : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(currentStep == 1 ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .disabled(currentStep == 1)

            Spacer()

            VStack {
                Text("按下方示意图进行设置").font(.title)
                // 进度指示器
                HStack(spacing: 4) {
                    ForEach(1 ... 2, id: \.self) { step in
                        Circle()
                            .fill(step == currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(step == currentStep ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                                    .scaleEffect(1.5)
                            )
                    }
                }
            }

            Spacer()

            Button(action: {
                withAnimation(.spring()) {
                    currentStep += 1
                }
            }) {
                HStack(spacing: 8) {
                    Text("下一步")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(currentStep == 2 ? .gray : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(currentStep == 2 ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .disabled(currentStep == 2)
        }
        .padding(20)
        .background(.background)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    func step1Detail() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text("通用")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("管理Mac的整体设置和相关设置...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 8)

                Divider()
            }
            .padding()

            ScrollView {
                VStack(spacing: 0) {
                    settingRow(title: "关于本机", icon: "info.circle")
                    settingRow(title: "...", icon: "arrow.clockwise")
                    settingRow(title: "登录项与扩展", icon: "list.bullet", isHero: true)
                    settingRow(title: "...", icon: "person.2")
                }
            }
        }.background(MagicBackground.acousticMorning.opacity(0.2))
    }

    func step2Detail() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text("登录项与扩展")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("扩展可在 Mac 和 App 中添加额外功能...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 8)

                Divider()
            }
            .padding()

            ScrollView {
                VStack(spacing: 0) {
                    Group {
                        Text("扩展")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        extensionRow(
                            icon: "eye.fill",
                            iconColor: .gray,
                            title: "快速查看",
                            description: "ProvisioningProfileQuicklookExtension, TipsQuicklook"
                        )

                        extensionRow(
                            icon: "puzzlepiece.extension",
                            iconColor: .gray,
                            title: "网络扩展",
                            description: AppConfig.appName,
                            isHero: true
                        ).foregroundStyle(.red)

                        extensionRow(
                            icon: "doc.fill",
                            iconColor: .gray,
                            title: "...",
                            description: ""
                        )
                    }
                }
            }
        }
    }

    private func sidebarView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                VStack(alignment: .leading) {
                    Text("Coffic")
                        .font(.headline)
                    Text("CofficLab")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 16)
            .padding(.leading, 8)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Wi-Fi", systemImage: "wifi")
                        .opacity(0.6)
                    Label("网络", systemImage: "network")
                        .opacity(0.6)
                    Label("通用", systemImage: "gear")
                        .foregroundColor(.red.opacity(0.8))
                    Label("辅助功能", systemImage: "accessibility")
                        .opacity(0.6)
                    Label("聚焦", systemImage: "magnifyingglass")
                        .opacity(0.6)
                }.padding(.leading, 16)
                    .font(.title3)

                Spacer()
            }

            Spacer()
        }.frame(maxHeight: .infinity)
    }

    private func appRow(icon: String, iconColor: Color, title: String, description: String, isEnabled: Bool = false, showReload: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(iconColor)
                .padding(4)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if showReload {
                Image(systemName: "arrow.clockwise.circle")
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
            }

            Toggle("", isOn: .constant(isEnabled))
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func extensionRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        isHero: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Label {
                Text(title)
                    .font(.body)
            } icon: {
                Image(systemName: icon)
                    .frame(width: 20)
            }

            Spacer()

            Image(systemName: "info.circle")
                .overlay(isHero ?
                    makeHeroCircle()
                    : nil
                )
        }
        .opacity(isHero ? 1 : 0.6)
        .foregroundStyle(isHero ? .red : .gray)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func settingRow(title: String, icon: String, isHero: Bool = false) -> some View {
        HStack {
            Label {
                Text(title)
                    .font(.body)
            } icon: {
                Image(systemName: icon)
                    .frame(width: 20)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption).overlay(isHero ?
                    makeHeroCircle()
                    : nil
                )
        }
        .opacity(isHero ? 1 : 0.6)
        .foregroundStyle(isHero ? .red : .gray)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func makeHeroCircle() -> some View {
        Circle()
            .stroke(.orange, lineWidth: 2)
            .frame(width: 30, height: 30)
    }

    private func makeStepView(detail: some View) -> some View {
        HStack(spacing: 0) {
            sidebarView()
                .frame(width: 150)
                .background(MagicBackground.forest.opacity(0.5))

            VStack(alignment: .leading, spacing: 0) {
                detail
            }.background(MagicBackground.forest.opacity(0.2))
        }
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
