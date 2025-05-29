import Foundation
import SwiftUI

extension SmartApp {
    /// 示例应用列表
    static var samples: [SmartApp] { [
        SmartApp(id: "com.apple.Safari", name: "Safari", icon: IconHelper.createSystemIcon(
            iconName: "safari",
            gradientColors: [Color.blue.opacity(0.8), Color.cyan]
        )),
        SmartApp(id: "com.apple.Maps", name: "Maps", icon: IconHelper.createSystemIcon(
            iconName: "map",
            gradientColors: [Color.green.opacity(0.8), Color.mint]
        )),
        SmartApp(id: "com.apple.MobileSMS", name: "Messages", icon: IconHelper.createSystemIcon(
            iconName: "message",
            gradientColors: [Color.green.opacity(0.8), Color.blue]
        )),
        SmartApp(id: "com.apple.Mail", name: "Mail", icon: IconHelper.createSystemIcon(
            iconName: "envelope",
            gradientColors: [Color.blue.opacity(0.8), Color.indigo]
        )),
        SmartApp(id: "com.apple.Photos", name: "Photos", icon: IconHelper.createSystemIcon(
            iconName: "photo.on.rectangle",
            gradientColors: [Color.yellow.opacity(0.8), Color.orange]
        )),
        SmartApp(id: "com.apple.iCal", name: "Calendar", icon: IconHelper.createSystemIcon(
            iconName: "calendar",
            gradientColors: [Color.red.opacity(0.8), Color.orange]
        )),
        SmartApp(id: "com.apple.Notes", name: "Notes", icon: IconHelper.createSystemIcon(
            iconName: "note.text",
            gradientColors: [Color.yellow.opacity(0.8), Color.orange]
        )),
        SmartApp(id: "com.apple.reminders", name: "Reminders", icon: IconHelper.createSystemIcon(
            iconName: "checklist",
            gradientColors: [Color.orange.opacity(0.8), Color.red]
        )),
        SmartApp(id: "com.apple.Weather", name: "Weather", icon: IconHelper.createSystemIcon(
            iconName: "cloud.sun",
            gradientColors: [Color.blue.opacity(0.8), Color.cyan]
        )),
        SmartApp(id: "com.apple.Clock", name: "Clock", icon: IconHelper.createSystemIcon(
            iconName: "clock",
            gradientColors: [Color.gray.opacity(0.8), Color.black]
        )),
        SmartApp(id: "com.apple.systempreferences", name: "Settings", icon: IconHelper.createSystemIcon(
            iconName: "gearshape",
            gradientColors: [Color.gray.opacity(0.8), Color.secondary]
        )),
        SmartApp(id: "com.apple.AppStore", name: "App Store", icon: IconHelper.createSystemIcon(
            iconName: "app.badge",
            gradientColors: [Color.blue.opacity(0.8), Color.indigo]
        )),
        SmartApp(id: "com.apple.Health", name: "Health", icon: IconHelper.createSystemIcon(
            iconName: "heart",
            gradientColors: [Color.red.opacity(0.8), Color.pink]
        )),
        SmartApp(id: "com.apple.Wallet", name: "Wallet", icon: IconHelper.createSystemIcon(
            iconName: "wallet.pass",
            gradientColors: [Color.black.opacity(0.8), Color.gray]
        )),
        SmartApp(id: "com.apple.stocks", name: "Stocks", icon: IconHelper.createSystemIcon(
            iconName: "chart.line.uptrend.xyaxis",
            gradientColors: [Color.green.opacity(0.8), Color.mint]
        )),
        SmartApp(id: "com.apple.Calculator", name: "Calculator", icon: IconHelper.createSystemIcon(
            iconName: "calculator",
            gradientColors: [Color.gray.opacity(0.8), Color.black]
        )),
        SmartApp(id: "com.apple.camera", name: "Camera", icon: IconHelper.createSystemIcon(
            iconName: "camera",
            gradientColors: [Color.gray.opacity(0.8), Color.black]
        )),
        SmartApp(id: "com.apple.FaceTime", name: "FaceTime", icon: IconHelper.createSystemIcon(
            iconName: "video",
            gradientColors: [Color.green.opacity(0.8), Color.mint]
        )),
        SmartApp(id: "com.apple.iBooks", name: "iBooks", icon: IconHelper.createSystemIcon(
            iconName: "book",
            gradientColors: [Color.orange.opacity(0.8), Color.yellow]
        )),
        SmartApp(id: "com.apple.podcasts", name: "Podcasts", icon: IconHelper.createSystemIcon(
            iconName: "mic",
            gradientColors: [Color.purple.opacity(0.8), Color.pink]
        )),
        SmartApp(id: "com.apple.Music", name: "Music", icon: IconHelper.createSystemIcon(
            iconName: "music.note",
            gradientColors: [Color.red.opacity(0.8), Color.pink]
        )),
        SmartApp(id: "com.apple.TV", name: "TV", icon: IconHelper.createSystemIcon(
            iconName: "tv",
            gradientColors: [Color.black.opacity(0.8), Color.gray]
        )),
        SmartApp(id: "com.apple.finder", name: "Finder", icon: IconHelper.createSystemIcon(
            iconName: "folder",
            gradientColors: [Color.blue.opacity(0.8), Color.cyan]
        )),
        SmartApp(id: "com.apple.Home", name: "Home", icon: IconHelper.createSystemIcon(
            iconName: "house",
            gradientColors: [Color.orange.opacity(0.8), Color.yellow]
        )),
        SmartApp(id: "com.apple.VoiceMemos", name: "Voice Memos", icon: IconHelper.createSystemIcon(
            iconName: "waveform",
            gradientColors: [Color.red.opacity(0.8), Color.orange]
        )),
        SmartApp(id: "com.apple.shortcuts", name: "Shortcuts", icon: IconHelper.createSystemIcon(
            iconName: "bolt.circle",
            gradientColors: [Color.blue.opacity(0.8), Color.indigo]
        )),
        SmartApp(id: "com.apple.translate", name: "Translate", icon: IconHelper.createSystemIcon(
            iconName: "translate",
            gradientColors: [Color.blue.opacity(0.8), Color.purple]
        )),
        SmartApp(id: "com.apple.findmy", name: "Find My", icon: IconHelper.createSystemIcon(
            iconName: "location.circle",
            gradientColors: [Color.green.opacity(0.8), Color.mint]
        )),
        SmartApp(id: "com.apple.AddressBook", name: "Address Book", icon: IconHelper.createSystemIcon(
            iconName: "person.2",
            gradientColors: [Color.blue.opacity(0.8), Color.indigo]
        )),
        SmartApp(id: "com.apple.measure", name: "Measure", icon: IconHelper.createSystemIcon(
            iconName: "ruler",
            gradientColors: [Color.yellow.opacity(0.8), Color.orange]
        )),
    ] }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
