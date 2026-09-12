// swift-tools-version: 6.0
// ProviderShell：Shell/UI 贡献契约（Toolbar/Settings/Window/Toast）。
// 依赖约束：Foundation + SwiftUI（仅用于贡献工厂的 AnyView 构造闭包）。
// 不得包含业务逻辑、Provider 注册表或 ObservableObject 广播。
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
