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
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../ProviderViewEnvironment"),
        .package(path: "../ProviderAppSettings"),
        .package(path: "../ProviderFirewall"),
        .package(path: "../ProviderFirewallEvents"),
        .package(url: "https://github.com/CofficLab/LumiSettings.git", from: "1.0.1"),
        .package(path: "../ProviderShell"),
        .package(path: "../ProviderStore"),
        .package(path: "../ProviderMenuBar"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
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
                .product(name: "ProviderStore", package: "ProviderStore"),
                .product(name: "ProviderMenuBar", package: "ProviderMenuBar"),
                .product(name: "ProviderViewEnvironment", package: "ProviderViewEnvironment"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "LumiUI", package: "LumiUI"),
            ]
        )
    ]
)
