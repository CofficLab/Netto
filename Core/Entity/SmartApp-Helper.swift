import Foundation
import SwiftUI
import AppKit
import OSLog
import MagicCore

extension SmartApp: SuperLog {
    /// 获取当前系统中所有正在运行的应用程序列表
    ///
    /// - Returns: 包含所有正在运行的应用程序的数组
    static func getRunningAppList() -> [NSRunningApplication] {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications

        return runningApps
    }

    /// 根据标识符查找正在运行的应用程序
    ///
    /// - Parameter id: 要查找的应用程序标识符
    /// - Returns: 找到的应用程序实例，如果未找到则返回nil
    static func getApp(_ id: String) -> NSRunningApplication? {
        let apps = getRunningAppList()

        for app in apps {
            let bundleIdentifier = app.bundleIdentifier

            guard let bundleIdentifier = bundleIdentifier else {
                continue
            }

            if bundleIdentifier == id {
                return app
            }
        }

        os_log(.debug, "\(self.t) ⚠️ 未找到应用程序: \(id)")

        return nil
    }
}

// MARK: - Preview

/// 用于展示运行中应用列表的预览视图
struct RunningAppsPreview: View {
    @State private var runningApps: [NSRunningApplication] = []
    
    var body: some View {
        VStack {
            Text("当前运行的应用程序")
                .font(.headline)
                .padding()
            
            List(runningApps, id: \.bundleIdentifier) { app in
                HStack {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "questionmark.app")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(app.localizedName ?? "未知应用")
                            .font(.headline)
                        
                        if let bundleId = app.bundleIdentifier {
                            Text(bundleId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let bundleURL = app.bundleURL {
                            Text(bundleURL.absoluteString)
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.8))
                        }

                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: 400, height: 600)
        .onAppear {
            runningApps = SmartApp.getRunningAppList()
        }
    }
}

#Preview {
    RunningAppsPreview()
}
