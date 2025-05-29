import SwiftUI

struct RunningView: View {
    @EnvironmentObject var app: AppManager

    var body: some View {
        Popview(
            iconName: "inset.filled.rectangle.badge.record",
            title: "正在监控",
            iconColor: .green
        ) {
            VStack(spacing: 20) {
                // 状态信息区域
                VStack(alignment: .leading, spacing: 12) {
                    switch app.displayType {
                    case .All:
                        allTip
                    case .Allowed:
                        allowTip
                    case .Rejected:
                        denyTip
                    }
                }
            }
        }
    }
    
    private var allTip: some View = HStack(spacing: 8) {
        Image(systemName: .iconStop)
            .foregroundStyle(.blue)
            .font(.system(size: 14, weight: .medium))
            .frame(width: 20, alignment: .center)

        Text("联网的 APP 将显示在这里")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.primary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(.orange.opacity(0.1))
    .cornerRadius(8)
    
    private var allowTip: some View = HStack(spacing: 8) {
        Image(systemName: .iconStop)
            .foregroundStyle(.green)
            .font(.system(size: 14, weight: .medium))
            .frame(width: 20, alignment: .center)

        Text("被允许联网的 APP 将显示在这里")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.primary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(.orange.opacity(0.1))
    .cornerRadius(8)
    
    private var denyTip: some View = VStack {
        HStack(spacing: 8) {
            Image(systemName: .iconStop)
                .foregroundStyle(.orange)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 20, alignment: .center)

            Text("被禁止联网的 APP 将显示在这里")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.1))
        .cornerRadius(8)
        
        HStack(spacing: 8) {
            Image(systemName: .iconInfo)
                .foregroundStyle(.orange)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 20, alignment: .center)

            Text("当前没有出现被禁止联网的 APP")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    RootView {
        RunningView()
    }
    .frame(height: 500)
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
