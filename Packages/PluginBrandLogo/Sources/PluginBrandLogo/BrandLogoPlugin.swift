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
        description: "向菜单栏贡献 TravelMode 品牌图标",
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
/// 菜单栏场景恒为单色模板图（`LogoScene.statusBar` 约定，由系统着色），
/// 其余场景使用品牌色（墨绿经纬网地球 + 橙红电源符号）。
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
                GlobeOutline()
                    .stroke(
                        palette.globe,
                        style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round, lineJoin: .round)
                    )
                GlobeGrid(showsEquator: !scene.isStatusBar)
                    .stroke(
                        palette.globe,
                        style: StrokeStyle(lineWidth: size * 0.058, lineCap: .round, lineJoin: .round)
                    )
                PowerGlyph()
                    .stroke(
                        palette.power,
                        style: StrokeStyle(lineWidth: size * 0.082, lineCap: .round)
                    )
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private extension LogoScene {
    var isStatusBar: Bool {
        self == .statusBar || self == .statusBarHighlighted
    }
}

private struct BrandPalette {
    let globe: Color
    let power: Color

    init(scene: LogoScene) {
        switch scene {
        case .statusBar:
            globe = .primary
            power = .primary
        case .statusBarHighlighted, .appIcon, .about, .general:
            globe = Color(red: 0.24, green: 0.49, blue: 0.25)
            power = Color(red: 0.96, green: 0.33, blue: 0.18)
        }
    }
}

private enum GlobeGeometry {
    static let insetRatio: CGFloat = 0.075

    static func bounds(in rect: CGRect) -> CGRect {
        let size = min(rect.width, rect.height)
        let inset = size * insetRatio
        return CGRect(
            x: rect.midX - size / 2 + inset,
            y: rect.midY - size / 2 + inset,
            width: size - inset * 2,
            height: size - inset * 2
        )
    }
}

/// 地球外圈。
private struct GlobeOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: GlobeGeometry.bounds(in: rect))
        return path
    }
}

/// 地球经线椭圆 + 赤道线；菜单栏尺寸下省略赤道，避免 18pt 时线条糊在一起。
private struct GlobeGrid: Shape {
    let showsEquator: Bool

    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height)
        let bounds = GlobeGeometry.bounds(in: rect)

        var path = Path()

        let meridianWidth = bounds.width * 0.5
        path.addEllipse(in: CGRect(
            x: rect.midX - meridianWidth / 2,
            y: bounds.minY,
            width: meridianWidth,
            height: bounds.height
        ))

        if showsEquator {
            let gap = size * 0.24
            path.move(to: CGPoint(x: bounds.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX - gap, y: rect.midY))
            path.move(to: CGPoint(x: rect.midX + gap, y: rect.midY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: rect.midY))
        }

        return path
    }
}

/// 电源符号：顶部留缺口的圆环 + 穿过缺口的竖线。
private struct PowerGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY + size * 0.035)
        let radius = size * 0.14

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-52),
            endAngle: .degrees(232),
            clockwise: false
        )
        path.move(to: CGPoint(x: center.x, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y - radius - size * 0.105))

        return path
    }
}
