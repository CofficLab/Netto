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
        .package(name: "KernelCore", path: "../KernelCore"),
        .package(name: "ProviderPersistence", path: "../ProviderPersistence"),
        .package(name: "ProviderSettingsUI", path: "../ProviderSettingsUI"),
        .package(name: "ProviderAppSettings", path: "../ProviderAppSettings"),
        .package(name: "ProviderFirewallEvents", path: "../ProviderFirewallEvents"),
        .package(name: "ProviderSettingView", path: "../ProviderSettingView"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(name: "ProviderViewEnvironment", path: "../ProviderViewEnvironment"),
        .package(url: "https://github.com/CofficLab/MagicKit", revision: "d04a729"),
        .package(url: "https://github.com/CofficLab/LumiUI", revision: "419c64ec01257f923b4139ede61377566b97b626"),
    ],
    targets: [
        .target(
            name: "PluginHostActions",
            dependencies: [
                "KernelCore",
                "ProviderPersistence",
                "ProviderSettingsUI",
                "ProviderAppSettings",
                "ProviderFirewallEvents",
                "ProviderSettingView",
                "ProviderShell",
                "ProviderViewEnvironment",
                .product(name: "MagicCore", package: "MagicKit"),
                .product(name: "MagicUI", package: "MagicKit"),
                "LumiUI",
            ]
        )
    ]
)
