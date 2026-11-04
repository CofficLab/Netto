// swift-tools-version: 6.0
// FactoryNetto：Netto 唯一静态装配点。
// 依赖约束：Netto 插件目录、Provider 契约与 SwiftUI。
// 禁止依赖 App target 代码（App/Bridge）。
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
        .package(url: "https://github.com/CofficLab/LumiThemePack.git", from: "1.0.12"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", from: "1.1.0"),
        .package(name: "PluginPersistence", path: "../PluginPersistence"),
        .package(name: "PluginAppSettings", path: "../PluginAppSettings"),
        .package(name: "PluginEventStore", path: "../PluginEventStore"),
        .package(name: "ProviderAppCatalog", path: "../ProviderAppCatalog"),
        .package(name: "ProviderAppSettings", path: "../ProviderAppSettings"),
        .package(name: "ProviderFirewall", path: "../ProviderFirewall"),
        .package(name: "ProviderFirewallEvents", path: "../ProviderFirewallEvents"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(url: "https://github.com/CofficLab/LumiSettings.git", from: "1.1.0"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.18.0"),
        .package(name: "ProviderStoreKit", path: "../ProviderStoreKit"),
        .package(url: "https://github.com/CofficLab/LumiPluginThemePack.git", from: "1.2.1"),
        .package(name: "PluginFirewallDashboard", path: "../PluginFirewallDashboard"),
        .package(name: "PluginFirewall", path: "../PluginFirewall"),
        .package(name: "PluginStore", path: "../PluginStore"),
        .package(name: "PluginHostActions", path: "../PluginHostActions"),
        .package(name: "ProviderMenuBar", path: "../ProviderMenuBar"),
        .package(name: "ProviderViewEnvironment", path: "../ProviderViewEnvironment"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.11.1"),
    ],
    targets: [
        .target(
            name: "FactoryNetto",
            dependencies: [
                .product(name: "LumiThemePack", package: "LumiThemePack"),
                .product(name: "KernelCore", package: "LumiKernel"),
                "PluginPersistence",
                "PluginAppSettings",
                "PluginEventStore",
                "ProviderAppCatalog",
                "ProviderAppSettings",
                "ProviderFirewall",
                "ProviderFirewallEvents",
                "ProviderShell",
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                .product(name: "ProviderStore", package: "LumiProviders"),
                "ProviderStoreKit",
                .product(name: "ProviderTheme", package: "LumiProviders"),
                .product(name: "PluginThemePack", package: "LumiPluginThemePack"),
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
            dependencies: [
                "FactoryNetto",
                "ProviderFirewall",
                "PluginPersistence",
            ]
        ),
    ]
)
