import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderStore
import SwiftUI

// MARK: - 契约环境键

/// 视图通过 `@Environment(\.firewallProvider)` 读取防火墙契约。
/// 未装配时为 nil；生产路径由 AppEnvironment 在启动期注入。
private struct FirewallProviderKey: EnvironmentKey {
    static let defaultValue: FirewallProviding? = nil
}

/// 事件存储契约环境键。
private struct EventsProviderKey: EnvironmentKey {
    static let defaultValue: FirewallEventsProviding? = nil
}

/// 应用设置契约环境键。
private struct SettingsProviderKey: EnvironmentKey {
    static let defaultValue: AppSettingsProviding? = nil
}

/// Store 契约环境键（nil = 未装配；由 PluginStore 在启动期注册）。
private struct StoreProviderKey: EnvironmentKey {
    static let defaultValue: StoreProviding? = nil
}

/// 会话起始时间键（旧 `EventRepo.sessionStartDate` 语义）。
private struct SessionStartDateKey: EnvironmentKey {
    static let defaultValue: Date = Date()
}

extension EnvironmentValues {
    /// 防火墙契约（nil = 未装配；视图按启动失败/未运行处理）。
    var firewallProvider: FirewallProviding? {
        get { self[FirewallProviderKey.self] }
        set { self[FirewallProviderKey.self] = newValue }
    }

    /// 事件存储契约。
    var eventsProvider: FirewallEventsProviding? {
        get { self[EventsProviderKey.self] }
        set { self[EventsProviderKey.self] = newValue }
    }

    /// 应用设置契约。
    var settingsProvider: AppSettingsProviding? {
        get { self[SettingsProviderKey.self] }
        set { self[SettingsProviderKey.self] = newValue }
    }

    /// Store 契约（nil = 未装配；AppAction 等跨插件消费方使用）。
    var storeProvider: StoreProviding? {
        get { self[StoreProviderKey.self] }
        set { self[StoreProviderKey.self] = newValue }
    }

    /// 会话起始时间（App 启动期固定）。
    var sessionStartDate: Date {
        get { self[SessionStartDateKey.self] }
        set { self[SessionStartDateKey.self] = newValue }
    }
}
