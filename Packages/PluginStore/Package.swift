// swift-tools-version: 6.0
// PluginStore：StoreKit 商店插件（旧 StoreService/StoreState/DTO/购买恢复订阅 UI 的唯一拥有者）。
// 依赖约束：KernelCore、ProviderStore、ProviderShell（ShellCenter）、LumiUI。
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
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.0"),
        .package(url: "https://github.com/lumi-softworks/LumiStoreKit.git", from: "1.0.1"),
        .package(name: "ProviderStoreKit", path: "../ProviderStoreKit"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.19.0"),
        .package(url: "https://github.com/lumi-softworks/LumiSettings.git", from: "1.1.0"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.18.0"),
    ],
    targets: [
        .target(
            name: "PluginStore",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderStore", package: "LumiProviders"),
                .product(name: "KitStoreKit", package: "LumiStoreKit"),
                "ProviderStoreKit",
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                "ProviderShell",
                "LumiUI",
            ]
        ),
        .testTarget(
            name: "PluginStoreTests",
            dependencies: ["PluginStore", .product(name: "KernelCore", package: "LumiKernel"), .product(name: "ProviderStore", package: "LumiProviders"), .product(name: "KitStoreKit", package: "LumiStoreKit"), "ProviderStoreKit"]
        ),
    ]
)
