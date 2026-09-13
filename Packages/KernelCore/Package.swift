// swift-tools-version: 6.0
// KernelCore：Netto 架构内核 local package。
// 依赖约束：仅 Foundation（及 macOS 15 的 Synchronization 并发原语），
// 禁止 import SwiftUI / AppKit / NetworkExtension / SwiftData / StoreKit / MagicKit / 具体 Plugin。
import PackageDescription

let package = Package(
    name: "KernelCore",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "KernelCore", targets: ["KernelCore"])
    ],
    targets: [
        .target(
            name: "KernelCore"
        ),
        .testTarget(
            name: "KernelCoreTests",
            dependencies: ["KernelCore"]
        ),
    ]
)
