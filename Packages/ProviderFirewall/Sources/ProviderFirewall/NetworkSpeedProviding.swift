import Foundation

/// 单个应用的实时网速（字节/秒）。
///
/// 只包含中立数值与 `appId`，不携带进程、图标等平台类型。
public struct AppNetworkSpeed: Identifiable, Sendable, Equatable {
    public let appId: String
    public let downloadBytesPerSecond: Double
    public let uploadBytesPerSecond: Double

    public var id: String { appId }
    public var totalBytesPerSecond: Double { downloadBytesPerSecond + uploadBytesPerSecond }

    public init(appId: String, downloadBytesPerSecond: Double, uploadBytesPerSecond: Double) {
        self.appId = appId
        self.downloadBytesPerSecond = downloadBytesPerSecond
        self.uploadBytesPerSecond = uploadBytesPerSecond
    }
}

/// 应用实时网速契约。
///
/// 数据源是系统扩展的内容过滤数据面：扩展按应用累计字节并每秒经 XPC
/// 上报，App 侧做速率归一化与平滑后发布快照。
///
/// 线程/actor：实现为 `@MainActor` 对象；观察者通过 `observe()` 接收更新。
@MainActor
public protocol NetworkSpeedProviding: AnyObject, Sendable {
    /// 当前网速快照，按总速率降序。
    var snapshot: [AppNetworkSpeed] { get }

    /// 观察网速快照更新（AsyncStream；订阅方负责消费与取消）。
    func observe() -> AsyncStream<[AppNetworkSpeed]>
}
