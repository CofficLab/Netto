// swift-tools-version: 6.0
// PluginShell：Shell 宿主实现（工具栏/设置/窗口/Toast 贡献聚合）。
// 依赖约束：KernelCore、ProviderShell、Combine、SwiftUI。
import PackageDescription

let package = Package(
    name: "PluginShell",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PluginShell", targets: ["PluginShell"])
    ],
    dependencies: [
        .package(name: "KernelCore", path: "../KernelCore"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
    ],
    targets: [
        .target(
            name: "PluginShell",
            dependencies: [
                "KernelCore",
                "ProviderShell",
            ]
        ),
        .testTarget(
            name: "PluginShellTests",
            dependencies: ["PluginShell"]
        ),
    ]
)
