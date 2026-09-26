// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderSettingView",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ProviderSettingView", targets: ["ProviderSettingView"])
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "ProviderSettingView",
            dependencies: ["LumiUI"]
        ),
        .testTarget(name: "ProviderSettingViewTests", dependencies: ["ProviderSettingView"]),
    ]
)
