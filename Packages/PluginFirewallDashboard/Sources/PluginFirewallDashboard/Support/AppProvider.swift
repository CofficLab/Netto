import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

/// 兼容 UI 状态（旧 `AppProvider` 语义；Store 相关视图使用）。
///
/// 纯 UI 状态，不创建/访问任何核心服务：showSheet / isImporting /
/// isDropping / rightAlbumVisible 四项与旧实现完全一致（Store 视图消费）。
///
/// 线程/actor：`ObservableObject`；@Published 变更在主线程发布（视图层消费）。
public final class AppProvider: NSObject, ObservableObject, SuperLog, SuperThread {
    public nonisolated static let emoji = "🐮"

    @Published public var showSheet: Bool = true
    @Published public var isImporting: Bool = false
    @Published public var isDropping: Bool = false
    @Published public var rightAlbumVisible = false

    public override init() {
        super.init()
    }
}
