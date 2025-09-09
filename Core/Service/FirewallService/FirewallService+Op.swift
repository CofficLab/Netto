import Foundation
import NetworkExtension
import OSLog
import SystemExtensions
import SwiftUI

// MARK: - 基础操作
// 负责 FirewallService 的基础操作，包括：
// - 错误处理（设置和清除错误）
// - 观察者管理（添加和移除观察者）
// - 其他基础工具方法

extension FirewallService {
    func clearError() {
        self.error = nil
    }

    func setError(_ error: Error) {
        self.error = error
    }

    func removeObserver() {
        guard let changeObserver = observer else {
            return
        }

        nc.removeObserver(
            changeObserver,
            name: .NEFilterConfigurationDidChange,
            object: NEFilterManager.shared()
        )
    }


}

// MARK: - Preview

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
}
