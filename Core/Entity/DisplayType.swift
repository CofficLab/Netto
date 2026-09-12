import SwiftUI

enum DisplayType: CaseIterable {
    case All
    case Allowed
    case Rejected
}

#Preview {
    RootView(environment: .preview()) {
        ContentView()
    }
}
