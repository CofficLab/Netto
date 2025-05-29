import MagicCore
import OSLog
import SwiftUI

struct AppLine: View, SuperEvent {
    @EnvironmentObject var data: DataProvider
    
    var app: SmartApp

    @State private var hovering: Bool = false
    @State var shouldAllow: Bool = true

    init(app: SmartApp) {
        self.app = app
    }

    private var background: some View {
            Group {
                if !shouldAllow {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.2),
                            Color.red.opacity(0.05)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else if hovering {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.mint.opacity(0.2),
                            Color.mint.opacity(0.05)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
    }

    var body: some View {
        HStack {
            app.icon.frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text(app.name)
                HStack(alignment: .top) {
                    Text("\(app.events.count)").font(.callout)
                    Text(app.id)
                }
            }

            Spacer()

            if hovering {
                AppAction(shouldAllow: $shouldAllow, appId: app.id)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(background)
        .scaleEffect(hovering ? 1 : 1)
        .onHover(perform: { hovering in
            self.hovering = hovering
        })
        .frame(height: 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: onAppear)
    }
}

// MARK: - 事件 

extension AppLine {
    func onAppear() {
        self.shouldAllow = data.shouldAllow(app.id)
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
