import MagicCore
import MagicAlert
import OSLog
import SwiftUI

struct TileFilter: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var ui: UIProvider

    var body: some View {
        Picker("", selection: $ui.displayType) {
            Text("全部").tag(DisplayType.All)
            Text("允许").tag(DisplayType.Allowed)
            Text("禁止").tag(DisplayType.Rejected)
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 150)
        .font(.footnote)
        .frame(maxHeight: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 700)
}
