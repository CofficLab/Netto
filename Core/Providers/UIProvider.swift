import Foundation
import Combine
import SwiftUI

@MainActor
class UIProvider: ObservableObject {
    static let shared = UIProvider()
    
    @Published var dbVisible: Bool = false
    @Published var displayType: DisplayType = .All
    @Published var showSystemApps: Bool = false
    @Published var hoveredAppId: String = ""
    
    func setHoveredAppId(_ id: String) {
        self.hoveredAppId = id
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
