// swift-tools-version: 6.0
// ProviderViewEnvironment：SwiftUI 环境中的共享 Provider 契约键。
import PackageDescription

let package = Package(
    name: "ProviderViewEnvironment",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ProviderViewEnvironment", targets: ["ProviderViewEnvironment"])
    ],
    dependencies: [
        .package(path: "../ProviderAppSettings"),
        .package(path: "../ProviderFirewall"),
        .package(path: "../ProviderFirewallEvents"),
        .package(path: "../ProviderStore"),
    ],
    targets: [
        .target(
            name: "ProviderViewEnvironment",
            dependencies: [
                "ProviderAppSettings",
                "ProviderFirewall",
                "ProviderFirewallEvents",
                "ProviderStore",
            ]
        ),
    ]
)
