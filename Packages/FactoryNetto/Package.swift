// swift-tools-version: 6.0
// FactoryNetto：Netto 唯一静态装配点。
// 依赖约束：KernelCore、全部 Provider 契约、PluginShell、持久化三插件、SwiftUI。
// 禁止依赖 App target 代码（Core/Plugins/Bridge）与具体业务 Plugin（防火墙等阶段 5+ 追加）。
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
        .package(name: "PluginShell", path: "../PluginShell"),
        .package(name: "PluginPersistence", path: "../PluginPersistence"),
        .package(name: "PluginAppSettings", path: "../PluginAppSettings"),
        .package(name: "PluginEventStore", path: "../PluginEventStore"),
        .package(name: "ProviderAppCatalog", path: "../ProviderAppCatalog"),
        .package(name: "ProviderAppSettings", path: "../ProviderAppSettings"),
        .package(name: "ProviderFirewall", path: "../ProviderFirewall"),
        .package(name: "ProviderFirewallEvents", path: "../ProviderFirewallEvents"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(name: "ProviderStore", path: "../ProviderStore"),
    ],
    targets: [
        .target(
            name: "FactoryNetto",
            dependencies: [
                "KernelCore",
                "PluginShell",
                "PluginPersistence",
                "PluginAppSettings",
                "PluginEventStore",
                "ProviderAppCatalog",
                "ProviderAppSettings",
                "ProviderFirewall",
                "ProviderFirewallEvents",
                "ProviderShell",
                "ProviderStore",
            ]
        ),
        .testTarget(
            name: "FactoryNettoTests",
            dependencies: ["FactoryNetto"]
        ),
    ]
)
