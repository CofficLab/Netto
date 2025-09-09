import MagicCore
import SwiftUI

struct ExtensionNotReady: View {
    var body: some View {
        Popview(
            iconName: "exclamationmark.shield",
            title: "需要激活系统扩展"
        ) {
            VStack(spacing: 20) {
                // 激活步骤示意图
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("1.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("打开系统设置")
                                .font(.callout)
                        }

                        HStack(spacing: 8) {
                            Text("2.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("找到本应用的扩展")
                                .font(.callout)
                        }

                        HStack(spacing: 8) {
                            Text("3.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("将开关点击到启用状态")
                                .font(.callout)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)

                // 系统设置按钮
                BtnSetting()
                    .controlSize(.extraLarge)
            }
        }
    }
}

#Preview {
    ExtensionNotReady()
        .inRootView()
        .frame(height: 500)
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
