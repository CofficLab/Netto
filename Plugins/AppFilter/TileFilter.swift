import MagicCore
import OSLog
import SwiftUI

struct TileFilter: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var ui: UIProvider

    var body: some View {
        Picker("Type", selection: $ui.displayType) {
            Text("All").tag(DisplayType.All)
            Text("Allowed").tag(DisplayType.Allowed)
            Text("Rejected").tag(DisplayType.Rejected)
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
