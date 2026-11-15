import Combine
import ProviderAppSettings

/// 菜单栏共享的「被拒绝应用数量」状态。
///
/// `AppSettingsProviding.observeChanges()` 是单消费者 AsyncStream（每次订阅会
/// 替换上一个续体），因此状态栏图标与弹出面板必须共享**同一个**观察者。
@MainActor
final class MenuBarDeniedAppsModel: ObservableObject {
    @Published private(set) var deniedCount: Int = 0

    private let settings: any AppSettingsProviding
    private var isStarted = false

    init(settings: any AppSettingsProviding) {
        self.settings = settings
    }

    /// 幂等启动；观察登记在插件上，生命周期 = App 运行期。
    func start() {
        guard !isStarted else { return }
        isStarted = true
        Task { [weak self] in
            guard let self else { return }
            await self.refresh()
            for await _ in self.settings.observeChanges() {
                await self.refresh()
            }
        }
    }

    private func refresh() async {
        if let count = try? await settings.deniedAppsCount() {
            deniedCount = count
        }
    }
}
