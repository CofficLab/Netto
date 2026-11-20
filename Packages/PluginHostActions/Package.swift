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
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.0"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.19.0"),
        .package(name: "ProviderPersistence", path: "../ProviderPersistence"),
        .package(name: "ProviderAppSettings", path: "../ProviderAppSettings"),
        .package(name: "ProviderFirewallEvents", path: "../ProviderFirewallEvents"),
        .package(name: "ProviderFirewall", path: "../ProviderFirewall"),
        .package(url: "https://github.com/lumi-softworks/LumiSettings.git", from: "1.1.0"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(name: "ProviderViewEnvironment", path: "../ProviderViewEnvironment"),
        .package(name: "PluginBrandLogo", path: "../PluginBrandLogo"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.18.0"),
    ],
    targets: [
        .target(
            name: "PluginHostActions",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderStorage", package: "LumiProviders"),
                "ProviderPersistence",
                "ProviderAppSettings",
                "ProviderFirewallEvents",
                "ProviderFirewall",
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                "ProviderShell",
                "ProviderViewEnvironment",
                "PluginBrandLogo",
                "LumiUI",
            ]
        ),
        .testTarget(
            name: "PluginHostActionsTests",
            dependencies: ["PluginHostActions"]
        )
    ]
)
