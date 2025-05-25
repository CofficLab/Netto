import SwiftUI

struct SettingView: View {
    var body: some View {
        NavigationSplitView {
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
                                Text("Apple 账户")
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
                    NavigationLink(destination: Text("蓝牙")) {
                        Label("蓝牙", systemImage: "bluetooth")
                    }
                    NavigationLink(destination: Text("网络")) {
                        Label("网络", systemImage: "network")
                    }
                    NavigationLink(destination: Text("VPN")) {
                        Label("VPN", systemImage: "vpn")
                    }
                }
                
                Section {
                    NavigationLink(destination: Text("通用")) {
                        Label("通用", systemImage: "gear")
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
        } detail: {
            Text("选择一个设置项")
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    SettingView()
}
