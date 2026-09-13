// swift-tools-version: 6.0
// PluginAgentRules：Agent 规则管理插件，向工具栏注入规则按钮 + popover。
import PackageDescription

let package = Package(
    name: "PluginAgentRules",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginAgentRules", targets: ["PluginAgentRules"])
    ],
    dependencies: [
        .package(name: "KernelCore", path: "../KernelCore"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(name: "ProviderViewEnvironment", path: "../ProviderViewEnvironment"),
        .package(url: "https://github.com/CofficLab/MagicKit", revision: "d04a729"),
    ],
    targets: [
        .target(
            name: "PluginAgentRules",
            dependencies: [
                "KernelCore",
                "ProviderShell",
                "ProviderViewEnvironment",
                .product(name: "MagicCore", package: "MagicKit"),
            ]
        )
    ]
)
