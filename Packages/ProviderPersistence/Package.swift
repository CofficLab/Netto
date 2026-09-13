// swift-tools-version: 6.0
// ProviderPersistence：共享 SwiftData schema、数据库配置与容器契约。
import PackageDescription

let package = Package(
    name: "ProviderPersistence",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ProviderPersistence", targets: ["ProviderPersistence"])
    ],
    targets: [
        .target(name: "ProviderPersistence"),
    ]
)
