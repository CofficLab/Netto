// swift-tools-version: 6.0
// ProviderFirewall：防火墙能力中立契约（状态、Snapshot、命令协议）。
// 依赖约束：仅 Foundation。禁止 SwiftUI/AppKit/NetworkExtension/SwiftData/StoreKit/具体 Repo/Service。
import PackageDescription

let package = Package(
    name: "ProviderFirewall",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "ProviderFirewall", targets: ["ProviderFirewall"])
    ],
    targets: [
        .target(
            name: "ProviderFirewall"
        ),
        .testTarget(
            name: "ProviderFirewallTests",
            dependencies: ["ProviderFirewall"]
        ),
    ]
)
