// swift-tools-version: 6.0
// ProviderAppCatalog：应用元数据/图标中立契约（AppList 等视图的数据来源）。
// 依赖约束：仅 Foundation。禁止 SwiftUI 视图类型与具体 SmartApp 实体。
import PackageDescription

let package = Package(
    name: "ProviderAppCatalog",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "ProviderAppCatalog", targets: ["ProviderAppCatalog"])
    ],
    targets: [
        .target(
            name: "ProviderAppCatalog"
        ),
        .testTarget(
            name: "ProviderAppCatalogTests",
            dependencies: ["ProviderAppCatalog"]
        ),
    ]
)
