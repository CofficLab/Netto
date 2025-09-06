import SwiftUI

/**
 * 停止监控视图
 * 使用Popview封装，显示监控已停止状态并提供启动按钮
 */
struct StopView: View {
    var body: some View {
        Popview(
            iconName: "stop.circle",
            title: "监控已停止",
            iconColor: .red
        ) {
            VStack(spacing: 20) {
                // 状态信息区域
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: .iconStop)
                            .foregroundStyle(.orange)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 20, alignment: .center)
                        Text("当前网络监控已停止")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.orange.opacity(0.1))
                    .cornerRadius(8)

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(.green)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 20, alignment: .center)
                        Text("所有应用可自由联网")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.green.opacity(0.1))
                    .cornerRadius(8)
                }

                BtnStart()
            }
        }
    }
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}

#Preview {
    StopView()
        .inRootView()
        .frame(height: 400)
}
