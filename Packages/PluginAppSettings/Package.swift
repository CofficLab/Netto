// swift-tools-version: 6.0
// PluginAppSettings：应用允许/阻止规则存储实现插件。
// 依赖约束：KernelCore、ProviderAppSettings、ProviderPersistence、OSLog。禁止 SwiftUI/具体 Repo。
import PackageDescription

let package = Package(
    name: "PluginAppSettings",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PluginAppSettings", targets: ["PluginAppSettings"])
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(name: "PluginPersistence", path: "../PluginPersistence"),
        .package(name: "ProviderAppSettings", path: "../ProviderAppSettings"),
        .package(name: "ProviderPersistence", path: "../ProviderPersistence"),
    ],
    targets: [
        .target(
            name: "PluginAppSettings",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                "ProviderAppSettings",
                "ProviderPersistence",
            ]
        ),
        .testTarget(
            name: "PluginAppSettingsTests",
            dependencies: ["PluginAppSettings", "PluginPersistence", .product(name: "KernelCore", package: "LumiKernel"), "ProviderAppSettings"]
        ),
    ]
)
