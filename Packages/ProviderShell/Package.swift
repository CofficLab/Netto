// swift-tools-version: 6.0
// ProviderShell：Shell/UI 贡献契约及 Factory 创建的默认可观察聚合实现。
// 依赖约束：Foundation + SwiftUI（仅用于贡献视图工厂与观察对象）。
import PackageDescription

let package = Package(
    name: "ProviderShell",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "ProviderShell", targets: ["ProviderShell"])
    ],
    targets: [
        .target(
            name: "ProviderShell"
        ),
        .testTarget(
            name: "ProviderShellTests",
            dependencies: ["ProviderShell"]
        ),
    ]
)
