import SwiftUI

struct StopView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Text("已停止监控").font(.title)
            
            BtnStart().labelStyle(.titleOnly)
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
