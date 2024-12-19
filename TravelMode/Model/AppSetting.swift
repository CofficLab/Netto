import Foundation
import SwiftData
import SwiftUI
import OSLog

@Model
final class AppSetting {
    @Attribute(.unique)
    var appId: String
    var allowed: Bool
    
    init(appId: String, allowed: Bool) {
        self.appId = appId
        self.allowed = allowed
    }
    
    static func create(_ id:String, allowed: Bool = true) {
        let context = ModelContext(AppConfig.container)
        context.insert(AppSetting(appId: id, allowed: allowed))
        do {
            try context.save()
        } catch (let error) {
            Logger.app.error("\(error.localizedDescription)")
        }
    }
    
    static func find(_ id:String) -> AppSetting? {
        let context = ModelContext(AppConfig.container)
        let predicate = #Predicate<AppSetting> { item in
            item.appId == id
        }
        
        do {
            let items = try context.fetch(FetchDescriptor(predicate: predicate))
            let first = items.first
            
            return first
        } catch (let error) {
            Logger.app.error("\(error.localizedDescription)")
            
            return nil
        }
    }
    
    static func shouldAllow(_ id: String) -> Bool {
        var targetId = id
        let appId = AppHelper.getApp(id)
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
    
    static func setDeny(_ id: String) {
        let context = ModelContext(AppConfig.container)
        
        let setting = find(id)
        if let s = setting {
            s.allowed = false
        } else {
            create(id, allowed: false)
        }
        
        do {
            try context.save()
        } catch (let error) {
            Logger.app.error("\(error.localizedDescription)")
        }
    }
    
    static func setAllow(_ id: String) {
        let context = ModelContext(AppConfig.container)
        
        let setting = find(id)
        if let s = setting {
            s.allowed = true
        } else {
            create(id, allowed: true)
        }
        
        do {
            try context.save()
        } catch (let error) {
            Logger.app.error("\(error.localizedDescription)")
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
