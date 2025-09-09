import Foundation
import SwiftUI

public struct StoreProductGroupsDTO: Hashable, Sendable {
    public let cars: [StoreProductDTO]
    public let subscriptions: [StoreProductDTO]
    public let nonRenewables: [StoreProductDTO]
    public let fuel: [StoreProductDTO]

    public init(cars: [StoreProductDTO], subscriptions: [StoreProductDTO], nonRenewables: [StoreProductDTO], fuel: [StoreProductDTO]) {
        self.cars = cars
        self.subscriptions = subscriptions
        self.nonRenewables = nonRenewables
        self.fuel = fuel
    }
}

// MARK: - Preview

#Preview("Debug") {
    DebugView()
        .inRootView()
        .frame(height: 800)
}

#Preview("Buy") {
    BuySetting()
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
        .frame(height: 800)
}
