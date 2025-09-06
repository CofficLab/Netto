import SwiftUI
import MagicCore

struct NotInApplicationsFolderView: View {
    var body: some View {
        Popview(
            iconName: "folder.badge.questionmark",
            title: "APP未安装在Applications目录",
            iconColor: .orange
        ) {
            VStack(spacing: 16) {
                Text("请将APP移动到Applications目录后再试")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Text("操作步骤：")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("1.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("退出当前软件")
                                .font(.callout)
                        }
                        
                        HStack(spacing: 8) {
                            Text("2.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("打开Finder")
                                .font(.callout)
                        }
                        
                        HStack(spacing: 8) {
                            Text("3.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("找到当前APP的位置")
                                .font(.callout)
                        }
                        
                        HStack(spacing: 8) {
                            Text("4.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("将APP拖拽到Applications文件夹")
                                .font(.callout)
                        }
                        
                        HStack(spacing: 8) {
                            Text("5.")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Text("重新启动APP")
                                .font(.callout)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    RootView {
        NotInApplicationsFolderView()
    }
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    RootView {
        NotInApplicationsFolderView()
    }
    .frame(width: 600, height: 600)
}
