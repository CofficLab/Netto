// swift-tools-version: 6.0
// PluginPersistence：SwiftData ModelContainer 的唯一创建者；共享 schema/config 位于 ProviderPersistence。
// EventStore / AppSettings 插件都依赖本包，保证同一 db.sqlite 只有一个容器实例。
// 依赖约束：Foundation、SwiftData、OSLog、KernelCore。禁止 SwiftUI/NetworkExtension/StoreKit/MagicKit。
import PackageDescription

let package = Package(
    name: "PluginPersistence",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PluginPersistence", targets: ["PluginPersistence"])
    ],
    dependencies: [
        .package(name: "KernelCore", path: "../KernelCore"),
        .package(name: "ProviderPersistence", path: "../ProviderPersistence"),
    ],
    targets: [
        .target(
            name: "PluginPersistence",
            dependencies: [
                "KernelCore",
                "ProviderPersistence",
            ]
        ),
        .testTarget(
            name: "PluginPersistenceTests",
            dependencies: ["PluginPersistence", "ProviderPersistence"]
        ),
    ]
)
