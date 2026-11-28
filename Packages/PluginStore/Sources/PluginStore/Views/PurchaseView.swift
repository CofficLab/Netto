import LumiUI
import OSLog
import StoreKit
import SwiftUI

struct PurchaseView: View {
    nonisolated static let emoji = "🛒"

    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.dismiss) private var dismiss
    @State var closeBtnHovered = false
    var showCloseButton = false
    
    // MARK: - Product Type Configuration
    var showSubscription: Bool = true
    var showOneTime: Bool = false
    var showNonRenewable: Bool = false
    var showConsumable: Bool = false
    
    init(showCloseButton: Bool = false, 
         showSubscription: Bool = true,
         showOneTime: Bool = false,
         showNonRenewable: Bool = false,
         showConsumable: Bool = false) {
        self.showCloseButton = showCloseButton
        self.showSubscription = showSubscription
        self.showOneTime = showOneTime
        self.showNonRenewable = showNonRenewable
        self.showConsumable = showConsumable
    }

    var body: some View {
        VStack {
            // 添加关闭按钮（可配置）
            if showCloseButton {
                HStack {
                    Spacer()
                    AppButton(systemImage: "xmark.circle.fill", style: .destructive, action: {
                        dismiss()
                    })

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
            }

            // 商品分组
            TabView {
                if showSubscription {
                    ProductsSubscription()
                        .tabItem { Label("Subscriptions", systemImage: "repeat") }
                }
                
                if showOneTime {
                    ProductsOfOneTime()
                        .tabItem { Label("One-Time Purchases", systemImage: "car") }
                }

                if showNonRenewable {
                    ProductsNonRenewable()
                        .tabItem { Label("Non-Renewing", systemImage: "clock") }
                }

                if showConsumable {
                    ProductsConsumable()
                        .tabItem { Label("Consumables", systemImage: "drop") }
                }
            }
            .padding()
            .background(AppBackground.ocean.opacity(0.1))

            RestoreView()
                .padding()
                .background(AppBackground.aurora.opacity(0.1))

            footerView
        }
        .padding()
    }

    // MARK: Footer

    private var footerView: some View {
        HStack {
            Spacer()
            Link("Privacy Policy", destination: URL(string: "https://www.kuaiyizhi.cn/privacy")!)
            Link("License Agreement", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Spacer()
        }
        .foregroundStyle(
            colorScheme == .light ?
                .black.opacity(0.8) :
                .white.opacity(0.8))
        .padding(.vertical, 12)

        .font(.footnote)
        .background(AppBackground.aurora.opacity(0.1))
    }
}






