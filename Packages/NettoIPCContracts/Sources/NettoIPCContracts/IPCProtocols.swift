import Foundation
import NetworkExtension

/// App --> Provider（Extension）IPC 契约。
///
/// 与旧 `Bridge/Protocols.swift` 的 `ProviderCommunication` 完全同构，
/// 保持 `@objc` 以便 NSXPC 接口桥接。
@objc public protocol ProviderCommunication {
    /// Extension 侧注册回调：App 首次关联时调用，返回是否成功。
    func register(_ completionHandler: @escaping (Bool) -> Void)
}

/// Provider（Extension）--> App IPC 契约。
@objc public protocol AppCommunication {
    /// 询问用户是否允许某条网络连接。
    /// - Parameters:
    ///   - id: 应用标识符。
    ///   - hostname: 主机名。
    ///   - port: 端口号。
    ///   - direction: 流量方向（NETrafficDirection 值类型跨进程传递）。
    ///   - responseHandler: 用户决策回调（true=放行，false=丢弃）。
    func promptUser(
        id: String,
        hostname: String,
        port: String,
        direction: NETrafficDirection,
        responseHandler: @escaping @Sendable (Bool) -> Void
    )

    /// 需要用户批准系统扩展/过滤器。
    func needApproval()

    /// 传递 Extension 侧日志。
    func extensionLog(_ words: String)
}
