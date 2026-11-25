import Foundation
import SwiftData
import Synchronization
import Testing
@testable import ProviderPersistence

/// `SerialModelDatabase`：真正的后台串行执行与主线程解耦。
@Suite("串行模型数据库")
struct SerialModelDatabaseTests {

    private func makeDatabase() throws -> SerialModelDatabase {
        let container = try ModelContainer(
            for: Schema([AppSetting.self, FirewallEventModel.self]),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SerialModelDatabase(container: container, label: "test.database")
    }

    @Test("perform 在专用队列执行，不占用主线程")
    func performRunsOffMainThread() async throws {
        let database = try makeDatabase()
        let observed = Mutex<(isMain: Bool, isOnQueue: Bool)?>(nil)

        try await database.perform { _ in
            observed.withLock {
                $0 = (Thread.isMainThread, database.isOnDatabaseQueue)
            }
        }

        let result = try #require(observed.withLock { $0 })
        #expect(result.isMain == false)
        #expect(result.isOnQueue)
    }

    @Test("并发提交永不重叠执行")
    func performsNeverOverlap() async throws {
        let database = try makeDatabase()
        let state = Mutex<(active: Int, maxActive: Int)>((0, 0))

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    try? await database.perform { _ in
                        state.withLock {
                            $0.active += 1
                            $0.maxActive = max($0.maxActive, $0.active)
                        }
                        Thread.sleep(forTimeInterval: 0.001)
                        state.withLock { $0.active -= 1 }
                    }
                }
            }
        }

        #expect(state.withLock { $0.maxActive } == 1)
    }

    @Test("闭包抛错原样透传")
    func propagatesErrors() async throws {
        struct Failure: Error {}
        let database = try makeDatabase()

        await #expect(throws: Failure.self) {
            try await database.perform { _ in throw Failure() }
        }
    }

}
