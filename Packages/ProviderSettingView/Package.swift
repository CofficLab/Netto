// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderSettingView",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ProviderSettingView", targets: ["ProviderSettingView"])
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiUI", revision: "419c64ec01257f923b4139ede61377566b97b626"),
    ],
    targets: [
        .target(
            name: "ProviderSettingView",
            dependencies: ["LumiUI"]
        ),
        .testTarget(name: "ProviderSettingViewTests", dependencies: ["ProviderSettingView"]),
    ]
)
