import SwiftUI

enum MarketCode: String, CaseIterable, Codable {
    case cn = "CN"
    case hk = "HK"
    case us = "US"
    case btc = "BTC"
    case fund = "FUND"

    var displayName: String {
        switch self {
        case .cn: return "A股"
        case .hk: return "港股"
        case .us: return "美股"
        case .btc: return "虚拟货币"
        case .fund: return "基金"
        }
    }
}

enum TradeType: String, CaseIterable, Codable {
    case buy = "BUY"
    case sell = "SELL"

    var displayName: String {
        switch self {
        case .buy: return "买入"
        case .sell: return "卖出"
        }
    }

    var tintColor: Color {
        switch self {
        case .buy: return .valuationDeepGreen
        case .sell: return .valuationRed
        }
    }
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

    var sortRank: Int {
        switch self {
        case .deepUndervalued: return 0
        case .undervalued: return 1
        case .fair: return 2
        case .overvalued: return 3
        case .deepOvervalued: return 4
        }
    }
}

enum DashboardSortOption: String, CaseIterable, Identifiable {
    case positionHighToLow = "仓位从高到低"
    case deviationHighToLow = "仓位偏离目标从大到小"
    case undervaluedFirst = "估值低估优先"

    var id: String { rawValue }
}

enum CurrencyConverter {
    static func fxRateToCNY(currency: String) -> Double {
        switch currency {
        case "CNY": return 1
        case "HKD": return 0.92
        case "USD": return 7.20
        default: return 1
        }
    }
}

enum AppNumberFormat {
    static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let twoDigits: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    static func wholeString(_ value: Double) -> String {
        whole.string(from: NSNumber(value: value)) ?? "0"
    }

    static func twoDigitString(_ value: Double) -> String {
        twoDigits.string(from: NSNumber(value: value)) ?? "0.00"
    }

    static func priceString(_ price: Double, currency: String, market: String) -> String {
        if price >= 10000 {
            return wholeString(price)
        }
        let isCrypto = currency == "USD" && market == MarketCode.btc.rawValue
        return String(format: isCrypto ? "%.4f" : "%.2f", price)
    }

    static func quantityString(_ quantity: Double) -> String {
        if quantity == floor(quantity) {
            return String(format: "%.0f", quantity)
        }
        return String(format: "%.4f", quantity)
    }
}

enum AppDateFormat {
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    static func timeString(_ date: Date) -> String {
        time.string(from: date)
    }

    static func dateTimeString(_ date: Date) -> String {
        dateTime.string(from: date)
    }
}
