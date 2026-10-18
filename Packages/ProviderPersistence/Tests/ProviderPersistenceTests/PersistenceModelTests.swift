import Foundation
import SwiftData
import Testing
@testable import ProviderPersistence

/// 持久化模型测试：字段映射、`isAllowed` 语义与内存容器往返。
@MainActor
@Suite("持久化模型")
struct PersistenceModelTests {

    // MARK: - AppSetting

    @Test("AppSetting 保存 appId 与 allowed")
    func appSettingProperties() {
        let setting = AppSetting(appId: "com.app", allowed: true)
        #expect(setting.appId == "com.app")
        #expect(setting.allowed)

        let denied = AppSetting(appId: "com.other", allowed: false)
        #expect(!denied.allowed)
    }

    // MARK: - FirewallEventModel

    @Test("statusRawValue 0 视为放行，非 0 视为拒绝")
    func isAllowedSemantics() {
        // 兼容红线：0=放行，1=拒绝，与旧模型 isAllowed 一致。
        let allowed = FirewallEventModel(
            address: "example.com", port: "443",
            statusRawValue: 0, directionRawValue: 2
        )
        #expect(allowed.isAllowed)

        let rejected = FirewallEventModel(
            address: "evil.example", port: "80",
            statusRawValue: 1, directionRawValue: 1
        )
        #expect(!rejected.isAllowed)
    }

    @Test("默认参数生成唯一 id、当前时间与空来源应用")
    func firewallEventDefaults() {
        let before = Date()
        let event = FirewallEventModel(
            address: "example.com", port: "443",
            statusRawValue: 0, directionRawValue: 2
        )
        #expect(!event.id.isEmpty)
        #expect(UUID(uuidString: event.id) != nil, "默认 id 应为合法 UUID")
        #expect(event.time >= before)
        #expect(event.sourceAppIdentifier.isEmpty)
        #expect(event.address == "example.com")
        #expect(event.port == "443")
    }

    @Test("显式 id 与时间被保留")
    func firewallEventExplicitValues() {
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        let event = FirewallEventModel(
            id: "fixed-id", time: when,
            address: "a.example", port: "8080",
            sourceAppIdentifier: "com.app",
            statusRawValue: 1, directionRawValue: 1
        )
        #expect(event.id == "fixed-id")
        #expect(event.time == when)
        #expect(event.sourceAppIdentifier == "com.app")
        #expect(!event.isAllowed)
    }

    // MARK: - 内存容器往返

    @Test("事件写入后可按时间范围与来源应用查回")
    func firewallEventRoundTrip() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        let start = Date(timeIntervalSince1970: 1_600_000_000)
        let inside = FirewallEventModel(
            time: start.addingTimeInterval(500),
            address: "inside.example", port: "443",
            sourceAppIdentifier: "com.app",
            statusRawValue: 0, directionRawValue: 2
        )
        let outside = FirewallEventModel(
            time: start.addingTimeInterval(5_000),
            address: "outside.example", port: "80",
            sourceAppIdentifier: "com.app",
            statusRawValue: 1, directionRawValue: 1
        )
        context.insert(inside)
        context.insert(outside)
        try context.save()

        let windowStart = start.addingTimeInterval(100)
        let windowEnd = start.addingTimeInterval(1_000)
        let fetched = try context.fetch(FetchDescriptor<FirewallEventModel>(
            predicate: #Predicate { $0.time >= windowStart && $0.time <= windowEnd }
        ))
        #expect(fetched.count == 1)
        #expect(fetched.first?.address == "inside.example")
        #expect(fetched.first?.isAllowed == true)

        let allForApp = try context.fetch(FetchDescriptor<FirewallEventModel>(
            predicate: #Predicate { $0.sourceAppIdentifier == "com.app" }
        ))
        #expect(allForApp.count == 2)
    }

    @Test("AppSetting 写入后保留 allow/deny 语义")
    func appSettingRoundTrip() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        context.insert(AppSetting(appId: "com.allowed", allowed: true))
        context.insert(AppSetting(appId: "com.denied", allowed: false))
        try context.save()

        let all = try context.fetch(FetchDescriptor<AppSetting>())
        #expect(all.count == 2)

        let allowed = try #require(all.first { $0.appId == "com.allowed" })
        let denied = try #require(all.first { $0.appId == "com.denied" })
        #expect(allowed.allowed)
        #expect(!denied.allowed)
    }

    /// 构建仅含本包两个模型的内存容器，避免污染真实数据库目录。
    private func makeInMemoryContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema([AppSetting.self, FirewallEventModel.self]),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
