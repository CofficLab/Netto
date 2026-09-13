// swift-tools-version: 6.0
// PluginFirewallDashboard：Netto 主界面与防火墙/应用/事件呈现。
// UI 只依赖 Provider 契约和 Shell 聚合，不创建服务或访问持久化实现。
import PackageDescription

let package = Package(
    name: "PluginFirewallDashboard",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginFirewallDashboard", targets: ["PluginFirewallDashboard"])
    ],
    dependencies: [
        .package(name: "KernelCore", path: "../KernelCore"),
        .package(path: "../ProviderSettingsUI"),
        .package(path: "../ProviderViewEnvironment"),
        .package(path: "../ProviderAppSettings"),
        .package(path: "../ProviderFirewall"),
        .package(path: "../ProviderFirewallEvents"),
        .package(path: "../ProviderSettingView"),
        .package(path: "../ProviderShell"),
        .package(path: "../ProviderStore"),
        .package(path: "../ProviderMenuBar"),
        .package(url: "https://github.com/CofficLab/MagicKit", revision: "d04a729"),
    ],
    targets: [
        .target(
            name: "PluginFirewallDashboard",
            dependencies: [
                .product(name: "MagicCore", package: "MagicKit"),
                .product(name: "MagicAlert", package: "MagicKit"),
                .product(name: "MagicUI", package: "MagicKit"),
                .product(name: "MagicBackground", package: "MagicKit"),
                .product(name: "ProviderSettingsUI", package: "ProviderSettingsUI"),
                .product(name: "ProviderAppSettings", package: "ProviderAppSettings"),
                .product(name: "ProviderFirewall", package: "ProviderFirewall"),
                .product(name: "ProviderFirewallEvents", package: "ProviderFirewallEvents"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderShell", package: "ProviderShell"),
                .product(name: "ProviderStore", package: "ProviderStore"),
                .product(name: "ProviderMenuBar", package: "ProviderMenuBar"),
                .product(name: "ProviderViewEnvironment", package: "ProviderViewEnvironment"),
                "KernelCore",
            ]
        )
    ]
)
