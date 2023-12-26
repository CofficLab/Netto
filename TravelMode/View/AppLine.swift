import SwiftUI

struct AppLine: View {
    var app: SmartApp
    
    @State private var hovering: Bool = false
    
    private var background: some View {
        ZStack {
            if hovering {
                BackgroundView.type1.opacity(0.4)
            } else {
                if !AppSetting.shouldAllow(app.id) {
                    Color.red.opacity(0.1)
                }
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
                if AppSetting.shouldAllow(app.id) {
                    Button("禁止") {
                        AppSetting.setDeny(app.id)
                    }
                } else {
                    Button("允许") {
                        AppSetting.setAllow(app.id)
                    }
                }
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
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
