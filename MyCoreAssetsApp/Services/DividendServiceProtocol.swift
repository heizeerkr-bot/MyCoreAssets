import Foundation

/// 分红/拆股事件（自动检测得到的候选项）
struct DividendEvent: Identifiable, Hashable {
    enum Kind: String, Codable {
        case cashDividend
        case split
    }

    let id: UUID
    let exDate: Date
    let kind: Kind
    /// cashDividend 时使用：每股股息（原币种）
    let amountPerShare: Double
    /// split 时使用：拆股比率（2.0 = 1股拆2股；0.5 = 反向并股）
    let splitRatio: Double

    init(
        id: UUID = UUID(),
        exDate: Date,
        kind: Kind,
        amountPerShare: Double = 0,
        splitRatio: Double = 1
    ) {
        self.id = id
        self.exDate = exDate
        self.kind = kind
        self.amountPerShare = amountPerShare
        self.splitRatio = splitRatio
    }

    /// 用于去重比对的"日键"：YYYY-MM-DD（utc）
    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: exDate)
    }
}

protocol DividendServiceProtocol {
    /// 拉取该资产从 since 到现在的分红/拆股事件。
    /// since 为 nil 时拉取最近 5 年。
    /// 失败时抛错，调用方负责静默处理。
    func fetchEvents(asset: Asset, since: Date?) async throws -> [DividendEvent]
}

enum DividendServiceError: Error {
    case unsupportedMarket
    case allSourcesFailed
    case parseError(String)
}
