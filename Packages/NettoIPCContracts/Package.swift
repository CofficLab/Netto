// swift-tools-version: 6.0
// NettoIPCContracts：App 与 Network Extension 共享的跨进程契约与值类型。
// 依赖约束：Foundation + NetworkExtension（仅 NETrafficDirection 值类型）。
// 禁止 SwiftUI/SwiftData/StoreKit/App 引用/Plugin 引用。
import PackageDescription

let package = Package(
    name: "NettoIPCContracts",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "NettoIPCContracts", targets: ["NettoIPCContracts"])
    ],
    targets: [
        .target(
            name: "NettoIPCContracts"
        ),
        .testTarget(
            name: "NettoIPCContractsTests",
            dependencies: ["NettoIPCContracts"]
        ),
    ]
)
