import LumiUI
import ProviderTheme
import SwiftUI

/// 把 `ThemeProviding` 选中的主题桥接到 LumiUI 主题体系（`@LumiTheme` /
/// `ChromeThemes`），使 LumiUI 组件渲染出选中主题的一致配色。
///
/// 复刻 Lumi `ViewFactory.syncLumiTheme`：`ThemeProviding` 是主题事实来源，
/// 此处把其 palette 适配回 chrome 主题并同步全局状态（氛围渐变、窗口外观、
/// UI 主题存储），让设置窗口的 LumiUI 组件即时反映切换。
///
/// 线程/actor：`@MainActor`（修改全局主题状态必须在主线程；主题事件回调
/// 亦由 `@MainActor` Provider 在主线程派发）。
@MainActor
enum ThemeBridging {
    /// 按当前系统外观解析有效明暗（`.system` 主题跟随系统）。
    private static var effectiveColorScheme: ColorScheme {
        #if canImport(AppKit)
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark ? .dark : .light
        #else
        return .light
        #endif
    }

    /// 同步主题到 LumiUI 全局状态（`@LumiTheme` / `ChromeThemes` / 窗口外观）。
    ///
    /// 副作用：更新 `ActiveChromeTheme.current`、`LumiUIThemeStore`、
    /// `ResolvedSystemColorScheme.current` 并同步全部窗口外观。
    static func sync(_ provider: any ThemeProviding) {
        guard let selected = provider.selectedTheme else { return }

        let colorScheme: ColorScheme
        switch selected.appearanceKind {
        case .dark: colorScheme = .dark
        case .light: colorScheme = .light
        case .system: colorScheme = Self.effectiveColorScheme
        }

        ResolvedSystemColorScheme.current = colorScheme

        let chrome = PaletteChromeTheme(theme: selected, colorScheme: colorScheme)
        ActiveChromeTheme.current = chrome
        LumiUIThemeStore.shared.setTheme(ChromeToUIThemeAdapter(chrome: chrome))
        ThemeWindowAppearanceSync.syncAllWindows()
    }
}

/// 主题感知的视图包装：根据 `ThemeProviding` 的选中主题应用明暗外观，
/// 并在主题切换时重新桥接 LumiUI 全局状态。
///
/// 复刻 Lumi `ViewFactory.ThemeHostingView`：订阅 `ThemeProviding` 主题事件，
/// 任何窗口触发切换后本视图重算并同步（`sync` 幂等，重复调用无副作用）。
///
/// 线程/actor：`View`，`@MainActor`；observer 生命周期随视图出现/消失管理。
@MainActor
struct ThemeHostingView<Content: View>: View {
    let theme: any ThemeProviding
    let content: Content

    @State private var refreshTick = false
    @State private var observerHandle: (any ThemeProvidingObserverHandle)?

    init(theme: any ThemeProviding, content: Content) {
        self.theme = theme
        self.content = content
    }

    var body: some View {
        let _ = refreshTick

        content
            .preferredColorScheme(preferredColorScheme)
            .background(backgroundColor)
            .onAppear {
                ThemeBridging.sync(theme)
                guard observerHandle == nil else { return }
                observerHandle = theme.addObserver { _ in
                    refreshTick.toggle()
                }
            }
            .onDisappear {
                observerHandle?.cancel()
                observerHandle = nil
            }
    }

    private var preferredColorScheme: ColorScheme? {
        switch theme.selectedTheme?.appearanceKind {
        case .dark: .dark
        case .light: .light
        case .system: nil
        case nil: nil
        }
    }

    private var backgroundColor: Color {
        theme.selectedTheme?.palette.backgroundMedium.color() ?? Color(nsColor: .windowBackgroundColor)
    }
}
