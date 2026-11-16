import LumiUI
import SwiftUI

/// 错误显示视图
/// 显示错误信息并提供复制到剪贴板的功能
struct ErrorView: View {
    let error: Error
    @State private var showCopiedMessage = false
    @LumiTheme private var theme

    var body: some View {
        DashboardGuidePanel(
            iconName: "exclamationmark.triangle.fill",
            title: "启动失败",
            iconColor: theme.error
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                AppStatusBanner(
                    kind: .error,
                    title: "防火墙启动时遇到错误",
                    message: error.localizedDescription
                )

                AppButton(
                    showCopiedMessage ? "已复制" : "复制错误信息",
                    systemImage: showCopiedMessage ? "checkmark.circle.fill" : "doc.on.clipboard",
                    style: showCopiedMessage ? .tonal : .secondary,
                    fillsWidth: true,
                    action: copyErrorToClipboard
                )

                BtnStart(title: "重试")
            }
        }
    }

    /// 复制错误信息到剪贴板
    /// 将完整的错误描述复制到系统剪贴板
    private func copyErrorToClipboard() {
        let errorText = "Error: \(error.localizedDescription)"

        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(errorText, forType: .string)
        #else
        UIPasteboard.general.string = errorText
        #endif

        withAnimation(.easeInOut(duration: 0.3)) {
            showCopiedMessage = true
        }

        // 2秒后隐藏提示信息
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCopiedMessage = false
            }
        }
    }
}

#Preview {
    ErrorView(error: NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "This is a test error message"]))
        .dashboardPreviewRoot()
        .frame(width: 400, height: 500)
}
