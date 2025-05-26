import SwiftUI

struct InstallView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 50) {
            Image(systemName: "gearshape.arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .symbolEffect(.bounce, value: isAnimating)
                .foregroundStyle(.blue)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 10)
            
            BtnInstall()
                .scaleEffect(isAnimating ? 1 : 0.9)
                .controlSize(.extraLarge)

            Text("Install System Extension to continue")
                .font(.headline)
                .foregroundStyle(.secondary)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 10)
        }
        .padding(30)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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
        InstallView()
    }
    .frame(height: 800)
}
