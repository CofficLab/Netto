import Foundation
import Combine
import SwiftUI

@MainActor
class UIProvider: ObservableObject {
    @Published var dbVisible: Bool = false
    @Published var displayType: DisplayType = .All
    @Published var activePopoverAppId: String = ""
    @Published var shouldShowUpgradeGuide: Bool = false
    
    /// 显示指定应用的popover，同时隐藏其他应用的popover
    /// - Parameter appId: 要显示popover的应用ID
    func showPopover(for appId: String) {
        self.activePopoverAppId = appId
    }
    
    /// 隐藏当前显示的popover
    func hidePopover() {
        self.activePopoverAppId = ""
    }
    
    /// 检查指定应用的popover是否应该显示
    /// - Parameter appId: 应用ID
    /// - Returns: 是否应该显示popover
    func shouldShowPopover(for appId: String) -> Bool {
        return activePopoverAppId == appId
    }
    
    /// 显示升级引导界面
    func showUpgradeGuide() {
        self.shouldShowUpgradeGuide = true
    }
    
    /// 隐藏升级引导界面
    func hideUpgradeGuide() {
        self.shouldShowUpgradeGuide = false
    }
    
    /// 清理所有状态，释放内存
    func cleanup() {
        dbVisible = false
        displayType = .All
        activePopoverAppId = ""
        shouldShowUpgradeGuide = false
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
