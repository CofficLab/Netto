import Foundation
import StoreKit
import SwiftUI

public struct StoreProductDTO: Identifiable, Hashable,Sendable {
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
    public var description: String = ""
    public let subscription: SubscriptionInfoDTO?

    public init(id: String, displayName: String, displayPrice: String, kind: ProductKind, subscription: SubscriptionInfoDTO? = nil, description: String) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.kind = kind
        self.subscription = subscription
        self.description = description
    }

    public static func toDTO(_ product: Product, kind: StoreProductDTO.ProductKind) -> StoreProductDTO {
        var subscriptionDTO: SubscriptionInfoDTO? = nil
        if kind == .autoRenewable, let info = product.subscription {
            subscriptionDTO = info.toDTO()
        }

        return StoreProductDTO(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            kind: kind,
            subscription: subscriptionDTO, description: product.description
        )
    }
}

extension Product {
    func toNonConsumableDTO() -> StoreProductDTO {
        .toDTO(self, kind: .nonConsumable)
    }
}

// MARK: - Preview

#Preview("Debug") {
    DebugView()
        .inRootView()
        .frame(height: 800)
}

