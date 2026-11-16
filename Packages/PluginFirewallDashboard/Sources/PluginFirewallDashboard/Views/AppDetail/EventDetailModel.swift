import Foundation
import Observation
import ProviderFirewallEvents

/// 事件详情的数据源：并发加载时只采纳最新一次请求的结果。
///
/// 请求令牌在调用方同步领取（`beginRequest`），因此无论两个 Task 谁先开始
/// 执行，后发起的请求总是最后的令牌；晚到的旧响应会被丢弃。
///
/// 线程/actor：`@MainActor`，直接驱动视图状态。
@MainActor
@Observable
final class EventDetailModel {
    private(set) var events: [FirewallEventSnapshot] = []
    private(set) var totalCount = 0
    private(set) var isLoading = false

    private var generation = 0

    /// 登记一次新请求并返回其令牌。
    func beginRequest() -> Int {
        generation += 1
        return generation
    }

    /// 执行加载；只有令牌仍是最新时才写回状态。
    func load(
        _ query: FirewallEventQuery,
        token: Int,
        from provider: (any FirewallEventsProviding)?
    ) async {
        guard let provider else {
            guard token == generation else { return }
            events = []
            totalCount = 0
            isLoading = false
            return
        }

        if token == generation {
            isLoading = true
        }

        do {
            let page = try await provider.fetchPage(query)
            guard token == generation else { return }
            events = page.events
            totalCount = page.totalCount
            isLoading = false
        } catch {
            guard token == generation else { return }
            events = []
            isLoading = false
        }
    }
}
