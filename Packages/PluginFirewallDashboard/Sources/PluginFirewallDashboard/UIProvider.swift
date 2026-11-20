import Foundation
import Combine
import SwiftUI

@MainActor
public final class UIProvider: ObservableObject {
    @Published public var dbVisible: Bool = false
    @Published public var displayType: DisplayType = .All
    @Published public var activePopoverAppId: String = ""
    @Published public var shouldShowUpgradeGuide: Bool = false
    /// 菜单栏弹窗当前展开的应用；nil 表示显示应用列表。
    @Published public var selectedAppId: String?

    public init() {}

    public func selectApp(_ appId: String) {
        selectedAppId = appId
    }

    public func clearSelectedApp() {
        selectedAppId = nil
    }

    /// 升级引导是否需要覆盖在当前子视图之上。
    ///
    /// 停留在应用详情页时达到免费版限制，引导必须覆盖在详情之上才可见。
    public var showsUpgradeOverlay: Bool {
        shouldShowUpgradeGuide && selectedAppId != nil
    }

    /// 达到免费版限制时的处理：显示升级引导。
    public func presentUpgradeLimit() {
        shouldShowUpgradeGuide = true
    }
    
    /// 显示指定应用的popover，同时隐藏其他应用的popover
    /// - Parameter appId: 要显示popover的应用ID
    public func showPopover(for appId: String) {
        self.activePopoverAppId = appId
    }
    
    /// 隐藏当前显示的popover
    public func hidePopover() {
        self.activePopoverAppId = ""
    }
    
    /// 检查指定应用的popover是否应该显示
    /// - Parameter appId: 应用ID
    /// - Returns: 是否应该显示popover
    public func shouldShowPopover(for appId: String) -> Bool {
        return activePopoverAppId == appId
    }
    
    /// 显示升级引导界面
    public func showUpgradeGuide() {
        self.shouldShowUpgradeGuide = true
    }
    
    /// 隐藏升级引导界面
    public func hideUpgradeGuide() {
        self.shouldShowUpgradeGuide = false
    }
    
    /// 清理所有状态，释放内存
    public func cleanup() {
        dbVisible = false
        displayType = .All
        activePopoverAppId = ""
        shouldShowUpgradeGuide = false
        selectedAppId = nil
    }
}

#Preview("APP") {
    DashboardPreviewHost { ContentView() }.frame(width: 700)
}
