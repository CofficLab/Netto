import AppKit
import LumiUI
import SwiftUI

/**
 * 应用信息视图
 * 
 * 展示应用的基本信息，包括图标、名称、ID、属性信息和Bundle路径
 * 支持复制App ID和显示代理应用解释
 */
struct AppInfoView: View {
    nonisolated static let emoji = "📱"
    
    /// 应用对象
    var app: SmartApp
    
    /// 复制状态，用于显示复制成功的动画提示
    @State private var isCopied = false
    
    /// 是否显示代理解释视图
    @State private var showProxyExplanation = false

    @LumiTheme private var theme

    private var isProxyApp: Bool {
        SmartApp.isProxyApp(withId: app.id)
    }

    private var showsTypeRow: Bool {
        app.isSystemApp || isProxyApp
    }

    var body: some View {
        AppCard(
            style: .subtle,
            cornerRadius: DesignTokens.Radius.md,
            showShadow: false
        ) {
            VStack(alignment: .leading, spacing: AppUI.Spacing.md) {
                header
                metadata

                if showProxyExplanation {
                    ProxyExplanationView()
                        .frame(height: 380)
                        .background(
                            theme.elevatedSurface.opacity(0.6),
                            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                .stroke(theme.appSubtleBorder, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: AppUI.Spacing.md) {
            AppIcon(app: app)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: AppUI.Spacing.xs) {
                Text(app.name)
                    .font(.appSectionTitle)
                    .foregroundStyle(theme.textPrimary)

                HStack(spacing: AppUI.Spacing.xs) {
                    Text("ID: \(app.id)")
                        .font(.appCaption)
                        .foregroundStyle(theme.textSecondary)
                        .textSelection(.enabled)

                    AppButton(
                        systemImage: isCopied ? "checkmark.circle.fill" : "doc.on.doc",
                        style: .ghost,
                        size: .small,
                        action: copyAppID
                    )
                    .help(isCopied ? String(localized: "Copied!") : String(localized: "Copy App ID"))
                }
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var metadata: some View {
        if showsTypeRow || app.bundleURL != nil {
            AppMetadataCard {
                if app.isSystemApp {
                    AppMetadataRow(title: String(localized: "Type"), systemImage: "checkmark.seal") {
                        Label("System App", systemImage: "checkmark.circle.fill")
                            .font(.appCaption)
                            .foregroundStyle(theme.success)
                    }
                } else if isProxyApp {
                    AppMetadataRow(title: String(localized: "Type"), systemImage: "shield") {
                        HStack(spacing: AppUI.Spacing.xs) {
                            Label("Proxy App", systemImage: "shield.fill")
                                .font(.appCaption)
                                .foregroundStyle(theme.warning)

                            AppButton(
                                systemImage: showProxyExplanation ? "chevron.up.circle.fill" : "info.circle",
                                style: .ghost,
                                size: .small
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showProxyExplanation.toggle()
                                }
                            }
                            .help(showProxyExplanation ? String(localized: "Collapse Proxy App Description") : String(localized: "Understanding the Impact of Proxy Apps on Network Monitoring"))
                        }
                    }
                }

                if showsTypeRow && app.bundleURL != nil {
                    AppSettingsDivider()
                }

                if let bundleURL = app.bundleURL {
                    AppMetadataRow(title: String(localized: "Path"), systemImage: "folder") {
                        HStack(spacing: AppUI.Spacing.xs) {
                            Text(bundleURL.path)
                                .font(.appMicro)
                                .foregroundStyle(theme.textSecondary)
                                .textSelection(.enabled)
                                .lineLimit(2)
                                .truncationMode(.middle)

                            AppButton(systemImage: "doc.viewfinder", style: .ghost, size: .small) {
                                NSWorkspace.shared.activateFileViewerSelecting([bundleURL])
                            }
                            .help("Show in Finder")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Action
    
    /// 复制App ID到剪贴板的方法
    private func copyAppID() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(app.id, forType: .string)
        
        // 显示复制成功的动画
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isCopied = true
        }
        
        // 2秒后重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isCopied = false
            }
        }
    }
}

#Preview("APP") {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 600)
}

#Preview("应用信息视图") {
    AppInfoView(app: SmartApp.samples.first!)
        .frame(width: 600)
}
