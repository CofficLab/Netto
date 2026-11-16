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
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.0"),
        .package(path: "../ProviderViewEnvironment"),
        .package(path: "../ProviderAppSettings"),
        .package(path: "../ProviderFirewall"),
        .package(path: "../ProviderFirewallEvents"),
        .package(url: "https://github.com/lumi-softworks/LumiSettings.git", from: "1.1.0"),
        .package(path: "../ProviderShell"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.19.0"),
        .package(name: "ProviderStoreKit", path: "../ProviderStoreKit"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.18.0"),
    ],
    targets: [
        .target(
            name: "PluginFirewallDashboard",
            dependencies: [
                .product(name: "ProviderAppSettings", package: "ProviderAppSettings"),
                .product(name: "ProviderFirewall", package: "ProviderFirewall"),
                .product(name: "ProviderFirewallEvents", package: "ProviderFirewallEvents"),
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                .product(name: "ProviderShell", package: "ProviderShell"),
                .product(name: "ProviderStore", package: "LumiProviders"),
                "ProviderStoreKit",
                .product(name: "ProviderMenuBar", package: "LumiProviders"),
                .product(name: "ProviderToolbar", package: "LumiProviders"),
                .product(name: "ProviderViewEnvironment", package: "ProviderViewEnvironment"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "LumiUI", package: "LumiUI"),
            ]
        ),
        .testTarget(
            name: "PluginFirewallDashboardTests",
            dependencies: ["PluginFirewallDashboard"]
        )
    ]
)
