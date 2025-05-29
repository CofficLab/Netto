import MagicCore
import OSLog
import SwiftUI

struct AppLine: View, SuperEvent {
    @EnvironmentObject var data: DataProvider

    var app: SmartApp

    @State var hovering: Bool = false
    @State var shouldAllow: Bool = true
    @State var showCopyMessage: Bool = false

    init(app: SmartApp) {
        self.app = app
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
            .foregroundColor(app.isSystemApp ? .green.opacity(0.5) : .primary)

            Spacer()

            if hovering && app.isNotSample {
                AppAction(shouldAllow: $shouldAllow, appId: app.id)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(Group {
            if !shouldAllow {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red.opacity(0.2),
                        Color.red.opacity(0.05),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if hovering {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.mint.opacity(0.2),
                        Color.mint.opacity(0.05),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        })
        .scaleEffect(hovering ? 1 : 1)
        .onHover(perform: { hovering in
            self.hovering = hovering
        })
        .onTapGesture(count: 2) {
            copyAppId()
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: onAppear)
        .overlay(
            Group {
                if showCopyMessage {
                    Text("App ID 已复制到剪贴板")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .transition(.opacity.combined(with: .scale))
                }
            },
            alignment: .center
        )
    }
}

// MARK: - 事件

extension AppLine {
    /// 页面出现时的处理
    func onAppear() {
        self.shouldAllow = data.shouldAllow(app.id)
    }
    
    /// 复制应用 ID 到剪贴板
    private func copyAppId() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(app.id, forType: .string)
        
        // 显示复制成功提示
        withAnimation(.easeInOut(duration: 0.3)) {
            showCopyMessage = true
        }
        
        // 2秒后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCopyMessage = false
            }
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
