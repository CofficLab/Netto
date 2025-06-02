import SwiftUI
import SwiftData

struct DBSettingView: View {
    @Query(sort: \AppSetting.appId, order: .forward)
    var items: [AppSetting]
    
    var body: some View {
        Table(items, columns: {
            TableColumn("ID", value: \.appId)
            TableColumn("Allowed") {
                if $0.allowed {
                    Text("Yes").foregroundStyle(.green)
                } else {
                    Text("No").foregroundStyle(.red)
                }
            }
            TableColumn("Action") { i in
                AppAction(shouldAllow: .constant(true), appId: i.appId)
            }
        })
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 500)
}

#Preview {
    RootView {
        DBSettingView()
    }
}

#Preview("防火墙事件视图") {
    RootView {
        DBEventView()
    }
    .frame(width: 600, height: 600)
}
