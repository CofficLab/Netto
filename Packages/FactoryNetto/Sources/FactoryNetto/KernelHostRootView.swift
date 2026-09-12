import Foundation
import KernelCore
import PluginShell
import ProviderShell
import SwiftUI

/// 主视图 Host 壳 —— 启动态 / 运行态 / 失败态。
///
/// 阶段 3 占位实现：展示 Kernel 生命周期状态与 Shell 工具栏贡献聚合，
/// 证明 Factory 生成的视图走真实 Provider 解析路径；阶段 6 将替换内容区。
///
/// 约束：本视图不创建任何核心服务；`shell` 在装配时解析并缓存。
struct KernelHostRootView: View {
    let kernel: KernelCoreContainer
    let shell: ShellCenter?

    var body: some View {
        VStack(spacing: 0) {
            toolbarArea
            Divider()
            contentArea
        }
    }

    private var toolbarArea: some View {
        HStack(spacing: 12) {
            if let shell {
                HStack(spacing: 8) {
                    ForEach(shell.leftContributions) { contribution in
                        contribution.makeView()
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    ForEach(shell.centerContributions) { contribution in
                        contribution.makeView()
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    ForEach(shell.rightContributions) { contribution in
                        contribution.makeView()
                    }
                }
            } else {
                Spacer()
                Text("Shell 未装配")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }

    @ViewBuilder
    private var contentArea: some View {
        switch kernel.lifecycleState {
        case .running:
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("内核运行中（阶段 3 Host 占位，阶段 6 接入真实内容）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            BootstrapFailureView(
                title: "内核启动失败",
                message: "Kernel lifecycle: \(kernel.lifecycleState)"
            )
        default:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// 设置视图 Host 壳 —— 列出 SettingsProviding 聚合的设置入口。
struct SettingsHostView: View {
    let kernel: KernelCoreContainer
    let settings: ShellCenter?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("设置")
                .font(.headline)
                .padding(.bottom, 4)
            if let settings {
                if settings.entries.isEmpty {
                    Text("暂无设置入口（阶段 3 Host 占位）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(settings.entries) { entry in
                        entry.makeView()
                    }
                }
            } else {
                BootstrapFailureView(title: "设置 Provider 未装配", message: "")
            }
            Spacer()
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 320)
    }
}

/// 启动失败视图（与 Lumi BootstrapFailureView 语义一致：失败必须显式呈现）。
struct BootstrapFailureView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(title)
                .font(.headline)
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
