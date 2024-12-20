import SwiftUI

struct RunningView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Monitoring").font(.title)
            Text("Apps connected to the internet will appear here").font(.title)
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
