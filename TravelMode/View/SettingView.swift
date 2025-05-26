import SwiftUI

struct SettingView: View {
    @State private var currentStep = 1

    var body: some View {
        VStack {
            // 步骤
            HStack {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    HStack {
                        Text("上一步")
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                }.disabled(currentStep == 1)

                Spacer()

                Text("步骤 \(currentStep)/2")
                    .foregroundColor(.gray)

                Spacer()

                Button(action: {
                    withAnimation {
                        currentStep += 1
                    }
                }) {
                    HStack {
                        Text("下一步")
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                }.disabled(currentStep == 2)
            }
            .background(.orange.opacity(0.05))
            .cornerRadius(8)
            .padding()

            // 示意图
            if currentStep == 1 {
                step1()
                    .transition(.opacity)
            } else if currentStep == 2 {
                step2()
                    .transition(.opacity)
            }
        }
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
                        settingRow(title: "AppleCare与保修", icon: "applelogo")
                        settingRow(title: "隐空控制与接力", icon: "hand.raised")
                        settingRow(title: "登录项与扩展", icon: "list.bullet")
                            .foregroundColor(.red)
                        settingRow(title: "共享", icon: "person.2")
                        settingRow(title: "启动磁盘", icon: "externaldrive.fill")
                        settingRow(title: "日期与时间", icon: "clock")
                        settingRow(title: "时间机器", icon: "clock.arrow.circlepath")
                        settingRow(title: "语言与地区", icon: "globe")
                        settingRow(title: "自动填充与密码", icon: "key")
                        settingRow(title: "设备管理", icon: "slider.horizontal.3")
                        settingRow(title: "传输或还原", icon: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                            Text("登录项")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            appRow(
                                icon: "circle.fill",
                                iconColor: .purple,
                                title: "OrbStack",
                                description: "1个项目 · 1个项目影响所有用户",
                                isEnabled: true
                            )

                            appRow(
                                icon: "square.fill",
                                iconColor: .black,
                                title: "redis-server",
                                description: "项目来自自动脚本的开发者。",
                                isEnabled: true,
                                showReload: true
                            )

                            appRow(
                                icon: "circle.fill",
                                iconColor: .yellow,
                                title: "Tencent Lemon",
                                description: "5个项目 · 3个项目影响所有用户",
                                isEnabled: true
                            )

                            appRow(
                                icon: "square.fill",
                                iconColor: .cyan,
                                title: "won fen",
                                description: "1个项目",
                                isEnabled: true
                            )
                        }

                        Group {
                            Text("扩展")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            extensionRow(
                                icon: "square.fill",
                                iconColor: .gray,
                                title: "Xcode Source Editor",
                                description: "Soothe, XCFormat"
                            )

                            extensionRow(
                                icon: "square.fill",
                                iconColor: .gray,
                                title: "共享",
                                description: "FMPhotoShareExtension, Instruments及其他20个"
                            )

                            extensionRow(
                                icon: "eye.fill",
                                iconColor: .gray,
                                title: "快速查看",
                                description: "ProvisioningProfileQuicklookExtension, TipsQuicklook"
                            )

                            extensionRow(
                                icon: "puzzlepiece.extension",
                                iconColor: .red,
                                title: "网络扩展",
                                description: "输记"
                            )

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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
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
                            Text("林宇")
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
                NavigationLink(destination: Text("Wi-Fi")) {
                    Label("Wi-Fi", systemImage: "wifi")
                }
                NavigationLink(destination: Text("网络")) {
                    Label("网络", systemImage: "network")
                }
            }

            Section {
                NavigationLink(destination: Text("通用")) {
                    Label("通用", systemImage: "gear")
                        .foregroundColor(.red)
                }
                NavigationLink(destination: Text("辅助功能")) {
                    Label("辅助功能", systemImage: "accessibility")
                }
                NavigationLink(destination: Text("聚焦")) {
                    Label("聚焦", systemImage: "magnifyingglass")
                }
            }
        }
        .navigationTitle("设置")
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

    private func extensionRow(icon: String, iconColor: Color, title: String, description: String) -> some View {
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

            Image(systemName: "info.circle")
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func settingRow(title: String, icon: String) -> some View {
        HStack {
            Label {
                Text(title)
                    .font(.body)
            } icon: {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingView()
        .frame(height: 800)
}
