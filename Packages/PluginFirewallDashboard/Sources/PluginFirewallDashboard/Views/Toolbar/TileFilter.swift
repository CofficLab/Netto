import OSLog
import SwiftUI

struct TileFilter: View {
    @EnvironmentObject var ui: UIProvider

    var body: some View {
        Picker("", selection: $ui.displayType) {
            Text("全部").tag(DisplayType.All).accessibilityIdentifier("netto.filter.all")
            Text("允许").tag(DisplayType.Allowed).accessibilityIdentifier("netto.filter.allowed")
            Text("禁止").tag(DisplayType.Rejected).accessibilityIdentifier("netto.filter.rejected")
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("netto.dashboard.filter")
        .frame(width: 150)
        .font(.footnote)
        .frame(maxHeight: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}
