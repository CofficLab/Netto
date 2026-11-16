import Testing
@testable import PluginStore

/// 商店设置页纯逻辑：列表三态推导与加载代际。
@Suite("商店页状态推导")
struct StorePageStateTests {

    @Test("有商品时优先展示内容态（即使正在刷新或已有错误）")
    func contentWinsOverRefreshingAndError() {
        #expect(StoreProductListState.resolve(isRefreshing: true, hasProducts: true, hasError: false) == .content)
        #expect(StoreProductListState.resolve(isRefreshing: false, hasProducts: true, hasError: true) == .content)
        #expect(StoreProductListState.resolve(isRefreshing: true, hasProducts: true, hasError: true) == .content)
    }

    @Test("无商品且正在刷新时为加载态")
    func loadingWithoutProducts() {
        #expect(StoreProductListState.resolve(isRefreshing: true, hasProducts: false, hasError: false) == .loading)
    }

    @Test("无商品且有错误时为错误态")
    func errorWithoutProducts() {
        #expect(StoreProductListState.resolve(isRefreshing: false, hasProducts: false, hasError: true) == .error)
    }

    @Test("无商品、无错误、未刷新时为空态")
    func emptyWithoutProducts() {
        #expect(StoreProductListState.resolve(isRefreshing: false, hasProducts: false, hasError: false) == .empty)
    }

    @Test("只有当代际一致时才应用加载结果")
    func loadPolicyRejectsStaleGeneration() {
        #expect(StoreLoadPolicy.shouldApplyResult(currentGeneration: 2, resultGeneration: 2))
        #expect(!StoreLoadPolicy.shouldApplyResult(currentGeneration: 2, resultGeneration: 1))
        #expect(!StoreLoadPolicy.shouldApplyResult(currentGeneration: 1, resultGeneration: 2))
    }
}
