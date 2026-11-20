// swift-tools-version: 6.0
// PluginPersistence：各数据插件独立 ModelContainer 的唯一创建者；共享 schema/config 位于 ProviderPersistence。
// EventStore / AppSettings 插件各自持有自己的 SQLite 文件，不共享容器。
// 依赖约束：Foundation、SwiftData、OSLog、KernelCore、ProviderStorage。禁止 SwiftUI/NetworkExtension/StoreKit。
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
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.0"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.19.0"),
        .package(name: "ProviderPersistence", path: "../ProviderPersistence"),
    ],
    targets: [
        .target(
            name: "PluginPersistence",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderStorage", package: "LumiProviders"),
                "ProviderPersistence",
            ]
        ),
        .testTarget(
            name: "PluginPersistenceTests",
            dependencies: [
                "PluginPersistence",
                "ProviderPersistence",
                .product(name: "ProviderStorage", package: "LumiProviders"),
            ]
        ),
    ]
)
