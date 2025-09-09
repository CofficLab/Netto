import Foundation
import StoreKit
import SwiftUI

public struct StoreProductDTO: Identifiable, Hashable, Codable,Sendable {
    public enum ProductKind: String, Codable, Sendable {
        case consumable
        case nonConsumable
        case autoRenewable
        case nonRenewable
        case unknown
    }

    public let id: String
    public let displayName: String
    public let displayPrice: String
    public let kind: ProductKind

    public init(id: String, displayName: String, displayPrice: String, kind: ProductKind) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.kind = kind
    }

    public static func toDTO(_ product: Product, kind: StoreProductDTO.ProductKind) -> StoreProductDTO {
        StoreProductDTO(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            kind: kind
        )
    }
}

public struct StoreProductGroupsDTO: Hashable, Codable, Sendable {
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

