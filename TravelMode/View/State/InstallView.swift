import SwiftUI

struct InstallView: View {
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
                VStack(spacing: 50) {
                    BtnInstall()
                        .scaleEffect(isAnimating ? 1 : 0.9)

                    Text("安装系统扩展以继续")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 10)
                }
                .padding(30)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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
