import SwiftUI

struct RunningView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Text("正在监控").font(.title)
            Text("联网的 APP 将会出现在这里").font(.title)
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
