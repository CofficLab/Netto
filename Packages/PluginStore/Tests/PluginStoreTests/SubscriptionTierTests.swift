import Foundation
import ProviderStore
import Testing
@testable import PluginStore

/// 订阅等级比较与分级语义测试。
@Suite("StoreTier")
struct StoreTierTests {

    @Test("rawValue 顺序决定比较结果")
    func ordering() {
        #expect(StoreTier.none < StoreTier.pro)
        #expect(StoreTier.pro < StoreTier.ultimate)
        #expect(StoreTier.none < StoreTier.ultimate)
        // 反向不成立。
        #expect(!(StoreTier.pro < StoreTier.none))
        #expect(StoreTier.pro >= StoreTier.pro)
        #expect(StoreTier.pro <= StoreTier.pro)
    }

    @Test("分级布尔属性")
    func tierFlags() {
        #expect(StoreTier.none.isFree)
        #expect(!StoreTier.pro.isFree)
        #expect(!StoreTier.ultimate.isFree)

        #expect(!StoreTier.none.isProOrHigher)
        #expect(StoreTier.pro.isProOrHigher)
        #expect(StoreTier.ultimate.isProOrHigher)

        #expect(!StoreTier.none.isUltimateOrHigher)
        #expect(!StoreTier.pro.isUltimateOrHigher)
        #expect(StoreTier.ultimate.isUltimateOrHigher)
    }

    @Test("Codable 往返保持等级")
    func codableRoundTrip() throws {
        for tier in [StoreTier.none, .pro, .ultimate] {
            let data = try JSONEncoder().encode(tier)
            #expect(try JSONDecoder().decode(StoreTier.self, from: data) == tier)
        }
    }
}

/// `StoreEntitlementSnapshot` 过期与生效等级语义测试。
///
/// 关键业务约定（改动会直接影响付费校验）：
/// - `expiresAt == nil` 视为已过期
/// - 距到期不足 60 秒视为未过期（生产侧「延迟 1 分钟」的测试友好窗口）
@Suite("StoreEntitlementSnapshot")
struct PurchaseInfoTests {

    @Test("nil 到期时间视为已过期")
    func nilExpiryIsExpired() {
        let info = StoreEntitlementSnapshot(tier: .pro, expiresAt: nil)
        #expect(info.isExpired)
        #expect(!info.isProOrHigher)
        #expect(info.effectiveTier == .none)
    }

    @Test("未来到期时间视为未过期并生效")
    func futureExpiryIsActive() {
        let info = StoreEntitlementSnapshot(tier: .pro, expiresAt: Date(timeIntervalSinceNow: 3600))
        #expect(!info.isExpired)
        #expect(info.isProOrHigher)
        #expect(info.effectiveTier == .pro)
        #expect(info.isNotProOrHigher == false)
    }

    @Test("过去时间视为已过期，等级回落为 none")
    func pastExpiryIsInactive() {
        let info = StoreEntitlementSnapshot(tier: .ultimate, expiresAt: Date(timeIntervalSinceNow: -3600))
        #expect(info.isExpired)
        #expect(!info.isProOrHigher)
        #expect(info.effectiveTier == .none, "已过期的 ultimate 不应继续授予权益")
        #expect(info.isNotProOrHigher)
    }

    @Test("60 秒宽容窗口：到期仅过去 30 秒仍视为未过期")
    func graceWindowJustExpired() {
        let info = StoreEntitlementSnapshot(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -30))
        #expect(!info.isExpired)
        #expect(info.isProOrHigher)
    }

    @Test("超过 60 秒宽容窗口即视为过期")
    func beyondGraceWindowIsExpired() {
        let info = StoreEntitlementSnapshot(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -120))
        #expect(info.isExpired)
        #expect(!info.isProOrHigher)
        #expect(info.effectiveTier == .none)
    }

    @Test("任意未来到期时间都视为未过期")
    func anyFutureExpiryIsActive() {
        // distance(to:) 对未来时间为负，故 >60 不成立。
        // 60 秒宽容只作用于「刚刚过期」的情形，不限制未来时长。
        for seconds in [60.0, 120.0, 3_600.0] {
            let info = StoreEntitlementSnapshot(tier: .pro, expiresAt: Date(timeIntervalSinceNow: seconds))
            #expect(!info.isExpired, "未来 \(seconds) 秒后到期应视为有效")
        }
    }

    @Test("60 秒宽容窗口边界：过去 59 秒有效，过去 61 秒过期")
    func graceWindowBoundary() {
        #expect(!StoreEntitlementSnapshot(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -59)).isExpired)
        #expect(StoreEntitlementSnapshot(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -61)).isExpired)
    }

    @Test("none 等级即使未过期也不授予 pro 权益")
    func noneTierNeverGrantsPro() {
        let info = StoreEntitlementSnapshot(tier: .none, expiresAt: Date(timeIntervalSinceNow: 3600))
        #expect(!info.isExpired, "到期时间本身是有效的")
        #expect(!info.isProOrHigher)
        #expect(info.effectiveTier == .none)
    }

    @Test("expiresAtString 对 nil 输出 \"nil\"")
    func expiresAtStringNil() {
        #expect(StoreEntitlementSnapshot.none.expiresAtString == "nil")
        #expect(StoreEntitlementSnapshot(tier: .none, expiresAt: nil).expiresAtString == "nil")
    }

    @Test("expiresAtString 标注过期与否")
    func expiresAtStringMarksExpiry() {
        let active = StoreEntitlementSnapshot(tier: .pro, expiresAt: Date(timeIntervalSinceNow: 3600))
        let expired = StoreEntitlementSnapshot(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -3600))

        #expect(active.expiresAtString.hasSuffix("[没过期]"))
        #expect(expired.expiresAtString.hasSuffix("[过期了]"))
        // 时间部分为定长 19 字符 + 5 字符标记。
        #expect(active.expiresAtString.count == 19 + 5)
        #expect(expired.expiresAtString.count == 19 + 5)
    }

    @Test("none 常量为 none 等级且已过期")
    func noneConstant() {
        #expect(StoreEntitlementSnapshot.none.tier == .none)
        #expect(StoreEntitlementSnapshot.none.expiresAt == nil)
        #expect(StoreEntitlementSnapshot.none.isExpired)
    }

    @Test("Codable 往返保持等级与到期时间")
    func codableRoundTrip() throws {
        let expires = Date(timeIntervalSince1970: 1_700_000_000)
        let info = StoreEntitlementSnapshot(tier: .ultimate, expiresAt: expires)

        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(StoreEntitlementSnapshot.self, from: data)
        #expect(decoded.tier == .ultimate)
        #expect(decoded.expiresAt == expires)
        #expect(decoded == info)
    }
}
