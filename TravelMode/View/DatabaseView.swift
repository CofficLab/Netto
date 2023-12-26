import SwiftUI
import SwiftData

struct DatabaseView: View {
    @Query(sort: \AppSetting.appId, order: .forward)
    var items: [AppSetting]
    
    var body: some View {
        Table(items, columns: {
            TableColumn("ID", value: \.appId)
            TableColumn("允许") {
                if $0.allowed {
                    Text("是").foregroundStyle(.green)
                } else {
                    Text("否").foregroundStyle(.red)
                }
            }
            TableColumn("操作") { i in
                if i.allowed {
                    Button("禁止") {
                        AppSetting.setDeny(i.appId)
                    }
                } else {
                    Button("允许") {
                        AppSetting.setAllow(i.appId)
                    }
                }
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
