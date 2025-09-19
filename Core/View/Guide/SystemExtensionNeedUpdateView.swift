import MagicCore
import SwiftUI

struct SystemExtensionNeedUpdateView: View {
    var body: some View {
        Popview(
            iconName: "arrow.clockwise.circle",
            title: "需要更新系统扩展",
            iconColor: .orange
        ) {
            VStack(spacing: 20) {
                Text("检测到已安装旧版本的系统扩展，需要更新到当前版本")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                VStack(spacing: 16) {
                    Text("更新步骤：")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("1.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("点击下方按钮更新系统扩展")
                                .font(.callout)
                        }

                        HStack(spacing: 8) {
                            Text("2.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("系统会自动替换旧版本扩展")
                                .font(.callout)
                        }

                        HStack(spacing: 8) {
                            Text("3.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("等待更新完成，防火墙即可正常使用")
                                .font(.callout)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)

                BtnInstallExtension()
                    .controlSize(.extraLarge)
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    RootView {
        SystemExtensionNeedUpdateView()
    }
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    RootView {
        SystemExtensionNeedUpdateView()
    }
    .frame(width: 600, height: 600)
}
