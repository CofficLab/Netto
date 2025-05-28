import Foundation
import SwiftUI

class DataProvider: ObservableObject {
    static let shared = DataProvider()
    private init() {
        self.apps = SmartApp.appList
    }
    
    @Published var apps: [SmartApp] = []
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
