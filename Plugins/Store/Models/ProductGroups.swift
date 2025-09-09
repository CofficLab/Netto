import Foundation
import MagicCore
import StoreKit
import SwiftUI

// MARK: - Types

public struct ProductGroups {
    public let cars: [Product]
    public let subscriptions: [Product]
    public let nonRenewables: [Product]
    public let fuel: [Product]

    public init(cars: [Product], subscriptions: [Product], nonRenewables: [Product], fuel: [Product]) {
        self.cars = cars
        self.subscriptions = subscriptions
        self.nonRenewables = nonRenewables
        self.fuel = fuel
    }

    // MARK: - DTO

    public func toDTO() -> StoreProductGroupsDTO {
        return StoreProductGroupsDTO(
            cars: cars.map { StoreProductDTO.toDTO($0, kind: .nonConsumable) },
            subscriptions: subscriptions.map { StoreProductDTO.toDTO($0, kind: .autoRenewable) },
            nonRenewables: nonRenewables.map { StoreProductDTO.toDTO($0, kind: .nonRenewable) },
            fuel: fuel.map { StoreProductDTO.toDTO($0, kind: .consumable) }
        )
    }
    
    // MARK: - Factory
    public static func classify(storeProducts: [Product]) -> ProductGroups {
        var newCars: [Product] = []
        var newSubscriptions: [Product] = []
        var newNonRenewables: [Product] = []
        var newFuel: [Product] = []

        for product in storeProducts {
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

        return ProductGroups(
            cars: sortByPrice(newCars),
            subscriptions: sortByPrice(newSubscriptions),
            nonRenewables: sortByPrice(newNonRenewables),
            fuel: sortByPrice(newFuel)
        )
    }

    // MARK: - Helpers
    public static func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { $0.price < $1.price })
    }
}
