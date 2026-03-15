import SwiftUI

// MARK: - Enums

enum Market: String {
    case cn = "A股"
    case hk = "港股"
    case us = "美股"
    case crypto = "加密货币"
}

enum ValuationLevel: String, CaseIterable {
    case deepUndervalued = "极度低估"
    case undervalued = "比较低估"
    case fair = "合理"
    case overvalued = "比较高估"
    case deepOvervalued = "极度高估"

    var color: Color {
        switch self {
        case .deepUndervalued: return .valuationDeepGreen
        case .undervalued: return .valuationLightGreen
        case .fair: return .valuationNeutral
        case .overvalued: return .valuationOrange
        case .deepOvervalued: return .valuationRed
        }
    }

    var label: String { rawValue }
}

// MARK: - Asset Model

struct Asset: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let market: Market
    let currency: String

    // Prices (in original currency)
    let currentPrice: Double
    let idealBuyPrice: Double
    let idealSellPrice: Double
    let priceChange: Double // percentage

    // Position
    let currentPositionPercent: Double
    let targetPositionPercent: Double
    let maxPositionPercent: Double

    // Holding
    let holdingQuantity: Double
    let averageCost: Double
    let currentValueCNY: Double

    // Valuation
    let valuation: ValuationLevel

    var positionDeviation: Double {
        currentPositionPercent - targetPositionPercent
    }

    var isOverTarget: Bool { positionDeviation > 0 }
    var isOverMax: Bool { currentPositionPercent >= maxPositionPercent }

    var deviationText: String {
        let dev = abs(positionDeviation)
        if isOverMax {
            return "已达上限"
        } else if positionDeviation > 1 {
            return "超出目标 +\(String(format: "%.1f", dev))%"
        } else if positionDeviation < -1 {
            return "低于目标 -\(String(format: "%.1f", dev))%"
        } else {
            return "接近目标"
        }
    }

    var deviationColor: Color {
        if isOverMax { return .valuationRed }
        if positionDeviation > 3 { return .valuationOrange }
        if positionDeviation < -3 { return .themePrimary }
        return .valuationDeepGreen
    }

    var profitLossPercent: Double {
        guard averageCost > 0 else { return 0 }
        return (currentPrice - averageCost) / averageCost * 100
    }

    var currencySymbol: String {
        switch currency {
        case "CNY": return "¥"
        case "HKD": return "HK$"
        case "USD": return "$"
        default: return ""
        }
    }
}

// MARK: - Mock Data

enum MockData {
    static let initialCapital: Double = 1_250_000
    static let totalInvested: Double = 987_500

    static let assets: [Asset] = [
        Asset(
            name: "贵州茅台",
            symbol: "600519",
            market: .cn,
            currency: "CNY",
            currentPrice: 1681,
            idealBuyPrice: 1500,
            idealSellPrice: 2300,
            priceChange: 1.25,
            currentPositionPercent: 30.2,
            targetPositionPercent: 30,
            maxPositionPercent: 40,
            holdingQuantity: 300,
            averageCost: 1545,
            currentValueCNY: 504_300,
            valuation: .undervalued
        ),
        Asset(
            name: "腾讯控股",
            symbol: "00700",
            market: .hk,
            currency: "HKD",
            currentPrice: 388.6,
            idealBuyPrice: 300,
            idealSellPrice: 500,
            priceChange: -0.82,
            currentPositionPercent: 29.5,
            targetPositionPercent: 25,
            maxPositionPercent: 35,
            holdingQuantity: 800,
            averageCost: 355,
            currentValueCNY: 368_750,
            valuation: .fair
        ),
        Asset(
            name: "Apple",
            symbol: "AAPL",
            market: .us,
            currency: "USD",
            currentPrice: 198.5,
            idealBuyPrice: 150,
            idealSellPrice: 200,
            priceChange: 0.45,
            currentPositionPercent: 22.8,
            targetPositionPercent: 20,
            maxPositionPercent: 25,
            holdingQuantity: 150,
            averageCost: 165,
            currentValueCNY: 285_000,
            valuation: .overvalued
        ),
        Asset(
            name: "比特币",
            symbol: "BTC",
            market: .crypto,
            currency: "USD",
            currentPrice: 43500,
            idealBuyPrice: 50000,
            idealSellPrice: 100000,
            priceChange: 3.12,
            currentPositionPercent: 5.5,
            targetPositionPercent: 10,
            maxPositionPercent: 15,
            holdingQuantity: 0.15,
            averageCost: 38000,
            currentValueCNY: 68_750,
            valuation: .deepUndervalued
        ),
    ]

    static var totalValueCNY: Double {
        assets.reduce(0) { $0 + $1.currentValueCNY }
    }

    static var remainingCash: Double {
        initialCapital - totalInvested
    }
}
