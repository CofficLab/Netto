import SwiftUI

struct ApprovalView: View {
    @State private var isAnimating = false

    var body: some View {
        Group {
            if AppConfig.osVersion < 15 {
                VStack(spacing: 24) {
                    Text("请在系统设置中允许运行")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.primary)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)

                    Image("NeedApproval")
                        .resizable()
                        .scaledToFit()
                        .shadow(radius: 10)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.8)
                }
                .padding()
            } else {
                VStack(spacing: 24) {
                    Text("请在系统设置中允许运行")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.primary)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)

                    Text("通用 -> 登录项与扩展 -> 网络扩展 -> TravelMode")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    BtnInstall()
                        .scaleEffect(isAnimating ? 1 : 0.9)

                    Image("NeedApproval-15")
                        .resizable()
                        .scaledToFit()
                        .shadow(radius: 10)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.8)
                }
                .padding()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}