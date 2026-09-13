import Foundation
import Combine
import SwiftUI

@MainActor
public final class UIProvider: ObservableObject {
    @Published public var dbVisible: Bool = false
    @Published public var displayType: DisplayType = .All
    @Published public var activePopoverAppId: String = ""
    @Published public var shouldShowUpgradeGuide: Bool = false

    public init() {}
    
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
    }
}

#Preview("APP") {
    DashboardPreviewHost { ContentView() }.frame(width: 700)
}
