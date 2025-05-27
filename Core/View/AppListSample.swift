import OSLog
import SwiftUI

struct AppListSample: View {
    private var apps: [SmartApp] {
        [
            SmartApp(id: "com.apple.Safari", name: "Safari", icon: Text("🌐")),
            SmartApp(id: "com.apple.Maps", name: "Maps", icon: Text("🗺️")),
            SmartApp(id: "com.apple.MobileSMS", name: "Messages", icon: Text("💬")),
            SmartApp(id: "com.apple.Mail", name: "Mail", icon: Text("📧")),
            SmartApp(id: "com.apple.Photos", name: "Photos", icon: Text("🖼️")),
            SmartApp(id: "com.apple.iCal", name: "Calendar", icon: Text("📅")),
            SmartApp(id: "com.apple.Notes", name: "Notes", icon: Text("📝")),
            SmartApp(id: "com.apple.reminders", name: "Reminders", icon: Text("⏰")),
            SmartApp(id: "com.apple.Weather", name: "Weather", icon: Text("🌤️")),
            SmartApp(id: "com.apple.Clock", name: "Clock", icon: Text("🕐")),
            SmartApp(id: "com.apple.systempreferences", name: "Settings", icon: Text("⚙️")),
            SmartApp(id: "com.apple.AppStore", name: "App Store", icon: Text("🏪")),
            SmartApp(id: "com.apple.Health", name: "Health", icon: Text("❤️")),
            SmartApp(id: "com.apple.Wallet", name: "Wallet", icon: Text("👛")),
            SmartApp(id: "com.apple.stocks", name: "Stocks", icon: Text("📈")),
            SmartApp(id: "com.apple.Calculator", name: "Calculator", icon: Text("🧮")),
            SmartApp(id: "com.apple.camera", name: "Camera", icon: Text("📸")),
            SmartApp(id: "com.apple.FaceTime", name: "FaceTime", icon: Text("📱")),
            SmartApp(id: "com.apple.iBooks", name: "iBooks", icon: Text("📚")),
            SmartApp(id: "com.apple.podcasts", name: "Podcasts", icon: Text("🎙️")),
            SmartApp(id: "com.apple.Music", name: "Music", icon: Text("🎵")),
            SmartApp(id: "com.apple.TV", name: "TV", icon: Text("📺")),
            SmartApp(id: "com.apple.finder", name: "Finder", icon: Text("📁")),
            SmartApp(id: "com.apple.Home", name: "Home", icon: Text("🏠")),
            SmartApp(id: "com.apple.VoiceMemos", name: "Voice Memos", icon: Text("🎤")),
            SmartApp(id: "com.apple.shortcuts", name: "Shortcuts", icon: Text("⚡️")),
            SmartApp(id: "com.apple.translate", name: "Translate", icon: Text("🌍")),
            SmartApp(id: "com.apple.findmy", name: "Find My", icon: Text("🔍")),
            SmartApp(id: "com.apple.AddressBook", name: "Address Book", icon: Text("👥")),
            SmartApp(id: "com.apple.measure", name: "Measure", icon: Text("📏"))
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
