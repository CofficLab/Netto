import NetworkExtension

/// App --> Provider IPC
@objc protocol ProviderCommunication {
    func register(_ completionHandler: @escaping (Bool) -> Void)
}

/// Provider --> App IPC
@objc protocol AppCommunication {
    func promptUser(id: String, hostname: String, port: String, direction: NETrafficDirection, responseHandler: @escaping (Bool) -> Void)
    func needApproval()
    func extensionLog(_ words: String)
}
