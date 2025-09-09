import SwiftUI
import MagicCore

struct FilterNotInstalledView: View {
    var body: some View {
        Popview(
            iconName: "exclamationmark.triangle",
            title: "过滤器未安装",
            iconColor: .red
        ) {
            VStack(spacing: 20) {
                Text("网络过滤器未安装，无法启动防火墙功能")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 16) {
                    Text("解决方案：")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("1.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("点击下方按钮安装过滤器")
                                .font(.callout)
                        }
                        
                        HStack(spacing: 8) {
                            Text("2.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("等待过滤器安装完成")
                                .font(.callout)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                
                BtnInstallFilter()
                    .controlSize(.extraLarge)
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    RootView {
        FilterNotInstalledView()
    }
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    RootView {
        FilterNotInstalledView()
    }
    .frame(width: 600, height: 600)
}
