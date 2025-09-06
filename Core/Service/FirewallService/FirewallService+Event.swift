import Foundation
import SwiftUICore

// MARK: - Firewall Service Events

/// 防火墙服务相关事件通知名称扩展
extension Notification.Name {
    /// 防火墙即将启动
    static let firewallWillBoot = Notification.Name("firewallWillBoot")
    
    /// 防火墙状态变化
    static let firewallStatusChanged = Notification.Name("firewallStatusChanged")
    
    /// 防火墙即将安装
    static let firewallWillInstall = Notification.Name("firewallWillInstall")
    
    /// 防火墙即将启动
    static let firewallWillStart = Notification.Name("firewallWillStart")
    
    /// 防火墙即将停止
    static let firewallWillStop = Notification.Name("firewallWillStop")
    
    /// 防火墙配置变化
    static let firewallConfigurationChanged = Notification.Name("firewallConfigurationChanged")
    
    /// 防火墙发生错误
    static let firewallDidFailWithError = Notification.Name("firewallDidFailWithError")
    
    /// 防火墙已启动
    static let firewallDidStart = Notification.Name("firewallDidStart")
    
    /// 防火墙已停止
    static let firewallDidStop = Notification.Name("firewallDidStop")
    
    /// 防火墙已安装
    static let firewallDidInstall = Notification.Name("firewallDidInstall")
    
    /// 用户已授权
    static let firewallUserApproved = Notification.Name("firewallUserApproved")
    
    /// 用户拒绝授权
    static let firewallUserRejected = Notification.Name("firewallUserRejected")
    
    /// 即将注册提供者
    static let firewallWillRegisterWithProvider = Notification.Name("firewallWillRegisterWithProvider")
    
    /// 已注册提供者
    static let firewallDidRegisterWithProvider = Notification.Name("firewallDidRegisterWithProvider")
    
    /// 网络流量过滤事件
    static let firewallNetWorkFilterFlow = Notification.Name("firewallNetWorkFilterFlow")
    
    /// 需要用户批准
    static let firewallNeedApproval = Notification.Name("firewallNeedApproval")
    
    /// 等待用户批准
    static let firewallWaitingForApproval = Notification.Name("firewallWaitingForApproval")
    
    /// 权限被拒绝
    static let firewallPermissionDenied = Notification.Name("firewallPermissionDenied")
    
    /// 提供者消息
    static let firewallProviderSaid = Notification.Name("firewallProviderSaid")
    
    /// 设置允许操作完成
    static let firewallDidSetAllow = Notification.Name("firewallDidSetAllow")
    
    /// 设置拒绝操作完成
    static let firewallDidSetDeny = Notification.Name("firewallDidSetDeny")
}

// MARK: - View Extensions

extension View {
    /// 监听防火墙状态变化
    /// - Parameter action: 状态变化时的回调，参数为新的 FilterStatus
    func onFirewallStatusChange(_ action: @escaping (FilterStatus) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallStatusChanged)) { notification in
            if let status = notification.object as? FilterStatus {
                action(status)
            }
        }
    }
    
    /// 监听防火墙启动事件
    /// - Parameter action: 启动时的回调
    func onFirewallWillStart(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallWillStart)) { _ in
            action()
        }
    }
    
    /// 监听防火墙已启动事件
    /// - Parameter action: 已启动时的回调
    func onFirewallDidStart(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallDidStart)) { _ in
            action()
        }
    }
    
    /// 监听防火墙停止事件
    /// - Parameter action: 停止时的回调
    func onFirewallWillStop(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallWillStop)) { _ in
            action()
        }
    }
    
    /// 监听防火墙已停止事件
    /// - Parameter action: 已停止时的回调
    func onFirewallDidStop(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallDidStop)) { _ in
            action()
        }
    }
    
    /// 监听防火墙安装事件
    /// - Parameter action: 安装时的回调
    func onFirewallWillInstall(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallWillInstall)) { _ in
            action()
        }
    }
    
    /// 监听防火墙已安装事件
    /// - Parameter action: 已安装时的回调
    func onFirewallDidInstall(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallDidInstall)) { _ in
            action()
        }
    }
    
    /// 监听防火墙配置变化事件
    /// - Parameter action: 配置变化时的回调
    func onFirewallConfigurationChanged(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallConfigurationChanged)) { _ in
            action()
        }
    }
    
    /// 监听防火墙错误事件
    /// - Parameter action: 错误发生时的回调，参数为错误信息
    func onFirewallError(_ action: @escaping (Error) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallDidFailWithError)) { notification in
            if let userInfo = notification.userInfo,
               let error = userInfo["error"] as? Error {
                action(error)
            }
        }
    }
    
    /// 监听用户授权事件
    /// - Parameter action: 用户授权时的回调
    func onFirewallUserApproved(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallUserApproved)) { _ in
            action()
        }
    }
    
    /// 监听用户拒绝授权事件
    /// - Parameter action: 用户拒绝授权时的回调
    func onFirewallUserRejected(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallUserRejected)) { _ in
            action()
        }
    }
    
    /// 监听防火墙启动事件
    /// - Parameter action: 启动时的回调
    func onFirewallWillBoot(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallWillBoot)) { _ in
            action()
        }
    }
}
