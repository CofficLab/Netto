import MagicBackground
import MagicCore
import MagicUI
import OSLog
import StoreKit
import SwiftUI

struct PurchaseView: View, SuperLog {
    nonisolated static let emoji = "🛒"

    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreProvider
    @State var closeBtnHovered: Bool = false

    var body: some View {
        VStack {
            // 添加关闭按钮
            HStack {
                Spacer()
                MagicButton.simple(action: {
                    dismiss()
                })
                .magicIcon(.iconClose)
                .magicShape(.circle)
                .magicStyle(.danger)
                .magicShapeVisibility(.always)

                #if os(macOS)
                    .onHover { hovering in
                        closeBtnHovered = hovering
                    }
                    .scaleEffect(closeBtnHovered ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: closeBtnHovered)
                #endif
                #if os(iOS)
                .scaleEffect(closeBtnHovered ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: closeBtnHovered)
                .onTapGesture {
                    closeBtnHovered = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        closeBtnHovered = false
                    }
                }
                #endif
            }
            .padding(.vertical, 2)

            // 商品分组 Tab 展示（每类一个定制视图）
            TabView {
                ProudctsOfSubscription()
                    .tabItem { Label("订阅", systemImage: "repeat") }
                
                CarsProductsView()
                    .tabItem { Label("一次性购买", systemImage: "car") }

                NonRenewableProductsView()
                    .tabItem { Label("非续订", systemImage: "clock") }

                ConsumableProductsView()
                    .tabItem { Label("消耗品", systemImage: "drop") }
            }
            .padding()
            .background(MagicBackground.aurora.opacity(0.1))

            RestoreView()
                .padding()
                .background(MagicBackground.aurora.opacity(0.1))

            footerView
        }
        .padding()
    }

    // MARK: Footer

    private var footerView: some View {
        HStack {
            Spacer()
            Link("隐私政策", destination: URL(string: "https://www.kuaiyizhi.cn/privacy")!)
            Link("许可协议", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Spacer()
        }
        .foregroundStyle(
            colorScheme == .light ?
                .black.opacity(0.8) :
                .white.opacity(0.8))
        .padding(.vertical, 12)

        .font(.footnote)
        .background(MagicBackground.aurora.opacity(0.1))
    }
}

#Preview("BuyView") {
    PurchaseView()
        .inRootView()
        .frame(height: 800)
}

#Preview("Store Debug") {
    DebugView()
        .inRootView()
        .frame(width: 500, height: 700)
}
