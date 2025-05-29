import Foundation
import SwiftData
import SwiftUI
import OSLog
import MagicCore

@Model
final class AppSetting: SuperLog, SuperEvent {
    @Transient let emoji = "🦆"

    @Attribute(.unique)
    var appId: String
    var allowed: Bool
    
    // MARK: - Initialization
    
    /// 初始化AppSetting实例
    /// - Parameters:
    ///   - appId: 应用程序的唯一标识符
    ///   - allowed: 是否允许该应用程序访问网络
    init(appId: String, allowed: Bool) {
        self.appId = appId
        self.allowed = allowed
    }
}

// MARK: - CRUD Operations

extension AppSetting {
    
    /// 创建新的AppSetting记录
    /// - Parameters:
    ///   - id: 应用程序ID
    ///   - allowed: 是否允许访问，默认为true
    static func create(_ id: String, allowed: Bool = true) {
        let context = ModelContext(AppConfig.container)
        context.insert(AppSetting(appId: id, allowed: allowed))
        do {
            try context.save()
        } catch (let error) {
            os_log("\(error.localizedDescription)")
        }
    }
    
    /// 根据ID查找AppSetting记录
    /// - Parameter id: 应用程序ID
    /// - Returns: 找到的AppSetting实例，如果未找到则返回nil
    static func find(_ id: String) -> AppSetting? {
        let context = ModelContext(AppConfig.container)
        let predicate = #Predicate<AppSetting> { item in
            item.appId == id
        }
        
        do {
            let items = try context.fetch(FetchDescriptor(predicate: predicate))
            let first = items.first
            
            return first
        } catch (let error) {
            os_log("\(error.localizedDescription)")
            
            return nil
        }
    }
}

// MARK: - Permission Management

extension AppSetting {
    
    /// 检查指定ID的应用是否应该被允许访问网络
    /// - Parameter id: 应用程序或进程ID
    /// - Returns: 如果允许访问返回true，否则返回false
    static func shouldAllow(_ id: String) -> Bool {
        var targetId = id
        let appId = SmartApp.getApp(id)
        if let app = appId {
            // 当前进程id属于某个APP，结算到该APP头上
            targetId = app.bundleIdentifier ?? ""
        }
        
        let setting = find(targetId)
        if let s = setting {
            return s.allowed
        } else {
            create(targetId)
            
            return true
        }
    }
    
    /// 设置指定ID的应用为拒绝访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    static func setDeny(_ id: String) throws {
        let context = ModelContext(AppConfig.container)
        
        let setting = find(id)
        if let s = setting {
            s.allowed = false
        } else {
            create(id, allowed: false)
        }
        
        try context.save()

        self.emitDidSetDeny(id)
    }
    
    /// 设置指定ID的应用为允许访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    static func setAllow(_ id: String) throws {
        let context = ModelContext(AppConfig.container)
        
        let setting = find(id)
        if let s = setting {
            s.allowed = true
        } else {
            create(id, allowed: true)
        }
        
        try context.save()

        self.emitDidSetAllow(id)
    }
}

// MARK: - Event Emission

extension AppSetting {
    
    /// 发送允许访问事件通知
    /// - Parameter appId: 应用程序ID
    static func emitDidSetAllow(_ appId: String) {
        NotificationCenter.default.post(name: .didSetAllow, object: nil, userInfo: [
            "appId": appId
        ])
    }

    /// 发送拒绝访问事件通知
    /// - Parameter appId: 应用程序ID
    static func emitDidSetDeny(_ appId: String) {
        NotificationCenter.default.post(name: .didSetDeny, object: nil, userInfo: [
            "appId": appId
        ])
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
