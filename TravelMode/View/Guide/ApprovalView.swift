import SwiftUI

struct ApprovalView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Please allow TravelMode to run in System Settings")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

            Text("General -> Login Items & Extensions -> Network Extension -> TravelMode")
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
