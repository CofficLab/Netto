import SwiftUI
import MagicBackground
import MagicCore
import MagicUI

/// 模拟 macOS 桌面视图，包含顶部任务栏和底部 Dock
struct AppStoreDesktop: View {
    @State private var selectedApp: String? = nil
    @State private var isMenuBarExpanded = false
    
    // 任务栏应用
    private let menuBarApps = [
        ("apple.logo", "Apple"),
        ("safari", "Safari"),
        ("message", "Messages"),
        ("mail", "Mail"),
        ("calendar", "Calendar"),
        ("photos", "Photos"),
        ("music.note", "Music"),
        ("tv", "TV"),
        ("gamecontroller", "Game Center"),
        ("app.badge", "App Store")
    ]
    
    // Dock 应用
    private let dockApps = [
        ("safari", "Safari"),
        ("message", "Messages"),
        ("mail", "Mail"),
        ("calendar", "Calendar"),
        ("tv", "TV"),
        ("gamecontroller", "Game Center"),
        ("app.badge", "App Store"),
        ("folder", "Finder"),
        ("trash", "Trash")
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 桌面背景
                MagicBackground.emerald
                
                // 顶部任务栏
                topMenuBar
                    .frame(height: 28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                // 底部 Dock
                bottomDock
                    .frame(height: 80)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .background(Color.black)
    }
    
    // MARK: - Top Menu Bar
    private var topMenuBar: some View {
        VStack {
            HStack {
                // 左侧 Apple Logo
                Button(action: { isMenuBarExpanded.toggle() }) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 应用菜单
                if isMenuBarExpanded {
                    HStack(spacing: 20) {
                        ForEach(menuBarApps, id: \.0) { app in
                            menuBarAppIcon(systemName: app.0, name: app.1)
                        }
                    }
                    .padding(.leading, 20)
                    .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
                
                // 右侧状态信息
                HStack(spacing: 16) {
                    statusItem(icon: "wifi")
                    statusItem(icon: "battery.100")
                    statusItem(icon: "clock", text: "10:30")
                }
            }
            .padding(.horizontal, 16)
            .background(
                Color.black.opacity(0.4)
                    .background(.ultraThinMaterial)
            )
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Dock
    private var bottomDock: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                ForEach(dockApps, id: \.0) { app in
                    dockAppIcon(systemName: app.0, name: app.1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            )
            .padding(.bottom, 20)
            Spacer()
        }
    }
    
    // MARK: - Helper Views
    
    private func menuBarAppIcon(systemName: String, name: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 2) {
                Image(systemName: systemName)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func dockAppIcon(systemName: String, name: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: systemName)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(selectedApp == name ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: selectedApp)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            selectedApp = selectedApp == name ? nil : name
        }
    }
    
    private func statusItem(icon: String, text: String = "") -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
#Preview("App Store Desktop - Large") {
    AppStoreDesktop()
        .inMagicContainer(CGSizeMake(1280, 800), scale: 0.8)
}

#Preview("App Store Desktop - Small") {
    AppStoreDesktop()
        .frame(width: 800, height: 600)
}
