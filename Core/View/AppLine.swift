import MagicCore
import OSLog
import SwiftUI

struct AppLine: View, SuperEvent {
    @EnvironmentObject var data: DataProvider

    var app: SmartApp

    @State var hovering: Bool = false
    @State var shouldAllow: Bool = true
    @State var showCopyMessage: Bool = false
    @State var isExpanded: Bool = false

    init(app: SmartApp) {
        self.app = app
    }

    var body: some View {
        VStack(spacing: 0) {
            // 主应用行
            HStack {
                // 展开/折叠按钮
                if !app.children.isEmpty {
                    Button(action: toggleExpansion) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 16)
                } else {
                    Spacer().frame(width: 16)
                }
                
                app.icon.frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text(app.name)
                    HStack(alignment: .top) {
                        Text("\(app.events.count)").font(.callout)
                        if !app.children.isEmpty {
                            Text("(\(app.children.count))").font(.caption).foregroundColor(.secondary)
                        }
                        Text(app.id)
                            .foregroundColor(app.isSystemApp ? .orange.opacity(0.7) : .primary)
                    }
                }

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
            .onTapGesture {
                if !app.children.isEmpty {
                    toggleExpansion()
                }
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
            
            // 子应用列表
            if isExpanded && !app.children.isEmpty {
                VStack(spacing: 0) {
                    ForEach(app.children) { childApp in
                        ChildAppLine(app: childApp)
                            .padding(.leading, 32) // 缩进显示子应用
                    }
                }
                .transition(.slide.combined(with: .opacity))
            }
        }
    }
}

// MARK: - 事件

extension AppLine {
    /// 页面出现时的处理
    func onAppear() {
        self.shouldAllow = data.shouldAllow(app.id)
    }
    
    /// 切换展开/折叠状态
    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded.toggle()
        }
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

// MARK: - 子应用行组件

struct ChildAppLine: View {
    @EnvironmentObject var data: DataProvider
    
    var app: SmartApp
    
    @State var hovering: Bool = false
    @State var shouldAllow: Bool = true
    @State var showCopyMessage: Bool = false
    
    var body: some View {
        HStack {
            // 子应用缩进指示器
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 2, height: 30)
            
            app.icon.frame(width: 30, height: 30)
            
            VStack(alignment: .leading) {
                Text(app.name)
                    .font(.subheadline)
                HStack(alignment: .top) {
                    Text("\(app.events.count)").font(.caption2)
                    Text(app.id)
                        .font(.caption2)
                        .foregroundColor(app.isSystemApp ? .orange.opacity(0.7) : .secondary)
                }
            }
            
            Spacer()
            
            if hovering && app.isNotSample {
                AppAction(shouldAllow: $shouldAllow, appId: app.id)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 10)
        .background(Group {
            if !shouldAllow {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red.opacity(0.1),
                        Color.red.opacity(0.02),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if hovering {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.mint.opacity(0.1),
                        Color.mint.opacity(0.02),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        })
        .onHover(perform: { hovering in
            self.hovering = hovering
        })
        .onTapGesture(count: 2) {
            copyAppId()
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            self.shouldAllow = data.shouldAllow(app.id)
        }
        .overlay(
            Group {
                if showCopyMessage {
                    Text("App ID 已复制到剪贴板")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .transition(.opacity.combined(with: .scale))
                }
            },
            alignment: .center
        )
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
