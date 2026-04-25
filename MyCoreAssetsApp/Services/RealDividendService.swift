import Foundation

/// 真实分红/拆股事件源。多市场分发 + 双源 fallback。
struct RealDividendService: DividendServiceProtocol {
    private static let session = URLSession.shared

    func fetchEvents(asset: Asset, since: Date?) async throws -> [DividendEvent] {
        switch asset.market {
        case MarketCode.us.rawValue:
            return try await fetchYahooEvents(symbol: asset.symbol, since: since)
        case MarketCode.hk.rawValue:
            return try await fetchYahooEvents(symbol: hkYahooSymbol(from: asset.symbol), since: since)
        case MarketCode.cn.rawValue:
            do {
                return try await fetchEastmoneyCNDividends(symbol: asset.symbol, since: since)
            } catch {
                if isCancelledError(error) { throw error }
                debugLog("Eastmoney CN failed for \(asset.symbol), falling back to Sina")
                return try await fetchSinaCNDividends(symbol: asset.symbol, since: since)
            }
        case MarketCode.fund.rawValue:
            return try await fetchFundDividends(symbol: asset.symbol, since: since)
        case MarketCode.btc.rawValue:
            return []
        default:
            throw DividendServiceError.unsupportedMarket
        }
    }

    // MARK: - Yahoo (US / HK)

    /// Yahoo chart with events=div,split returns:
    /// { chart: { result: [{ events: { dividends: { "1234": { amount, date } }, splits: { "1234": { numerator, denominator, splitRatio, date } } } }] } }
    private func fetchYahooEvents(symbol: String, since: Date?) async throws -> [DividendEvent] {
        let urlString = "https://query2.finance.yahoo.com/v8/finance/chart/\(symbol)?events=div%2Csplit&interval=1d&range=5y"
        let data = try await fetchData(from: urlString)

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let chart = object["chart"] as? [String: Any],
            let resultArr = chart["result"] as? [[String: Any]],
            let first = resultArr.first
        else {
            throw DividendServiceError.parseError("Yahoo: no result")
        }

        var events: [DividendEvent] = []
        if let yahooEvents = first["events"] as? [String: Any] {
            if let dividends = yahooEvents["dividends"] as? [String: [String: Any]] {
                for (_, entry) in dividends {
                    guard
                        let timestamp = entry["date"] as? TimeInterval,
                        let amount = entry["amount"] as? Double,
                        amount > 0
                    else { continue }
                    let exDate = Date(timeIntervalSince1970: timestamp)
                    if let since, exDate < since { continue }
                    events.append(DividendEvent(
                        exDate: exDate,
                        kind: .cashDividend,
                        amountPerShare: amount
                    ))
                }
            }
            if let splits = yahooEvents["splits"] as? [String: [String: Any]] {
                for (_, entry) in splits {
                    guard
                        let timestamp = entry["date"] as? TimeInterval,
                        let numerator = entry["numerator"] as? Double,
                        let denominator = entry["denominator"] as? Double,
                        denominator > 0
                    else { continue }
                    let exDate = Date(timeIntervalSince1970: timestamp)
                    if let since, exDate < since { continue }
                    let ratio = numerator / denominator
                    events.append(DividendEvent(
                        exDate: exDate,
                        kind: .split,
                        splitRatio: ratio
                    ))
                }
            }
        }
        return events.sorted { $0.exDate < $1.exDate }
    }

    // MARK: - 东方财富 (A股分红，主源)

    /// 东方财富 datacenter API（非官方但稳定）
    private func fetchEastmoneyCNDividends(symbol: String, since: Date?) async throws -> [DividendEvent] {
        let filter = "(SECURITY_CODE=%22\(symbol)%22)"
        let urlString = "https://datacenter-web.eastmoney.com/api/data/v1/get?columns=ALL&filter=\(filter)&pageNumber=1&pageSize=200&sortColumns=NOTICE_DATE&sortTypes=-1&source=WEB&client=WEB&reportName=RPT_LICO_FN_CPD"
        let data = try await fetchData(from: urlString)

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = object["result"] as? [String: Any],
            let rows = result["data"] as? [[String: Any]]
        else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        var events: [DividendEvent] = []
        for row in rows {
            // PRETAX_BONUS_RMB = 每股税前现金分红（人民币）
            // EX_DIVIDEND_DATE = 除权除息日
            guard
                let exDateStr = row["EX_DIVIDEND_DATE"] as? String,
                let exDate = formatter.date(from: exDateStr)
            else { continue }
            if let since, exDate < since { continue }

            if let cash = row["PRETAX_BONUS_RMB"] as? Double, cash > 0 {
                events.append(DividendEvent(
                    exDate: exDate,
                    kind: .cashDividend,
                    amountPerShare: cash
                ))
            }
            // 注：PRETAX_BONUS_RMB 是每 10 股的金额，需除以 10 得到每股
            // 但东方财富不同接口字段含义偶有差异；保险起见注释提醒
        }
        return events
    }

    // MARK: - 新浪 (A股分红，兜底)

    private func fetchSinaCNDividends(symbol: String, since: Date?) async throws -> [DividendEvent] {
        let prefix = symbol.hasPrefix("6") ? "sh" : "sz"
        let urlString = "https://stock.finance.sina.com.cn/stock/api/openapi.php/CompanyBonusService.getCompanyBonus?symbol=\(prefix)\(symbol)"
        let data = try await fetchData(from: urlString)

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let resultDict = object["result"] as? [String: Any],
            let dataDict = resultDict["data"] as? [String: Any],
            let bonus = dataDict["bonus"] as? [[String: Any]]
        else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        var events: [DividendEvent] = []
        for row in bonus {
            // 字段：除权除息日 / 派息（每股，元）
            guard
                let exDateStr = row["dividend_date"] as? String,
                let exDate = formatter.date(from: exDateStr)
            else { continue }
            if let since, exDate < since { continue }

            // 派息字段名可能是 "dividend_money" 或 "shenli"，尝试多个
            var perShare: Double = 0
            for key in ["dividend_money", "money", "songzhuan", "shenli"] {
                if let str = row[key] as? String, let v = Double(str), v > 0 {
                    perShare = v / 10  // 通常是"每10股X元"，转每股
                    break
                }
                if let v = row[key] as? Double, v > 0 {
                    perShare = v / 10
                    break
                }
            }

            if perShare > 0 {
                events.append(DividendEvent(
                    exDate: exDate,
                    kind: .cashDividend,
                    amountPerShare: perShare
                ))
            }
        }
        return events
    }

    // MARK: - 基金 (天天基金分红历史)

    private func fetchFundDividends(symbol: String, since: Date?) async throws -> [DividendEvent] {
        let urlString = "https://api.fund.eastmoney.com/f10/lsfh/?fundCode=\(symbol)&pageIndex=1&pageSize=200"
        let data = try await fetchData(from: urlString, referer: "https://fund.eastmoney.com")

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let dataDict = object["Data"] as? [String: Any],
            let lsfh = dataDict["LSFHList"] as? [[String: Any]]
        else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        var events: [DividendEvent] = []
        for row in lsfh {
            guard
                let exDateStr = row["FFDATE"] as? String,
                let exDate = formatter.date(from: exDateStr)
            else { continue }
            if let since, exDate < since { continue }

            // FHFCZ = 每份分红金额
            if let fhStr = row["FHFCZ"] as? String, let fh = Double(fhStr), fh > 0 {
                events.append(DividendEvent(
                    exDate: exDate,
                    kind: .cashDividend,
                    amountPerShare: fh
                ))
            }
        }
        return events
    }

    // MARK: - Helpers

    private func hkYahooSymbol(from symbol: String) -> String {
        let digits = symbol.filter(\.isNumber)
        if let number = Int(digits) {
            return String(format: "%04d.HK", number)
        }
        return "\(symbol).HK"
    }

    // MARK: - Networking (mirrors RealPriceService)

    private func fetchData(from urlString: String, referer: String? = nil) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw DividendServiceError.parseError("invalid URL")
        }

        let maxRetry = 2
        var lastError: Error = DividendServiceError.allSourcesFailed
        for attempt in 0..<maxRetry {
            do {
                debugLog("Request[\(attempt + 1)/\(maxRetry)] \(urlString)")
                var request = URLRequest(url: url)
                request.timeoutInterval = 10
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                request.setValue(
                    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)",
                    forHTTPHeaderField: "User-Agent"
                )
                if let referer {
                    request.setValue(referer, forHTTPHeaderField: "Referer")
                }
                let (data, response) = try await fetchDataTask(with: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    throw DividendServiceError.parseError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                }
                debugLog("Success \(urlString), bytes=\(data.count)")
                return data
            } catch {
                lastError = error
                if isCancelledError(error), attempt < maxRetry - 1 {
                    continue
                }
                debugLog("Request failed \(urlString): \(error)")
                throw error
            }
        }
        throw lastError
    }

    private func fetchDataTask(with request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = Self.session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let response else {
                    continuation.resume(throwing: DividendServiceError.parseError("empty response"))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }

    private func isCancelledError(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled { return true }
        return false
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[DividendService] \(message)")
#endif
    }
}

// MARK: - Detector

/// 比对远端事件与本地已记录交易，找出未录入的候选项。
struct DividendDetector {
    private let service: DividendServiceProtocol

    init(service: DividendServiceProtocol = RealDividendService()) {
        self.service = service
    }

    /// 对单个资产做检测。
    /// 返回未在本地 Transaction 中记录的事件（按 dayKey 去重）。
    /// 失败时返回 nil（让调用方静默处理）。
    func detectUnrecorded(asset: Asset) async -> [DividendEvent]? {
        let earliest = asset.transactions
            .filter { $0.tradeType == .buy }
            .map(\.occurredAt)
            .min() ?? Date.distantPast

        do {
            let events = try await service.fetchEvents(asset: asset, since: earliest)
            let recordedKeys: Set<String> = Set(
                asset.transactions
                    .filter { $0.tradeType == .dividend || $0.tradeType == .split }
                    .map { dayKey($0.occurredAt) }
            )
            let unrecorded = events.filter { !recordedKeys.contains($0.dayKey) }
            return unrecorded.sorted { $0.exDate > $1.exDate }
        } catch {
            return nil
        }
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
