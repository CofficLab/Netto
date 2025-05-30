import MagicCore
import OSLog
import SwiftUI

struct FilterBar: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var app: UIProvider

    var body: some View {
        HStack {
            Picker("Type", selection: $app.displayType) {
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

            Spacer()
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .background(MagicBackground.colorTeal.opacity(0.3))
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 700)
}
