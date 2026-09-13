// swift-tools-version: 6.0
// ProviderSettingsUI：可被多个插件复用的系统设置与扩展操作视图。
import PackageDescription

let package = Package(
    name: "ProviderSettingsUI",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ProviderSettingsUI", targets: ["ProviderSettingsUI"])
    ],
    dependencies: [
        .package(path: "../ProviderFirewall"),
        .package(path: "../ProviderShell"),
        .package(path: "../ProviderViewEnvironment"),
        .package(url: "https://github.com/CofficLab/MagicKit", revision: "d04a729"),
    ],
    targets: [
        .target(
            name: "ProviderSettingsUI",
            dependencies: [
                "ProviderFirewall",
                "ProviderShell",
                "ProviderViewEnvironment",
                .product(name: "MagicCore", package: "MagicKit"),
                .product(name: "MagicUI", package: "MagicKit"),
            ]
        )
    ]
)
