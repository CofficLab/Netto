// swift-tools-version: 6.0
// PluginEventStore：防火墙事件存储实现插件（分页/筛选/统计/维护）。
// 依赖约束：KernelCore、PluginPersistence、ProviderFirewallEvents、OSLog。
// 禁止 SwiftUI/具体 Repo；NetworkExtension 仅用于 direction raw value 映射。
import PackageDescription

let package = Package(
    name: "PluginEventStore",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PluginEventStore", targets: ["PluginEventStore"])
    ],
    dependencies: [
        .package(name: "KernelCore", path: "../KernelCore"),
        .package(name: "PluginPersistence", path: "../PluginPersistence"),
        .package(name: "ProviderFirewallEvents", path: "../ProviderFirewallEvents"),
    ],
    targets: [
        .target(
            name: "PluginEventStore",
            dependencies: [
                "KernelCore",
                "PluginPersistence",
                "ProviderFirewallEvents",
            ]
        ),
        .testTarget(
            name: "PluginEventStoreTests",
            dependencies: ["PluginEventStore"]
        ),
    ]
)
