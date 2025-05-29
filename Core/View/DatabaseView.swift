import SwiftUI
import SwiftData

struct DatabaseView: View {
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
    }.frame(width: 700)
}

#Preview {
    RootView {
        DatabaseView()
    }
}
