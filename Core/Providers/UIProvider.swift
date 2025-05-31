import Foundation
import Combine
import SwiftUI

@MainActor
class UIProvider: ObservableObject {
    static let shared = UIProvider()
    @Published var dbVisible: Bool = false
    @Published var displayType: DisplayType = .All
    @Published var showSystemApps: Bool = false
    private var cancellables = Set<AnyCancellable>()
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
