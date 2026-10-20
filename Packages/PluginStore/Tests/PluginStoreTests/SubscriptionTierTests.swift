import Foundation
import Testing
@testable import PluginStore

/// 订阅等级比较与分级语义测试。
@Suite("SubscriptionTier")
struct SubscriptionTierTests {

    @Test("rawValue 顺序决定比较结果")
    func ordering() {
        #expect(SubscriptionTier.none < SubscriptionTier.pro)
        #expect(SubscriptionTier.pro < SubscriptionTier.ultimate)
        #expect(SubscriptionTier.none < SubscriptionTier.ultimate)
        // 反向不成立。
        #expect(!(SubscriptionTier.pro < SubscriptionTier.none))
        #expect(SubscriptionTier.pro >= SubscriptionTier.pro)
        #expect(SubscriptionTier.pro <= SubscriptionTier.pro)
    }

    @Test("分级布尔属性")
    func tierFlags() {
        #expect(SubscriptionTier.none.isFreeVersion)
        #expect(!SubscriptionTier.pro.isFreeVersion)
        #expect(!SubscriptionTier.ultimate.isFreeVersion)

        #expect(!SubscriptionTier.none.isProOrHigher)
        #expect(SubscriptionTier.pro.isProOrHigher)
        #expect(SubscriptionTier.ultimate.isProOrHigher)

        #expect(!SubscriptionTier.none.isUltimateOrHigher)
        #expect(!SubscriptionTier.pro.isUltimateOrHigher)
        #expect(SubscriptionTier.ultimate.isUltimateOrHigher)
    }

    @Test("Codable 往返保持等级")
    func codableRoundTrip() throws {
        for tier in [SubscriptionTier.none, .pro, .ultimate] {
            let data = try JSONEncoder().encode(tier)
            #expect(try JSONDecoder().decode(SubscriptionTier.self, from: data) == tier)
        }
    }
}

/// `PurchaseInfo` 过期与生效等级语义测试。
///
/// 关键业务约定（改动会直接影响付费校验）：
/// - `expiresAt == nil` 视为已过期
/// - 距到期不足 60 秒视为未过期（生产侧「延迟 1 分钟」的测试友好窗口）
@Suite("PurchaseInfo")
struct PurchaseInfoTests {

    @Test("nil 到期时间视为已过期")
    func nilExpiryIsExpired() {
        let info = PurchaseInfo(tier: .pro, expiresAt: nil)
        #expect(info.isExpired)
        #expect(!info.isProOrHigher)
        #expect(info.effectiveTier == .none)
    }

    @Test("未来到期时间视为未过期并生效")
    func futureExpiryIsActive() {
        let info = PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: 3600))
        #expect(!info.isExpired)
        #expect(info.isProOrHigher)
        #expect(info.effectiveTier == .pro)
        #expect(info.isNotProOrHigher == false)
    }

    @Test("过去时间视为已过期，等级回落为 none")
    func pastExpiryIsInactive() {
        let info = PurchaseInfo(tier: .ultimate, expiresAt: Date(timeIntervalSinceNow: -3600))
        #expect(info.isExpired)
        #expect(!info.isProOrHigher)
        #expect(info.effectiveTier == .none, "已过期的 ultimate 不应继续授予权益")
        #expect(info.isNotProOrHigher)
    }

    @Test("60 秒宽容窗口：到期仅过去 30 秒仍视为未过期")
    func graceWindowJustExpired() {
        let info = PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -30))
        #expect(!info.isExpired)
        #expect(info.isProOrHigher)
    }

    @Test("超过 60 秒宽容窗口即视为过期")
    func beyondGraceWindowIsExpired() {
        let info = PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -120))
        #expect(info.isExpired)
        #expect(!info.isProOrHigher)
        #expect(info.effectiveTier == .none)
    }

    @Test("任意未来到期时间都视为未过期")
    func anyFutureExpiryIsActive() {
        // distance(to:) 对未来时间为负，故 >60 不成立。
        // 60 秒宽容只作用于「刚刚过期」的情形，不限制未来时长。
        for seconds in [60.0, 120.0, 3_600.0] {
            let info = PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: seconds))
            #expect(!info.isExpired, "未来 \(seconds) 秒后到期应视为有效")
        }
    }

    @Test("60 秒宽容窗口边界：过去 59 秒有效，过去 61 秒过期")
    func graceWindowBoundary() {
        #expect(!PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -59)).isExpired)
        #expect(PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -61)).isExpired)
    }

    @Test("none 等级即使未过期也不授予 pro 权益")
    func noneTierNeverGrantsPro() {
        let info = PurchaseInfo(tier: .none, expiresAt: Date(timeIntervalSinceNow: 3600))
        #expect(!info.isExpired, "到期时间本身是有效的")
        #expect(!info.isProOrHigher)
        #expect(info.effectiveTier == .none)
    }

    @Test("expiresAtString 对 nil 输出 \"nil\"")
    func expiresAtStringNil() {
        #expect(PurchaseInfo.none.expiresAtString == "nil")
        #expect(PurchaseInfo(tier: .none, expiresAt: nil).expiresAtString == "nil")
    }

    @Test("expiresAtString 标注过期与否")
    func expiresAtStringMarksExpiry() {
        let active = PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: 3600))
        let expired = PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: -3600))

        #expect(active.expiresAtString.hasSuffix("[没过期]"))
        #expect(expired.expiresAtString.hasSuffix("[过期了]"))
        // 时间部分为定长 19 字符 + 5 字符标记。
        #expect(active.expiresAtString.count == 19 + 5)
        #expect(expired.expiresAtString.count == 19 + 5)
    }

    @Test("none 常量为 none 等级且已过期")
    func noneConstant() {
        #expect(PurchaseInfo.none.tier == .none)
        #expect(PurchaseInfo.none.expiresAt == nil)
        #expect(PurchaseInfo.none.isExpired)
    }

    @Test("Codable 往返保持等级与到期时间")
    func codableRoundTrip() throws {
        let expires = Date(timeIntervalSince1970: 1_700_000_000)
        let info = PurchaseInfo(tier: .ultimate, expiresAt: expires)

        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(PurchaseInfo.self, from: data)
        #expect(decoded.tier == .ultimate)
        #expect(decoded.expiresAt == expires)
        #expect(decoded == info)
    }
}
