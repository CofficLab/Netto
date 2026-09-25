// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemePack",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginThemePack", targets: ["PluginThemePack"])
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../ProviderSettingView"),
        .package(path: "../ProviderTheme"),
        .package(url: "https://github.com/CofficLab/LumiUI", revision: "419c64ec01257f923b4139ede61377566b97b626"),
    ],
    targets: [
        .target(
            name: "PluginThemePack",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderTheme", package: "ProviderTheme"),
                .product(name: "LumiUI", package: "LumiUI"),
            ]
        ),
        .testTarget(name: "PluginThemePackTests", dependencies: ["PluginThemePack"]),
    ]
)
