// swift-tools-version: 6.0
// ProviderStoreKit：Netto 特有的商店能力契约。
// 依赖约束：仅共享的 ProviderStore 契约（ProviderStore）。禁止 StoreKit 越过边界。
import PackageDescription

let package = Package(
    name: "ProviderStoreKit",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "ProviderStoreKit", targets: ["ProviderStoreKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.18.0"),
    ],
    targets: [
        .target(
            name: "ProviderStoreKit",
            dependencies: [
                .product(name: "ProviderStore", package: "LumiProviders"),
            ],
            path: "Sources/ProviderStoreKit"
        ),
        .testTarget(
            name: "ProviderStoreKitTests",
            dependencies: ["ProviderStoreKit"],
            path: "Tests/ProviderStoreKitTests"
        ),
    ]
)
