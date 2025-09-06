import NetworkExtension

/// App --> Provider IPC
@objc protocol ProviderCommunication {
    /// 注册
    /// - Parameter completionHandler: 注册结果回调
    func register(_ completionHandler: @escaping (Bool) -> Void)
}

/// Provider --> App IPC
@objc protocol AppCommunication {
    /// 是否允许网络连接
    /// - Parameters:
    ///   - id: 应用标识符
    ///   - hostname: 主机名
    ///   - port: 端口号
    ///   - direction: 网络流量方向
    ///   - responseHandler: 响应处理回调
    func promptUser(id: String, hostname: String, port: String, direction: NETrafficDirection, responseHandler: @escaping (Bool) -> Void)
    
    /// 需要用户批准
    func needApproval()
    
    /// 用于传递扩展发出的日志
    /// - Parameter words: 日志内容
    func extensionLog(_ words: String)
}
