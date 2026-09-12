import Foundation
import KernelCore
import OSLog
import PluginShell
import ProviderShell
import ProviderStore
import StoreKit
import SwiftUI

/// Store 插件：StoreService/StoreState/DTO/购买恢复订阅 UI 的装配点与唯一拥有者。
///
/// 生命周期：
/// - onBoot：注册 `StoreProviding`（owner=self.id），向 ShellCenter 贡献设置入口
///   与商店窗口内容，并启动交易监听与权益校准（旧 `StoreService.bootstrap()` 语义）。
/// - onShutdown：取消监听任务、撤销贡献（Kernel 随 owner 自动撤回 Provider）。
///
/// 线程/actor：`@MainActor`；StoreKit 调用在内部 Task 中串行执行；
/// 权益变更经 `observeEntitlement()` AsyncStream 暴露（替代旧 Notification 消费路径）。
@MainActor
public final class PluginStore: SuperPlugin, StoreProviding {
    public let id = "store"
    public var order: Int { 40 }
    public var dependencies: [String] { [] }
    public let metadata = PluginMetadata(
        name: "Store",
        version: "1.0",
        policy: .enabledByDefault,
        summary: "StoreKit 商店：购买/恢复/订阅/权益快照"
    )

    /// 交易监听 + 权益校准任务句柄（onShutdown 取消，避免留下后台任务）。
    private var storeTask: Task<Void, Never>?

    public init() {}

    // MARK: - SuperPlugin

    public func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(SettingsProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        try kernel.registerProvider(self, for: StoreProviding.self, owner: id)
        contribute(into: shell)
        // 启动监听 + 校准（幂等由 kernel 保证只 onBoot 一次）。
        storeTask = Task { [weak self] in
            await self?.runStoreServices()
        }
    }

    public func onShutdown() async {
        storeTask?.cancel()
        storeTask = nil
    }

    /// 向给定 ShellCenter 注册设置入口与窗口内容（预览与生产共用）。
    public func contribute(into shell: ShellCenter) {
        shell.registerEntry(SettingsEntry(
            id: "store",
            order: 40,
            ownerPluginID: id
        ) {
            AnyView(StoreBtn())
        })
        shell.registerContent(WindowContentContribution(
            id: "store-window",
            title: "Store - TravelMode",
            ownerPluginID: id
        ) {
            StoreWindowContent.windowView()
        })
    }

    // MARK: - StoreProviding

    public var entitlement: StoreEntitlementSnapshot {
        mapEntitlement(StoreState.cachedPurchaseInfo())
    }

    public func loadProducts() async throws -> [StoreProductSnapshot] {
        let groups = try await StoreService.fetchAllProducts()
        var result: [StoreProductSnapshot] = []
        for dto in groups.cars + groups.nonRenewables + groups.fuel {
            result.append(StoreProductSnapshot(
                id: dto.id,
                displayName: dto.displayName,
                price: dto.displayPrice,
                tier: StoreTier(rawValue: StoreConfig.tier(for: dto.id).rawValue) ?? .none,
                isSubscription: false
            ))
        }
        for group in groups.subscriptionGroups {
            for dto in group.subscriptions {
                result.append(StoreProductSnapshot(
                    id: dto.id,
                    displayName: dto.displayName,
                    price: dto.displayPrice,
                    tier: StoreTier(rawValue: StoreConfig.tier(for: dto.id).rawValue) ?? .none,
                    isSubscription: true
                ))
            }
        }
        return result
    }

    public func purchase(_ productID: String) async throws {
        _ = try await StoreService.purchase(productID: productID)
    }

    public func restore() async throws {
        // StoreKit 2 无独立 restore API：重放 currentEntitlements 校准本地状态。
        await StoreState.calibrateFromCurrentEntitlements()
    }

    public func observeEntitlement() -> AsyncStream<StoreEntitlementSnapshot> {
        AsyncStream { continuation in
            // 先推当前快照（订阅者立即可见），再订阅后续变更；避免订阅竞态。
            continuation.yield(self.entitlement)
            let observer = Task { @MainActor [weak self] in
                // 显式 MainActor 订阅：保证与调用方同一执行器，杜绝订阅竞态。
                for await _ in NotificationCenter.default.notifications(named: .storeEntitlementUpdated) {
                    continuation.yield(self?.entitlement ?? .none)
                }
            }
            continuation.onTermination = { _ in observer.cancel() }
        }
    }

    // MARK: - Private

    private func mapEntitlement(_ info: PurchaseInfo) -> StoreEntitlementSnapshot {
        StoreEntitlementSnapshot(
            tier: StoreTier(rawValue: info.tier.rawValue) ?? .none,
            expiresAt: info.expiresAt
        )
    }

    /// 启动交易监听与权益校准（可取消；校准先于监听，恢复旧 bootstrap 语义）。
    private func runStoreServices() async {
        await StoreState.calibrateFromCurrentEntitlements()
        await StoreService.observeTransactionUpdates()
    }
}

// MARK: - Notification（模块内权益变更桥）

extension Notification.Name {
    /// 权益快照已更新（StoreState.update 后发出；observeEntitlement 桥接）。
    static let storeEntitlementUpdated = Notification.Name("store.entitlement.updated")
}
