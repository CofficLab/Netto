import KernelCore
import ProviderLogo
import Testing
@testable import PluginBrandLogo

@MainActor
@Suite("BrandLogoPlugin")
struct BrandLogoPluginTests {

    private func makeKernel() throws -> (KernelCoreContainer, BrandLogoPlugin) {
        let kernel = KernelCoreContainer()
        try kernel.registerHostProvider(LogoProviding.self, DefaultLogoProviding())
        let plugin = BrandLogoPlugin()
        try kernel.start(plugins: [plugin])
        return (kernel, plugin)
    }

    @Test("插件元数据：id / 顺序 / 始终启用（对齐 Lumi/Wakey Logo 插件）")
    func metadata() {
        let plugin = BrandLogoPlugin()

        #expect(plugin.id == "brand-logo")
        #expect(plugin.order == 20)
        #expect(plugin.metadata.id == "brand-logo")
        #expect(plugin.metadata.name == "品牌图标")
        #expect(plugin.metadata.policy == .alwaysOn)
    }

    @Test("onBoot 向 LogoProviding 注册品牌图标")
    func onBootRegistersLogoItem() throws {
        let (kernel, _) = try makeKernel()
        let logo = try #require(kernel.resolveProvider((any LogoProviding).self))

        #expect(logo.highestPriorityLogoItem?.id == "brand-logo")
    }

    @Test("onShutdown 撤回品牌图标")
    func onShutdownUnregistersLogoItem() throws {
        let (kernel, plugin) = try makeKernel()
        let logo = try #require(kernel.resolveProvider((any LogoProviding).self))

        try plugin.onShutdown(kernel: kernel)

        #expect(logo.allLogoItems.isEmpty)
    }
}
