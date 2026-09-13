// swift-tools-version: 6.0
// ProviderAppSettings：应用允许/阻止规则能力中立契约。
// 依赖约束：仅 Foundation。禁止 SwiftData/SwiftUI/具体 Repo。
import PackageDescription

let package = Package(
    name: "ProviderAppSettings",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "ProviderAppSettings", targets: ["ProviderAppSettings"])
    ],
    targets: [
        .target(
            name: "ProviderAppSettings"
        ),
        .testTarget(
            name: "ProviderAppSettingsTests",
            dependencies: ["ProviderAppSettings"]
        ),
    ]
)
