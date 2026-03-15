import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var asset: Asset?
    var type: String
    var price: Double
    var quantity: Double
    var occurredAt: Date
    var fxRateUsed: Double?
    var cnyAmount: Double?

    init(
        id: UUID = UUID(),
        asset: Asset? = nil,
        type: String,
        price: Double,
        quantity: Double,
        occurredAt: Date = .now,
        fxRateUsed: Double? = nil,
        cnyAmount: Double? = nil
    ) {
        self.id = id
        self.asset = asset
        self.type = type
        self.price = price
        self.quantity = quantity
        self.occurredAt = occurredAt
        self.fxRateUsed = fxRateUsed
        self.cnyAmount = cnyAmount
    }
}

extension Transaction {
    var tradeType: TradeType {
        TradeType(rawValue: type) ?? .buy
    }

    var tradeAmountInOriginalCurrency: Double {
        price * quantity
    }
}
