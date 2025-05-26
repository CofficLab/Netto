import MagicCore
import SwiftUI

struct ExtensionNotReady: View {
    @State private var isAnimating = false
    @State private var currentStep = 1

    var body: some View {
        VStack {
            // 步骤
            stepView

            // 示意图
            heroView
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }

    private var heroView: some View {
        VStack {
            if currentStep == 1 {
                step1()
            } else if currentStep == 2 {
                step2()
            }
        }
        .cornerRadius(12)
        .padding()
    }

    private var stepView: some View {
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
        .shadow(color: Color.orange.opacity(0.1), radius: 10, x: 0, y: 2)
        .padding(.horizontal)
    }

    func step1() -> some View {
        NavigationSplitView {
            sidebarView()
        } detail: {
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
                            Text("管理Mac的整体设置和相关设置，视觉控件更新，设置语言，磁盘访问等。")
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
                        settingRow(title: "软件更新", icon: "arrow.clockwise")
                        settingRow(title: "存储空间", icon: "externaldrive")
                        settingRow(title: "登录项与扩展", icon: "list.bullet", isHero: true)
                        settingRow(title: "共享", icon: "person.2")
                        settingRow(title: "启动磁盘", icon: "externaldrive.fill")
                    }
                }
            }.background(MagicBackground.forest.opacity(0.2))
        }
    }

    func step2() -> some View {
        NavigationSplitView {
            sidebarView()
        } detail: {
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
                            Text("扩展可在 Mac 和 App 中添加额外功能。部分扩展需要您在启用后才能运行。")
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
                                description: "TravelMode",
                                isHero: true
                            ).foregroundStyle(.red)

                            extensionRow(
                                icon: "doc.fill",
                                iconColor: .gray,
                                title: "文件提供程序",
                                description: "OSpace, WPS Office, 百度网盘, 豆包"
                            )

                            extensionRow(
                                icon: "square.fill",
                                iconColor: .gray,
                                title: "文件系统扩展",
                                description: "msdos, exfat"
                            )
                        }
                    }
                }
            }
        }.background(MagicBackground.forest.opacity(0.3))
    }

    private func sidebarView() -> some View {
        List {
            Section {
                NavigationLink(destination: Text("Apple ID")) {
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
                    .padding(.vertical, 4)
                }
            }

            Section {
                Label("Wi-Fi", systemImage: "wifi")
                    .opacity(0.6)
                Label("网络", systemImage: "network")
                    .opacity(0.6)
            }

            Section {
                Label("通用", systemImage: "gear")
                    .foregroundColor(.red)
                Label("辅助功能", systemImage: "accessibility")
                    .opacity(0.6)
                Label("聚焦", systemImage: "magnifyingglass")
                    .opacity(0.6)
            }
        }
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
            Image(systemName: icon)
                .resizable()
                .frame(width: 20, height: 20)
                .padding(4)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
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
