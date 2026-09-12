// swift-tools-version: 6.0
// ProviderStore：StoreKit 能力中立契约（产品/权益 Snapshot + 命令）。
// 依赖约束：仅 Foundation。禁止 StoreKit.Product/交易类型越过边界。
import PackageDescription

let package = Package(
    name: "ProviderStore",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "ProviderStore", targets: ["ProviderStore"])
    ],
    targets: [
        .target(
            name: "ProviderStore"
        ),
        .testTarget(
            name: "ProviderStoreTests",
            dependencies: ["ProviderStore"]
        ),
    ]
)
