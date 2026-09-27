// swift-tools-version: 6.0
// PluginHostActions：应用设置、调试面板与 macOS Host 操作的插件和视图。
import PackageDescription

let package = Package(
    name: "PluginHostActions",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginHostActions", targets: ["PluginHostActions"])
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(name: "ProviderPersistence", path: "../ProviderPersistence"),
        .package(name: "ProviderAppSettings", path: "../ProviderAppSettings"),
        .package(name: "ProviderFirewallEvents", path: "../ProviderFirewallEvents"),
        .package(name: "ProviderFirewall", path: "../ProviderFirewall"),
        .package(url: "https://github.com/CofficLab/LumiSettings.git", from: "1.0.1"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(name: "ProviderViewEnvironment", path: "../ProviderViewEnvironment"),
        .package(url: "https://github.com/CofficLab/MagicKit", branch: "fix/swift6-strict-init"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "PluginHostActions",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                "ProviderPersistence",
                "ProviderAppSettings",
                "ProviderFirewallEvents",
                "ProviderFirewall",
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                "ProviderShell",
                "ProviderViewEnvironment",
                .product(name: "MagicCore", package: "MagicKit"),
                .product(name: "MagicUI", package: "MagicKit"),
                "LumiUI",
            ]
        )
    ]
)
