// swift-tools-version: 6.0
// PluginBrandLogo：向 LogoProviding 贡献菜单栏品牌图标（对齐 Lumi/Wakey 的 PluginLogo* 插件）。
import PackageDescription

let package = Package(
    name: "PluginBrandLogo",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PluginBrandLogo", targets: ["PluginBrandLogo"])
    ],
    dependencies: [
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.0"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.19.0"),
    ],
    targets: [
        .target(
            name: "PluginBrandLogo",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderLogo", package: "LumiProviders"),
            ]
        ),
        .testTarget(
            name: "PluginBrandLogoTests",
            dependencies: [
                "PluginBrandLogo",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderLogo", package: "LumiProviders"),
            ]
        ),
    ]
)
