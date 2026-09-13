// swift-tools-version: 6.0
// ProviderFirewallEvents：防火墙事件/数据库查询中立契约。
// 依赖约束：仅 Foundation。禁止 SwiftData/SwiftUI/NetworkExtension/具体 Repo。
import PackageDescription

let package = Package(
    name: "ProviderFirewallEvents",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "ProviderFirewallEvents", targets: ["ProviderFirewallEvents"])
    ],
    targets: [
        .target(
            name: "ProviderFirewallEvents"
        ),
        .testTarget(
            name: "ProviderFirewallEventsTests",
            dependencies: ["ProviderFirewallEvents"]
        ),
    ]
)
