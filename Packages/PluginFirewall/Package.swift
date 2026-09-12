// swift-tools-version: 6.0
// PluginFirewall：防火墙插件（NEFilterManager / OSSystemExtensionManager /
// IPC adapter / observer / daemon 的唯一拥有者）。
// 依赖约束：KernelCore、ProviderFirewall、ProviderFirewallEvents、
// ProviderAppSettings、NettoIPCContracts。禁止 SwiftUI/MagicKit/具体 Repo。
import PackageDescription

let package = Package(
    name: "PluginFirewall",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PluginFirewall", targets: ["PluginFirewall"])
    ],
    dependencies: [
        .package(name: "KernelCore", path: "../KernelCore"),
        .package(name: "ProviderFirewall", path: "../ProviderFirewall"),
        .package(name: "ProviderFirewallEvents", path: "../ProviderFirewallEvents"),
        .package(name: "ProviderAppSettings", path: "../ProviderAppSettings"),
        .package(name: "NettoIPCContracts", path: "../NettoIPCContracts"),
    ],
    targets: [
        .target(
            name: "PluginFirewall",
            dependencies: [
                "KernelCore",
                "ProviderFirewall",
                "ProviderFirewallEvents",
                "ProviderAppSettings",
                "NettoIPCContracts",
            ]
        ),
        .testTarget(
            name: "PluginFirewallTests",
            dependencies: ["PluginFirewall"]
        ),
    ]
)
