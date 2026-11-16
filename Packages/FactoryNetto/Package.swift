// swift-tools-version: 6.0
// FactoryNetto：Netto 唯一静态装配点。
// 依赖约束：Netto 插件目录、Provider 契约与 SwiftUI。
// 禁止依赖 App target 代码（App/Bridge）。
import PackageDescription

let package = Package(
    name: "FactoryNetto",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "FactoryNetto", targets: ["FactoryNetto"])
    ],
    dependencies: [
        .package(url: "https://github.com/lumi-softworks/LumiThemePack.git", from: "1.0.12"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.0"),
        .package(name: "PluginPersistence", path: "../PluginPersistence"),
        .package(name: "PluginAppSettings", path: "../PluginAppSettings"),
        .package(name: "PluginEventStore", path: "../PluginEventStore"),
        .package(name: "ProviderAppCatalog", path: "../ProviderAppCatalog"),
        .package(name: "ProviderAppSettings", path: "../ProviderAppSettings"),
        .package(name: "ProviderFirewall", path: "../ProviderFirewall"),
        .package(name: "ProviderFirewallEvents", path: "../ProviderFirewallEvents"),
        .package(name: "ProviderShell", path: "../ProviderShell"),
        .package(url: "https://github.com/lumi-softworks/LumiSettings.git", from: "1.1.0"),
        // 设置窗口外壳（与 Lumi / Wakey 同款：侧边栏顶部 App 图标 + 名称/版本）。
        .package(url: "https://github.com/lumi-softworks/LumiPluginSettingView.git", from: "1.0.3"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.19.0"),
        .package(name: "ProviderStoreKit", path: "../ProviderStoreKit"),
        .package(url: "https://github.com/lumi-softworks/LumiPluginThemePack.git", from: "1.2.1"),
        // 共享远程包：Coffic「关于」页（我们的应用 + 官网 / 隐私政策 / 服务条款）。
        .package(url: "https://github.com/lumi-softworks/LumiPluginAbout.git", from: "3.0.3"),
        .package(name: "PluginFirewallDashboard", path: "../PluginFirewallDashboard"),
        .package(name: "PluginBrandLogo", path: "../PluginBrandLogo"),
        .package(name: "PluginFirewall", path: "../PluginFirewall"),
        .package(name: "PluginStore", path: "../PluginStore"),
        .package(name: "PluginHostActions", path: "../PluginHostActions"),
        .package(name: "ProviderViewEnvironment", path: "../ProviderViewEnvironment"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.18.0"),
        // 共享根视图插件（与 Lumi / Wakey 同一套主窗口体系）。
        // 锁定 1.1.0：与 Wakey 使用的产品/API 一致（1.2 起产品改名为
        // `WorkbenchRootView`，主窗口布局契约不同）。
        .package(url: "https://github.com/lumi-softworks/LumiPluginRootView.git", exact: "1.1.0"),
    ],
    targets: [
        .target(
            name: "FactoryNetto",
            dependencies: [
                .product(name: "LumiThemePack", package: "LumiThemePack"),
                .product(name: "KernelCore", package: "LumiKernel"),
                "PluginPersistence",
                "PluginAppSettings",
                "PluginEventStore",
                "ProviderAppCatalog",
                "ProviderAppSettings",
                "ProviderFirewall",
                "ProviderFirewallEvents",
                "ProviderShell",
                .product(name: "ProviderSettingView", package: "LumiSettings"),
                .product(name: "PluginSettingView", package: "LumiPluginSettingView"),
                .product(name: "ProviderStore", package: "LumiProviders"),
                "ProviderStoreKit",
                .product(name: "ProviderTheme", package: "LumiProviders"),
                .product(name: "PluginThemePack", package: "LumiPluginThemePack"),
                .product(name: "PluginAbout", package: "LumiPluginAbout"),
                "PluginFirewallDashboard",
                "PluginBrandLogo",
                "PluginFirewall",
                "PluginStore",
                .product(name: "PluginHostActions", package: "PluginHostActions"),
                .product(name: "ProviderMenuBar", package: "LumiProviders"),
                .product(name: "ProviderLogo", package: "LumiProviders"),
                .product(name: "ProviderRootView", package: "LumiProviders"),
                .product(name: "ProviderToolbar", package: "LumiProviders"),
                .product(name: "PluginRootView", package: "LumiPluginRootView"),
                "ProviderViewEnvironment",
                "LumiUI",
            ]
        ),
        .testTarget(
            name: "FactoryNettoTests",
            dependencies: [
                "FactoryNetto",
                "PluginBrandLogo",
                "ProviderFirewall",
                "PluginPersistence",
                .product(name: "ProviderLogo", package: "LumiProviders"),
                .product(name: "ProviderRootView", package: "LumiProviders"),
                .product(name: "ProviderToolbar", package: "LumiProviders"),
            ]
        ),
    ]
)
