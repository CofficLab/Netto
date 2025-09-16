import Foundation
import StoreKit
import SwiftUI

public struct ProductGroupsDTO: Hashable, Sendable {
    public let cars: [StoreProductDTO]
    public let subscriptionGroups: [SubscriptionGroupDTO]
    public let nonRenewables: [StoreProductDTO]
    public let fuel: [StoreProductDTO]

    public init(cars: [StoreProductDTO], subscriptionGroups: [SubscriptionGroupDTO], nonRenewables: [StoreProductDTO], fuel: [StoreProductDTO]) {
        self.cars = cars
        self.subscriptionGroups = subscriptionGroups
        self.nonRenewables = nonRenewables
        self.fuel = fuel
    }

    public init(cars: [Product], subscriptions: [Product], nonRenewables: [Product], fuel: [Product]) {
        self.cars = cars.map { StoreProductDTO.toDTO($0, kind: .nonConsumable) }
        
        // 将订阅产品按组聚合
        let subscriptionDTOs = subscriptions.map { StoreProductDTO.toDTO($0, kind: .autoRenewable) }
        self.subscriptionGroups = Self.createSubscriptionGroups(from: subscriptionDTOs)
        
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
        
        // 将订阅产品按组聚合
        let subscriptionDTOs = newSubscriptions.map { StoreProductDTO.toDTO($0, kind: .autoRenewable) }
        self.subscriptionGroups = Self.createSubscriptionGroups(from: subscriptionDTOs)
        
        self.nonRenewables = newNonRenewables.map { StoreProductDTO.toDTO($0, kind: .nonRenewable) }
        self.fuel = newFuel.map { StoreProductDTO.toDTO($0, kind: .consumable) }
    }
}

// MARK: - Subscription Groups
extension ProductGroupsDTO {
    /// 创建订阅组（按订阅组 ID 聚合订阅类商品）
    ///
    /// - Parameter subscriptions: 订阅产品列表
    /// - Returns: 订阅组列表：`[SubscriptionGroupDTO]`
    private static func createSubscriptionGroups(from subscriptions: [StoreProductDTO]) -> [SubscriptionGroupDTO] {
        // 按订阅组 ID 聚合，避免为同一组重复创建条目
        var grouped: [String: [StoreProductDTO]] = [:]
        for product in subscriptions {
            let groupId = product.subscription?.groupID ?? "unknown"
            grouped[groupId, default: []].append(product)
        }

        // 组名优先取 StoreKit 的显示名，其次回退为组 ID
        let groups: [SubscriptionGroupDTO] = grouped.map { groupId, items in
            let nameFromProduct = items.first?.subscription?.groupDisplayName
            let displayName = nameFromProduct ?? groupId
            return SubscriptionGroupDTO(name: displayName, id: groupId, subscriptions: items)
        }

        return groups
    }
    
    /// 获取所有订阅产品（扁平化所有订阅组中的订阅）
    ///
    /// - Returns: 所有订阅产品的列表
    public var subscriptions: [StoreProductDTO] {
        return subscriptionGroups.flatMap { $0.subscriptions }
    }
    
    /// 根据订阅组 ID 查找订阅组
    ///
    /// - Parameter groupId: 订阅组 ID
    /// - Returns: 对应的订阅组，如果不存在则返回 nil
    public func subscriptionGroup(withId groupId: String) -> SubscriptionGroupDTO? {
        return subscriptionGroups.first { $0.id == groupId }
    }
}

// MARK: - Preview

#Preview("Debug") {
    DebugView()
        .inRootView()
        .frame(height: 1000)
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
