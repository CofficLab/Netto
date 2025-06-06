import SwiftUI

extension SmartApp {
    static func unknownApp(_ id: String) -> SmartApp {
        SmartApp(id: id, name: "未知")
    }
    
    static func getDefaultIcon() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.cyan]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Image(systemName: "app.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .foregroundColor(.white)
        }
        .frame(width: 30, height: 30)
        .clipped()
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
