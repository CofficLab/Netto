import ProviderShell
import SwiftUI

/// Preview-only host for package views. Production environment values are installed by App Host.
@MainActor
struct DashboardPreviewHost<Content: View>: View {
    @StateObject private var ui: UIProvider
    @StateObject private var shell: ShellCenter
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        _ui = StateObject(wrappedValue: UIProvider())
        _shell = StateObject(wrappedValue: ShellCenter())
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(ui)
            .environmentObject(shell)
    }
}

extension View {
    func dashboardPreviewRoot() -> some View {
        DashboardPreviewHost { self }
    }
}
