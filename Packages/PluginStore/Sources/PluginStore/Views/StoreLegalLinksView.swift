import LumiUI
import SwiftUI

// MARK: - 法律链接

/// 商店底部的法律链接：隐私政策与许可协议。
///
/// App Store 审核要求订阅类商品在**购买前**可读到这两份文档，因此链接
/// 必须出现在商品列表所在的同一页。
struct StoreLegalLinksView: View {
    @LumiTheme private var theme

    static var privacyURL: URL? {
        URL(string: "https://coffic.cn/privacy")
    }

    static var licenseURL: URL? {
        URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
    }

    var body: some View {
        if let privacyURL = Self.privacyURL,
           let licenseURL = Self.licenseURL {
            HStack(spacing: AppUI.Spacing.md) {
                Link(destination: privacyURL) {
                    Label {
                        Text("Privacy Policy")
                    } icon: {
                        Image(systemName: "hand.raised.fill")
                    }
                    .font(AppUI.Typography.footnote)
                }

                Link(destination: licenseURL) {
                    Label {
                        Text("License Agreement")
                    } icon: {
                        Image(systemName: "doc.text.fill")
                    }
                    .font(AppUI.Typography.footnote)
                }
            }
            .foregroundStyle(theme.textSecondary)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
