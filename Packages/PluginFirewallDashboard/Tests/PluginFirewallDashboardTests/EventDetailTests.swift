import Foundation
import ProviderFirewallEvents
import Testing
@testable import PluginFirewallDashboard

// MARK: - 测试替身

/// 可控事件源：每个请求挂起，直到测试显式恢复或抛错。
@MainActor
private final class ControlledEventsProvider: FirewallEventsProviding {
    private var continuations: [Int: CheckedContinuation<FirewallEventPage, Error>] = [:]

    private func key(_ status: FirewallEventDecision?) -> Int {
        status?.storageRawValue ?? -1
    }

    func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage {
        try await withCheckedThrowingContinuation { continuation in
            continuations[key(query.status)] = continuation
        }
    }

    func resume(status: FirewallEventDecision?, with page: FirewallEventPage) {
        continuations.removeValue(forKey: key(status))?.resume(returning: page)
    }

    func fail(status: FirewallEventDecision?, with error: Error) {
        continuations.removeValue(forKey: key(status))?.resume(throwing: error)
    }

    func waitForRequests(_ count: Int, timeout: Duration = .seconds(2)) async {
        let deadline = ContinuousClock.now + timeout
        while continuations.count < count, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    func count(_ query: FirewallEventCountQuery) async throws -> Int { 0 }
    func totalCount() async throws -> Int { 0 }
    func allAppIds() async throws -> [String] { [] }
    func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) async throws -> [FirewallEventSnapshot] { [] }
    func appIdsSince(_ date: Date) async throws -> [String] { [] }
    func create(_ event: FirewallEventSnapshot) async throws {}
    func deleteByAppId(_ appId: String) async throws {}
    func deleteAll() async throws -> Int { 0 }
    func cleanupOlderThan(days: Int) async throws -> Int { 0 }
    func triggerMaintenance() async throws -> FirewallMaintenanceResult { FirewallMaintenanceResult() }
    func observeChanges() -> AsyncStream<FirewallEventChange> { AsyncStream { _ in } }
}

/// 立即返回固定页面的事件源（第一页有数据，后续页为空）。
@MainActor
private final class StubEventsProvider: FirewallEventsProviding {
    var page = FirewallEventPage(events: [], totalCount: 0, page: 0, pageSize: 0)

    func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage {
        guard query.page == 0 else {
            return FirewallEventPage(events: [], totalCount: page.totalCount, page: query.page, pageSize: query.pageSize)
        }
        return page
    }

    func count(_ query: FirewallEventCountQuery) async throws -> Int { 0 }
    func totalCount() async throws -> Int { 0 }
    func allAppIds() async throws -> [String] { [] }
    func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) async throws -> [FirewallEventSnapshot] { [] }
    func appIdsSince(_ date: Date) async throws -> [String] { [] }
    func create(_ event: FirewallEventSnapshot) async throws {}
    func deleteByAppId(_ appId: String) async throws {}
    func deleteAll() async throws -> Int { 0 }
    func cleanupOlderThan(days: Int) async throws -> Int { 0 }
    func triggerMaintenance() async throws -> FirewallMaintenanceResult { FirewallMaintenanceResult() }
    func observeChanges() -> AsyncStream<FirewallEventChange> { AsyncStream { _ in } }
}

private func makeEvent(
    id: String = UUID().uuidString,
    address: String = "example.com",
    status: FirewallEventDecision = .allowed,
    direction: FirewallTrafficDirection = .outbound
) -> FirewallEventSnapshot {
    FirewallEventSnapshot(
        id: id,
        time: Date(timeIntervalSince1970: 1_700_000_000),
        address: address,
        port: "443",
        sourceAppIdentifier: "com.app",
        status: status,
        direction: direction,
        appId: "com.app"
    )
}

// MARK: - #2 请求竞态

@MainActor
@Suite("EventDetailModel 请求竞态")
struct EventDetailModelTests {

    @Test("旧请求晚到不会覆盖新请求的结果")
    func staleResultDoesNotOverwriteNewer() async {
        let provider = ControlledEventsProvider()
        let model = EventDetailModel()

        let staleToken = model.beginRequest()
        let staleTask = Task {
            await model.load(FirewallEventQuery(status: .allowed), token: staleToken, from: provider)
        }
        let freshToken = model.beginRequest()
        let freshTask = Task {
            await model.load(FirewallEventQuery(status: .rejected), token: freshToken, from: provider)
        }

        await provider.waitForRequests(2)

        let rejected = makeEvent(id: "fresh", status: .rejected)
        provider.resume(
            status: .rejected,
            with: FirewallEventPage(events: [rejected], totalCount: 7, page: 0, pageSize: 20)
        )
        await freshTask.value
        #expect(model.events.map(\.id) == ["fresh"])
        #expect(model.totalCount == 7)

        // 较慢的旧请求最后完成：结果必须被丢弃。
        provider.resume(
            status: .allowed,
            with: FirewallEventPage(events: [], totalCount: 0, page: 0, pageSize: 20)
        )
        await staleTask.value
        #expect(model.events.map(\.id) == ["fresh"])
        #expect(model.totalCount == 7)
        #expect(model.isLoading == false)
    }

    @Test("旧请求失败不会清空新请求的结果")
    func staleFailureDoesNotClearNewer() async {
        let provider = ControlledEventsProvider()
        let model = EventDetailModel()
        struct StaleError: Error {}

        let staleToken = model.beginRequest()
        let staleTask = Task {
            await model.load(FirewallEventQuery(status: .allowed), token: staleToken, from: provider)
        }
        let freshToken = model.beginRequest()
        let freshTask = Task {
            await model.load(FirewallEventQuery(status: .rejected), token: freshToken, from: provider)
        }

        await provider.waitForRequests(2)
        provider.resume(
            status: .rejected,
            with: FirewallEventPage(events: [makeEvent(id: "fresh", status: .rejected)], totalCount: 1, page: 0, pageSize: 20)
        )
        await freshTask.value

        provider.fail(status: .allowed, with: StaleError())
        await staleTask.value

        #expect(model.events.map(\.id) == ["fresh"])
        #expect(model.totalCount == 1)
    }
}

// MARK: - #3 导出结果

@MainActor
@Suite("EventCSVExport")
struct EventCSVExportTests {

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("netpause-export-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("契约缺失时抛出 providerUnavailable")
    func providerUnavailableThrows() async {
        await #expect(throws: EventCSVExport.ExportError.providerUnavailable) {
            try await EventCSVExport.export(
                provider: nil,
                appId: "com.app",
                status: nil,
                direction: nil,
                directory: FileManager.default.temporaryDirectory
            )
        }
    }

    @Test("下载目录不可用时抛出 downloadsUnavailable")
    func downloadsUnavailableThrows() async {
        await #expect(throws: EventCSVExport.ExportError.downloadsUnavailable) {
            try await EventCSVExport.export(
                provider: StubEventsProvider(),
                appId: "com.app",
                status: nil,
                direction: nil,
                directory: nil
            )
        }
    }

    @Test("抓取失败向上抛出")
    func fetchFailurePropagates() async {
        struct FetchError: Error {}
        let provider = ControlledEventsProvider()
        let directory = try? makeDirectory()
        defer {
            if let directory { try? FileManager.default.removeItem(at: directory) }
        }

        let task = Task {
            try await EventCSVExport.export(
                provider: provider,
                appId: "com.app",
                status: nil,
                direction: nil,
                directory: directory
            )
        }
        await provider.waitForRequests(1)
        provider.fail(status: nil, with: FetchError())

        do {
            _ = try await task.value
            Issue.record("预期导出抛出错误")
        } catch {
            #expect(error is FetchError)
        }
    }

    @Test("写入成功返回文件并转义逗号")
    func writesCSVAndReturnsURL() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let provider = StubEventsProvider()
        provider.page = FirewallEventPage(
            events: [makeEvent(id: "e1", address: "example,com")],
            totalCount: 1,
            page: 0,
            pageSize: 200
        )

        let url = try await EventCSVExport.export(
            provider: provider,
            appId: "com.app",
            status: nil,
            direction: nil,
            directory: directory,
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )

        #expect(url.lastPathComponent == "logs-com.app-1700000000.csv")
        #expect(FileManager.default.fileExists(atPath: url.path))

        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.hasPrefix(EventCSVExport.header))
        #expect(content.contains("example com"))
        #expect(content.contains("e1,2023-11-14T22:13:20Z,example com,443,com.app,allowed,outbound"))
    }
}
