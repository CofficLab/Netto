import MagicCore
import SwiftUI

public struct ContentView: View {
    @EnvironmentObject private var ui: UIProvider

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            TopBar()

            AppList()
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("")
    }
}

#Preview("APP") {
    DashboardPreviewHost { ContentView() }
    .frame(width: 700)
    .frame(height: 800)
}
