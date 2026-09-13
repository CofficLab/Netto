import OSLog
import StoreKit
import SwiftUI
import MagicCore


struct AllSubscriptions: View, SuperLog {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @State private var subscriptions: [ProductDTO] = []
    @State private var refreshing = false
    @State private var error: Error? = nil
    
    nonisolated static let emoji = "🖥️"

    var body: some View {
        GroupBox {
            VStack {
                ZStack {
                    Text("订阅方案").font(.title3)
                    refreshButton
                }

                Divider()

                if refreshing == false && subscriptions.isEmpty {
                    Text("🏃 暂无")
                } else {
                    VStack {
                        ForEach(subscriptions) { product in
                            ProductCell(product: product)
                        }
                    }
                    .padding()
                }

                footerView
            }
        }
        .onAppear {
            refreshing = true
            Task {
                getProducts("AllSubscription OnAppear")
            }
        }
    }

    private var refreshButton: some View {
        HStack {
            Spacer()
            ZStack {
                if refreshing {
                    ProgressView().scaleEffect(0.4)
                } else {
                    Button(action: {
                        Task {
                            getProducts("点击了重试按钮")
                        }
                    }, label: {
                        Label("重试", systemImage: "arrow.clockwise")
                            .labelStyle(.iconOnly)
                    }).buttonStyle(.plain)
                }
            }.frame(width: 30, height: 10)
        }
    }

    // MARK: 获取可用的订阅

    private func getProducts(_ reason: String, verbose: Bool = true) {
        if verbose {
            os_log("\(self.t)GetProducts because of \(reason)")
        }
        
        refreshing = true
        Task {
            do {
                let groups = try await StoreService.fetchAllProducts()
                self.subscriptions = groups.subscriptions
            } catch {
                self.error = error
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                refreshing = false
            })
        }
    }

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
        .padding(.top, 12)
        .font(.footnote)
    }
}

// MARK: - Preview




