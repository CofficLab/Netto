import SwiftUI

struct DisabledView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.shield")
                .font(.system(size: 48))
                .symbolEffect(.bounce.down, value: isAnimating)
                .foregroundStyle(.red)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            Text("Filter is disabled")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

            BtnStart()
                .scaleEffect(isAnimating ? 1 : 0.9)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}

#Preview {
    RootView {
        DisabledView()
    }
    .frame(height: 800)
}
