import SwiftUI

struct AppList: View {
    struct AppWrapper: Identifiable {
        var id: String = UUID().uuidString
        var app: NSRunningApplication
        
        var appName: String {
            app.localizedName ?? ""
        }
        var appId: String {
            app.bundleIdentifier ?? ""
        }
        var appIcon: NSImage {
            app.icon ?? NSImage()
        }
    }
    
    @State private var apps: [AppWrapper] = []
    
    var body: some View {
        VStack {
            Table(apps, columns: {
                TableColumn("名称") {
                    Image(nsImage: $0.appIcon)
                }
                TableColumn("名称", value: \.appName)
                TableColumn("ID", value: \.appId)
            })
        }
        .onAppear {
            apps = AppHelper.getRunningAppList().map({
                AppWrapper(app: $0)
            })
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
}

#Preview {
    RootView {
        AppList()
    }
}
