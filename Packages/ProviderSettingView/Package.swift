// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderSettingView",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ProviderSettingView", targets: ["ProviderSettingView"])
    ],
    targets: [
        .target(name: "ProviderSettingView"),
        .testTarget(name: "ProviderSettingViewTests", dependencies: ["ProviderSettingView"]),
    ]
)
