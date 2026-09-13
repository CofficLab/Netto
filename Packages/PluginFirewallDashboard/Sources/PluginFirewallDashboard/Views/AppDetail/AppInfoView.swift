import SwiftUI
import MagicCore
import OSLog

/**
 * 应用信息视图
 * 
 * 展示应用的基本信息，包括图标、名称、ID、属性信息和Bundle路径
 * 支持复制App ID和显示代理应用解释
 */
struct AppInfoView: View, SuperLog {
    nonisolated static let emoji = "📱"
    
    /// 应用对象
    var app: SmartApp
    
    /// 复制状态，用于显示复制成功的动画提示
    @State private var isCopied = false
    
    /// 是否显示代理解释视图
    @State private var showProxyExplanation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("应用详情")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 应用基本信息
            HStack(spacing: 12) {
                app.getIcon()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // App ID 和复制按钮
                    HStack(spacing: 6) {
                        Text("ID: \(app.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                        
                        Button(action: {
                            copyAppID()
                        }) {
                            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                .foregroundColor(isCopied ? .green : .secondary)
                                .font(.caption)
                                .scaleEffect(isCopied ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCopied)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(isCopied ? "已复制!" : "复制 App ID")
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // 应用属性信息
            VStack(alignment: .leading, spacing: 6) {
                Text("属性信息")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(spacing: 4) {
                    // 根据应用类型显示相应的标签
                    if app.isSystemApp {
                        // 系统应用标签
                        HStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                    .frame(width: 12, alignment: .center)
                                
                                Text("系统应用 (System App)")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                            
                            Spacer(minLength: 0)
                        }
                    } else if SmartApp.isProxyApp(withId: app.id) {
                        // 代理应用标签
                        HStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .frame(width: 12, alignment: .center)
                                
                                Text("代理应用 (Proxy App)")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showProxyExplanation.toggle()
                                }
                            }) {
                                Image(systemName: showProxyExplanation ? "chevron.up.circle.fill" : "info.circle")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help(showProxyExplanation ? "收起代理应用说明" : "了解代理应用对网络监控的影响")

                            Spacer(minLength: 0)
                        }
                    }
                }
                
                // Bundle URL 信息
                if let bundleURL = app.bundleURL {
                    HStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .foregroundColor(.purple)
                                .font(.caption)
                                .frame(width: 12, alignment: .center)
                            
                            Text("路径")
                                .foregroundColor(.purple)
                                .font(.caption)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    
                    // Bundle URL 路径显示
                    HStack(spacing: 6) {
                        Text(bundleURL.path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(2)
                            .truncationMode(.middle)
                        
                        Button(action: {
                            bundleURL.openInFinder()
                        }) {
                            Image(systemName: "doc.viewfinder")
                                .foregroundColor(.secondary)
                                .font(.caption2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("在 Finder 中显示")
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 16)
                }
            }
            
            // 代理应用解释视图（折叠/展开）
            if showProxyExplanation {
                ProxyExplanationView()
                    .frame(height: 380)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.controlBackgroundColor).opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Action
    
    /// 复制App ID到剪贴板的方法
    private func copyAppID() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(app.id, forType: .string)
        
        // 显示复制成功的动画
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isCopied = true
        }
        
        // 2秒后重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isCopied = false
            }
        }
    }
}

#Preview("APP") {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 600)
}

#Preview("应用信息视图") {
    AppInfoView(app: SmartApp.samples.first!)
        .frame(width: 600)
}
