import KernelCore
import ProviderLogo
import SwiftUI

/// 菜单栏品牌图标插件。
///
/// 对齐 Lumi/Wakey 的 PluginLogo* 插件：品牌图标不是宿主写死的资源，而是由
/// 插件在 `onBoot` 中向 `LogoProviding` 注册 `LogoItem`，宿主状态栏按
/// `highestPriorityLogoItem` 取用。`order` 同时用于插件启动顺序与 Logo 优先级，
/// 数值越大越优先显示。
@MainActor
public final class BrandLogoPlugin: SuperPlugin {
    public let id = "brand-logo"
    public let order = 20
    public let metadata = PluginMetadata(
        id: "brand-logo",
        name: "品牌图标",
        description: "向菜单栏贡献 Netpause 品牌图标",
        version: "1.0",
        category: .design,
        policy: .alwaysOn
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any LogoProviding).self)?.registerLogoItem(
            LogoItem(id: id, order: order) { scene in
                BrandLogoMark(scene: scene)
            }
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any LogoProviding).self)?.unregisterLogoItem(id: id)
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any LogoProviding).self)?.unregisterLogoItem(id: id)
    }
}

/// 品牌图标：与 Lumi/Wakey 的 Logo 插件一致，用 SwiftUI 矢量形状绘制而不是位图。
///
/// 图形与 App 图标同源的「盾牌 + 对勾」：盾牌代表按应用放行/拦截网络访问，
/// 对勾代表允许。菜单栏场景恒为单色模板图（`LogoScene.statusBar` 约定，
/// 由系统着色），其余场景使用品牌靛蓝 + 青色。
public struct BrandLogoMark: View {
    private let scene: LogoScene

    public init(scene: LogoScene = .general) {
        self.scene = scene
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let palette = BrandPalette(scene: scene)

            ZStack {
                ShieldOutline()
                    .stroke(
                        palette.shield,
                        style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round, lineJoin: .round)
                    )
                CheckGlyph()
                    .stroke(
                        palette.check,
                        style: StrokeStyle(lineWidth: size * 0.115, lineCap: .round, lineJoin: .round)
                    )
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct BrandPalette {
    let shield: Color
    let check: Color

    init(scene: LogoScene) {
        switch scene {
        case .statusBar, .statusBarHighlighted:
            shield = .primary
            check = .primary
        case .appIcon, .about, .general:
            shield = Color(red: 0.31, green: 0.27, blue: 0.90)
            check = Color(red: 0.03, green: 0.57, blue: 0.70)
        }
    }
}

/// 盾牌轮廓，比例与 App 图标中的盾牌一致；18pt 下仍需保持足够笔画宽度。
private struct ShieldOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }

        var path = Path()
        path.move(to: p(0.16, 0.24))
        path.addCurve(to: p(0.26, 0.13), control1: p(0.16, 0.19), control2: p(0.20, 0.13))
        path.addLine(to: p(0.74, 0.13))
        path.addCurve(to: p(0.84, 0.24), control1: p(0.80, 0.13), control2: p(0.84, 0.19))
        path.addLine(to: p(0.84, 0.47))
        path.addCurve(to: p(0.50, 0.91), control1: p(0.84, 0.69), control2: p(0.69, 0.83))
        path.addCurve(to: p(0.16, 0.47), control1: p(0.31, 0.83), control2: p(0.16, 0.69))
        path.closeSubpath()
        return path
    }
}

/// 对勾：起点与拐点抬高到盾牌视觉中心，菜单栏尺寸下不会被盾牌底尖挤压。
private struct CheckGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }

        var path = Path()
        path.move(to: p(0.34, 0.50))
        path.addLine(to: p(0.46, 0.62))
        path.addLine(to: p(0.68, 0.36))
        return path
    }
}
