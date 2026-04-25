import Foundation
import SwiftData

@Model
final class Asset {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbol: String
    var market: String
    var currency: String
    var idealBuyPrice: Double
    var idealSellPrice: Double
    var currentPrice: Double
    var lastPriceUpdatedAt: Date?
    var holdingQuantity: Double
    var averageCost: Double
    var targetPositionRatio: Double
    var maxPositionRatio: Double?
    var isWatched: Bool
    var notes: String?
    var sortOrder: Int
    /// 通知防抖记录：JSON encoded `[AlertType.rawValue: Date]`。每种 AlertType 24h 内只通知一次。
    var alertStateJSON: String?
    /// 上次拉取分红/拆股事件的时间。24h 内不重复检测，减少 API 调用。
    var lastDividendCheckAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Transaction.asset)
    var transactions: [Transaction]

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        market: String,
        currency: String,
        idealBuyPrice: Double = 0,
        idealSellPrice: Double = 0,
        currentPrice: Double = 0,
        lastPriceUpdatedAt: Date? = nil,
        holdingQuantity: Double = 0,
        averageCost: Double = 0,
        targetPositionRatio: Double = 0,
        maxPositionRatio: Double? = nil,
        isWatched: Bool = true,
        notes: String? = nil,
        sortOrder: Int = 0,
        alertStateJSON: String? = nil,
        lastDividendCheckAt: Date? = nil,
        transactions: [Transaction] = []
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.market = market
        self.currency = currency
        self.idealBuyPrice = idealBuyPrice
        self.idealSellPrice = idealSellPrice
        self.currentPrice = currentPrice
        self.lastPriceUpdatedAt = lastPriceUpdatedAt
        self.holdingQuantity = holdingQuantity
        self.averageCost = averageCost
        self.targetPositionRatio = targetPositionRatio
        self.maxPositionRatio = maxPositionRatio
        self.isWatched = isWatched
        self.notes = notes
        self.sortOrder = sortOrder
        self.alertStateJSON = alertStateJSON
        self.lastDividendCheckAt = lastDividendCheckAt
        self.transactions = transactions
    }
}

extension Asset {
    var marketDisplayName: String {
        MarketCode(rawValue: market)?.displayName ?? market
    }

    var currencySymbol: String {
        switch currency {
        case "CNY": return "¥"
        case "HKD": return "HK$"
        case "USD": return "$"
        default: return ""
        }
    }

    var fxRateToCNY: Double {
        CurrencyConverter.fxRateToCNY(currency: currency)
    }

    var currentValueCNY: Double {
        currentPrice * holdingQuantity * fxRateToCNY
    }

    var profitLossPercent: Double {
        guard averageCost > 0 else { return 0 }
        return ((currentPrice - averageCost) / averageCost) * 100
    }

    var hasValuationConfigured: Bool {
        idealBuyPrice > 0 && idealSellPrice > 0 && idealSellPrice > idealBuyPrice
    }

    var hasTargetPosition: Bool {
        targetPositionRatio > 0
    }

    var valuationLevel: ValuationLevel {
        guard hasValuationConfigured else { return .fair }
        if currentPrice <= idealBuyPrice * 0.85 { return .deepUndervalued }
        if currentPrice <= idealBuyPrice { return .undervalued }
        if currentPrice < idealSellPrice { return .fair }
        if currentPrice < idealSellPrice * 1.15 { return .overvalued }
        return .deepOvervalued
    }

    func currentPositionRatio(totalPortfolioCNY: Double) -> Double {
        guard totalPortfolioCNY > 0 else { return 0 }
        return currentValueCNY / totalPortfolioCNY * 100
    }
}
