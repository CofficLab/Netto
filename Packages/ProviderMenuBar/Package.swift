// swift-tools-version: 6.0
// ProviderMenuBar：菜单栏常驻内容与 popover 内容贡献契约。
import PackageDescription

let package = Package(
    name: "ProviderMenuBar",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ProviderMenuBar", targets: ["ProviderMenuBar"])
    ],
    targets: [
        .target(name: "ProviderMenuBar"),
        .testTarget(name: "ProviderMenuBarTests", dependencies: ["ProviderMenuBar"]),
    ]
)
