import Foundation
import StoreKit
import SwiftUI

public struct ProductGroupsDTO: Hashable, Sendable {
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

    public init(cars: [Product], subscriptions: [Product], nonRenewables: [Product], fuel: [Product]) {
        self.cars = cars.map { StoreProductDTO.toDTO($0, kind: .nonConsumable) }
        self.subscriptions = subscriptions.map { StoreProductDTO.toDTO($0, kind: .autoRenewable) }
        self.nonRenewables = nonRenewables.map { StoreProductDTO.toDTO($0, kind: .nonRenewable) }
        self.fuel = fuel.map { StoreProductDTO.toDTO($0, kind: .consumable) }
    }

    public init(products: [Product]) {
        var newCars: [Product] = []
        var newSubscriptions: [Product] = []
        var newNonRenewables: [Product] = []
        var newFuel: [Product] = []

        for product in products {
            switch product.type {
            case .consumable:
                newFuel.append(product)
            case .nonConsumable:
                newCars.append(product)
            case .autoRenewable:
                newSubscriptions.append(product)
            case .nonRenewable:
                newNonRenewables.append(product)
            default:
                break
            }
        }

        self.cars = newCars.map { StoreProductDTO.toDTO($0, kind: .nonConsumable) }
        self.subscriptions = newSubscriptions.map { StoreProductDTO.toDTO($0, kind: .autoRenewable) }
        self.nonRenewables = newNonRenewables.map { StoreProductDTO.toDTO($0, kind: .nonRenewable) }
        self.fuel = newFuel.map { StoreProductDTO.toDTO($0, kind: .consumable) }
    }
}

// MARK: - Preview

#Preview("Debug") {
    DebugView()
        .inRootView()
        .frame(height: 800)
}

#Preview("Buy") {
    PurchaseView()
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
        .frame(height: 800)
}
