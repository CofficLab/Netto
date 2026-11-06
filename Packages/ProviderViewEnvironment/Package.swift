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
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.19.0"),
        .package(name: "ProviderStoreKit", path: "../ProviderStoreKit"),
    ],
    targets: [
        .target(
            name: "ProviderViewEnvironment",
            dependencies: [
                "ProviderAppSettings",
                "ProviderFirewall",
                "ProviderFirewallEvents",
                .product(name: "ProviderStore", package: "LumiProviders"),
                "ProviderStoreKit",
            ]
        ),
        .testTarget(
            name: "ProviderViewEnvironmentTests",
            dependencies: ["ProviderViewEnvironment"]
        ),
    ]
)
