// swift-tools-version: 6.0
// FactoryNetto：Netto 唯一静态装配点。
// 依赖约束：Netto 插件目录、Provider 契约与 SwiftUI。
// 禁止依赖 App target 代码（Core/Plugins/Bridge）。
import PackageDescription

let package = Package(
    name: "FactoryNetto",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "FactoryNetto", targets: ["FactoryNetto"])
    ],
    dependencies: [
        .package(name: "KernelCore", path: "../KernelCore"),
        .package(name: "PluginPersistence", path: "../PluginPersistence"),
        .package(name: "PluginAppSettings", path: "../PluginAppSettings"),
        .package(name: "PluginEventStore", path: "../PluginEventStore"),
        .package(name: "ProviderAppCatalog", path: "../ProviderAppCatalog"),
        .package(name: "ProviderAppSettings", path: "../ProviderAppSettings"),
        .package(name: "ProviderFirewall", path: "../ProviderFirewall"),
        .package(name: "ProviderFirewallEvents", path: "../ProviderFirewallEvents"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(name: "ProviderSettingView", path: "../ProviderSettingView"),
        .package(name: "ProviderStore", path: "../ProviderStore"),
        .package(name: "ProviderTheme", path: "../ProviderTheme"),
        .package(name: "PluginThemePack", path: "../PluginThemePack"),
        .package(name: "PluginFirewallDashboard", path: "../PluginFirewallDashboard"),
        .package(name: "PluginFirewall", path: "../PluginFirewall"),
        .package(name: "PluginStore", path: "../PluginStore"),
        .package(name: "PluginHostActions", path: "../PluginHostActions"),
        .package(name: "ProviderMenuBar", path: "../ProviderMenuBar"),
        .package(name: "ProviderViewEnvironment", path: "../ProviderViewEnvironment"),
        .package(url: "https://github.com/CofficLab/LumiUI", revision: "419c64ec01257f923b4139ede61377566b97b626"),
    ],
    targets: [
        .target(
            name: "FactoryNetto",
            dependencies: [
                "KernelCore",
                "PluginPersistence",
                "PluginAppSettings",
                "PluginEventStore",
                "ProviderAppCatalog",
                "ProviderAppSettings",
                "ProviderFirewall",
                "ProviderFirewallEvents",
                "ProviderShell",
                "ProviderSettingView",
                "ProviderStore",
                "ProviderTheme",
                "PluginThemePack",
                "PluginFirewallDashboard",
                "PluginFirewall",
                "PluginStore",
                .product(name: "PluginHostActions", package: "PluginHostActions"),
                "ProviderMenuBar",
                "ProviderViewEnvironment",
                "LumiUI",
            ]
        ),
        .testTarget(
            name: "FactoryNettoTests",
            dependencies: ["FactoryNetto"]
        ),
    ]
)
