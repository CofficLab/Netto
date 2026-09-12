import MagicCore
import SwiftUI

/**
 * 代理应用解释视图
 * 展示代理应用对网络监控的影响，左侧显示未开启代理的情况，右侧显示开启代理的情况
 */
struct ProxyExplanationView: View {
    @State private var showAnimation = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 标题
            Text("代理应用对网络监控的影响")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            // 说明文字
            Text("💡 当代理应用运行时，部分应用的网络流量会被代理应用接管，\n这些应用的网络活动将无法被本软件直接监控到。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 20)

            // 对比视图
            VStack(spacing: 0) {
                // 标题行（对齐）
                HStack {
                    Text("未开启代理")
                        .font(.headline)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 1)
                        .frame(height: 36)

                    Text("开启代理")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                }

                // 网络层级视图
                VStack(spacing: 12) {
                    // 应用层
                    HStack(spacing: 30) {
                        // 左侧：正常应用
                        normalAppsView

                        // 分隔线
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)

                        // 右侧：代理应用和被隐藏的应用
                        proxyAppsView
                    }
                    .frame(height: 120)

                    // 箭头指向操作系统
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.gray)
                            .font(.title2)
                            .opacity(showAnimation ? 1 : 0.3)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showAnimation)
                            .frame(maxWidth: .infinity)

                        Image(systemName: "arrow.down")
                            .foregroundColor(.gray)
                            .font(.title2)
                            .opacity(showAnimation ? 1 : 0.3)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showAnimation)
                            .frame(maxWidth: .infinity)
                    }

                    // 操作系统层（底层）
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 50)
                        .overlay(
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                Text("操作系统 (macOS)")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        )
                }
            }
            .frame(maxWidth: 600, maxHeight: .infinity)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .padding(.top, 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                showAnimation = true
            }
        }
    }

    /**
     * 正常应用视图
     * 显示所有应用直接通过操作系统处理网络数据
     */
    private var normalAppsView: some View {
        VStack(spacing: 8) {
            // 应用列表
            VStack(spacing: 6) {
                appRow(name: "Safari", icon: "safari", color: .blue, visible: true)
                appRow(name: "Chrome", icon: "globe", color: .orange, visible: true)
                appRow(name: "Xcode", icon: "hammer", color: .blue, visible: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /**
     * 代理应用视图
     * 显示代理应用和被隐藏的应用情况
     */
    private var proxyAppsView: some View {
        VStack(spacing: 8) {
            // 应用列表（部分隐藏）
            VStack(spacing: 6) {
                appRow(name: "Safari", icon: "safari", color: .gray, visible: false)
                appRow(name: "Chrome", icon: "globe", color: .gray, visible: false)
                appRow(name: "Xcode", icon: "hammer", color: .gray, visible: false)
            }

            // 代理应用
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.2))
                .frame(height: 30)
                .overlay(
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.orange)
                        Text("代理应用")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                )
        }
        .frame(maxWidth: .infinity)
    }

    /**
     * 应用行视图
     * 显示单个应用的状态
     */
    private func appRow(name: String, icon: String, color: Color, visible: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)

            Text(name)
                .font(.caption)
                .foregroundColor(visible ? .primary : .secondary)

            Spacer()

            if !visible {
                Image(systemName: "eye.slash")
                    .foregroundColor(.gray)
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(visible ? Color.clear : Color.gray.opacity(0.1))
        )
        .opacity(visible ? 1.0 : 0.6)
        .scaleEffect(showAnimation && visible ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.8).delay(visible ? 0 : 0.3), value: showAnimation)
    }
}

#Preview {
    ProxyExplanationView()
        .frame(width: 700, height: 500)
}

#Preview("APP") {
    RootView(environment: .preview()) {
        ContentView()
    }
    .frame(height: 800)
}
