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
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.0.2"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "PluginThemePack",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderTheme", package: "LumiProviders"),
                .product(name: "LumiUI", package: "LumiUI"),
            ]
        ),
        .testTarget(name: "PluginThemePackTests", dependencies: ["PluginThemePack"]),
    ]
)
