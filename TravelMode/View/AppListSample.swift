import OSLog
import SwiftUI

struct AppListSample: View {
    private var apps: [SmartApp] {
        [
            SmartApp(id: "com.apple.Safari", name: "Safari浏览器", icon: Text("🌐")),
            SmartApp(id: "com.apple.Maps", name: "地图", icon: Text("🗺️")),
            SmartApp(id: "com.apple.MobileSMS", name: "信息", icon: Text("💬")),
            SmartApp(id: "com.apple.Mail", name: "邮件", icon: Text("📧")),
            SmartApp(id: "com.apple.Photos", name: "照片", icon: Text("🖼️")),
            SmartApp(id: "com.apple.iCal", name: "日历", icon: Text("📅")),
            SmartApp(id: "com.apple.Notes", name: "备忘录", icon: Text("📝")),
            SmartApp(id: "com.apple.reminders", name: "提醒事项", icon: Text("⏰")),
            SmartApp(id: "com.apple.Weather", name: "天气", icon: Text("🌤️")),
            SmartApp(id: "com.apple.Clock", name: "时钟", icon: Text("🕐")),
            SmartApp(id: "com.apple.systempreferences", name: "设置", icon: Text("⚙️")),
            SmartApp(id: "com.apple.AppStore", name: "App Store", icon: Text("🏪")),
            SmartApp(id: "com.apple.Health", name: "健康", icon: Text("❤️")),
            SmartApp(id: "com.apple.Wallet", name: "钱包", icon: Text("👛")),
            SmartApp(id: "com.apple.stocks", name: "股市", icon: Text("📈")),
            SmartApp(id: "com.apple.Calculator", name: "计算器", icon: Text("🧮")),
            SmartApp(id: "com.apple.camera", name: "相机", icon: Text("📸")),
            SmartApp(id: "com.apple.FaceTime", name: "FaceTime", icon: Text("📱")),
            SmartApp(id: "com.apple.iBooks", name: "图书", icon: Text("📚")),
            SmartApp(id: "com.apple.podcasts", name: "播客", icon: Text("🎙️")),
            SmartApp(id: "com.apple.Music", name: "音乐", icon: Text("🎵")),
            SmartApp(id: "com.apple.TV", name: "电视", icon: Text("📺")),
            SmartApp(id: "com.apple.finder", name: "访达", icon: Text("📁")),
            SmartApp(id: "com.apple.Home", name: "家庭", icon: Text("🏠")),
            SmartApp(id: "com.apple.VoiceMemos", name: "语音备忘录", icon: Text("🎤")),
            SmartApp(id: "com.apple.shortcuts", name: "快捷指令", icon: Text("⚡️")),
            SmartApp(id: "com.apple.translate", name: "翻译", icon: Text("🌍")),
            SmartApp(id: "com.apple.findmy", name: "查找", icon: Text("🔍")),
            SmartApp(id: "com.apple.AddressBook", name: "通讯录", icon: Text("👥")),
            SmartApp(id: "com.apple.measure", name: "测距仪", icon: Text("📏"))
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(apps) { app in
                    AppLine(app: app)
                    Divider()
                }
            }
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
}

#Preview("AppList") {
    RootView {
        AppList()
    }
}

#Preview("AppListSample") {
    RootView {
        AppListSample()
    }
}

#Preview("EventList") {
    RootView {
        EventList()
    }
}
