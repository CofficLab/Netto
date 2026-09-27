// swift-tools-version: 6.0
// PluginStore：StoreKit 商店插件（旧 StoreService/StoreState/DTO/购买恢复订阅 UI 的唯一拥有者）。
// 依赖约束：KernelCore、ProviderStore、ProviderShell（ShellCenter）、
// MagicKit（视图层 MagicCore/MagicUI/MagicAlert/MagicBackground）。
// 通过 StoreProviding 向其他插件/App 暴露中立 Snapshot；Kernel 不允许 import StoreKit。
import PackageDescription

let package = Package(
    name: "PluginStore",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PluginStore", targets: ["PluginStore"])
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(name: "ProviderStore", path: "../ProviderStore"),
        .package(url: "https://github.com/CofficLab/LumiSettings.git", from: "1.0.1"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(url: "https://github.com/CofficLab/MagicKit", branch: "fix/swift6-strict-init"),
    ],
    targets: [
        .target(
            name: "PluginStore",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                "ProviderStore",
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                "ProviderShell",
                .product(name: "MagicCore", package: "MagicKit"),
                .product(name: "MagicUI", package: "MagicKit"),
                .product(name: "MagicAlert", package: "MagicKit"),
                .product(name: "MagicBackground", package: "MagicKit"),
            ]
        ),
        .testTarget(
            name: "PluginStoreTests",
            dependencies: ["PluginStore", .product(name: "KernelCore", package: "LumiKernel"), "ProviderStore"]
        ),
    ]
)
