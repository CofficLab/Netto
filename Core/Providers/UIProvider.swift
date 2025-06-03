import Foundation
import Combine
import SwiftUI

@MainActor
class UIProvider: ObservableObject {
    static let shared = UIProvider()
    
    @Published var dbVisible: Bool = false
    @Published var displayType: DisplayType = .All
    @Published var showSystemApps: Bool = false
    @Published var activePopoverAppId: String = ""
    
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
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
