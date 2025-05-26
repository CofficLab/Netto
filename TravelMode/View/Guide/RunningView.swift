import SwiftUI

struct RunningView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "inset.filled.rectangle.badge.record")
                .font(.system(size: 48))
                .symbolEffect(.rotate, value: isAnimating)
                .foregroundStyle(.blue)
            
            Text("正在监控")
                .font(.title)
            Text("Apps connected to the internet will appear here")
        }
        .padding()
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}

#Preview {
    RootView {
        RunningView()
    }
    .frame(height: 800)
}
