// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderTheme",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ProviderTheme", targets: ["ProviderTheme"])
    ],
    targets: [
        .target(name: "ProviderTheme"),
        .testTarget(name: "ProviderThemeTests", dependencies: ["ProviderTheme"]),
    ]
)
