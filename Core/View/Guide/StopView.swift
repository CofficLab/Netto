import SwiftUI

struct StopView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "stop.circle")
                .font(.system(size: 48))
                .symbolEffect(.pulse, value: isAnimating)
                .foregroundStyle(.red)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            Text("Monitoring Stopped").font(.title)
            
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

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}

#Preview {
    RootView {
        StopView()
    }
    .frame(height: 800)
}
