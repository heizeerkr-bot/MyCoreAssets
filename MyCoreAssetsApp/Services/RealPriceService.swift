import Foundation

struct RealPriceService: PriceServiceProtocol {
    private let session: URLSession = .shared

    func fetchPrices(for assets: [Asset]) async throws -> [UUID: Double] {
        guard !assets.isEmpty else { return [:] }

        debugLog("Start fetching \(assets.count) assets")
        var prices: [UUID: Double] = [:]
        var cancelledCount = 0
        var failedCount = 0
        for asset in assets {
            do {
                let price = try await fetchPrice(for: asset)
                prices[asset.id] = price
                debugLog("Fetched \(asset.market)-\(asset.symbol): \(price)")
            } catch {
                if isCancelledError(error) {
                    cancelledCount += 1
                    debugLog("Cancelled \(asset.market)-\(asset.symbol)")
                    continue
                }
                failedCount += 1
                print("Price fetch failed for \(asset.symbol): \(error)")
            }
        }

        if prices.isEmpty {
            if cancelledCount > 0, failedCount == 0 {
                debugLog("All requests cancelled")
                throw URLError(.cancelled)
            }
            debugLog("All requests failed")
            throw PriceServiceError.allFailed
        }
        debugLog("Completed with \(prices.count) prices")
        return prices
    }

    // MARK: - Router

    private func fetchPrice(for asset: Asset) async throws -> Double {
        switch asset.market {
        case MarketCode.cn.rawValue:
            do {
                return try await fetchTencentPrice(prefix: cnPrefix(for: asset.symbol), symbol: asset.symbol)
            } catch {
                return try await fetchCNPriceFromYahoo(symbol: asset.symbol)
            }
        case MarketCode.hk.rawValue:
            do {
                return try await fetchTencentPrice(prefix: "hk", symbol: asset.symbol)
            } catch {
                return try await fetchHKPriceFromYahoo(symbol: asset.symbol)
            }
        case MarketCode.us.rawValue:
            return try await fetchUSPrice(symbol: asset.symbol)
        case MarketCode.btc.rawValue:
            return try await fetchCryptoPrice(symbol: asset.symbol)
        case MarketCode.fund.rawValue:
            return try await fetchFundPrice(symbol: asset.symbol)
        default:
            throw PriceServiceError.invalidResponse
        }
    }

    // MARK: - A股 + 港股 (腾讯行情 web.sqt.gtimg.cn)

    private func fetchTencentPrice(prefix: String, symbol: String) async throws -> Double {
        let urlString = "https://web.sqt.gtimg.cn/q=\(prefix)\(symbol)"
        let data = try await fetchData(from: urlString)

        guard let raw = decodeTencentQuote(data) else {
            throw PriceServiceError.decodingFailed
        }

        // Format: v_sz000333="51~美的集团~000333~75.12~..."
        // Price is at index 3 when split by ~
        let fields = raw.components(separatedBy: "~")
        guard fields.count > 3, let price = Double(fields[3]), price > 0 else {
            throw PriceServiceError.decodingFailed
        }
        return price
    }

    // MARK: - 美股 (Yahoo Finance v8)

    private func fetchHKPriceFromYahoo(symbol: String) async throws -> Double {
        let formatted = hkYahooSymbol(from: symbol)
        let urlString = "https://query2.finance.yahoo.com/v8/finance/chart/\(formatted)?interval=1d&range=1d"
        return try await fetchYahooPrice(urlString: urlString)
    }

    private func fetchCNPriceFromYahoo(symbol: String) async throws -> Double {
        let formatted = cnYahooSymbol(from: symbol)
        let urlString = "https://query2.finance.yahoo.com/v8/finance/chart/\(formatted)?interval=1d&range=1d"
        return try await fetchYahooPrice(urlString: urlString)
    }

    private func fetchUSPrice(symbol: String) async throws -> Double {
        let urlString = "https://query2.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=1d&range=1d"
        return try await fetchYahooPrice(urlString: urlString)
    }

    private func fetchYahooPrice(urlString: String) async throws -> Double {
        let data = try await fetchData(from: urlString)
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let chart = object["chart"] as? [String: Any],
            let result = chart["result"] as? [[String: Any]],
            let first = result.first,
            let meta = first["meta"] as? [String: Any],
            let price = meta["regularMarketPrice"] as? Double,
            price > 0
        else {
            throw PriceServiceError.decodingFailed
        }
        return price
    }

    // MARK: - 加密货币 (Binance data-api)

    private func fetchCryptoPrice(symbol: String) async throws -> Double {
        let normalized = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let pair = normalized.hasSuffix("USDT") ? normalized : "\(normalized)USDT"
        let urlString = "https://data-api.binance.vision/api/v3/ticker/price?symbol=\(pair)"
        let data = try await fetchData(from: urlString)
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let priceStr = object["price"] as? String,
            let price = Double(priceStr),
            price > 0
        else {
            throw PriceServiceError.decodingFailed
        }
        return price
    }

    // MARK: - 基金 (天天基金 fundgz)

    private func fetchFundPrice(symbol: String) async throws -> Double {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let urlString = "https://fundgz.1234567.com.cn/js/\(symbol).js?rt=\(timestamp)"
        let data = try await fetchData(from: urlString)
        guard let raw = String(data: data, encoding: .utf8) else {
            throw PriceServiceError.decodingFailed
        }

        let pattern = #"jsonpgz\((.*)\);?"#
        let regex = try NSRegularExpression(pattern: pattern)
        let ns = raw as NSString
        guard
            let match = regex.firstMatch(in: raw, range: NSRange(location: 0, length: ns.length)),
            match.numberOfRanges > 1
        else {
            throw PriceServiceError.decodingFailed
        }

        let jsonString = ns.substring(with: match.range(at: 1))
        guard
            let jsonData = jsonString.data(using: .utf8),
            let object = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let gsz = object["gsz"] as? String,
            let price = Double(gsz),
            price > 0
        else {
            throw PriceServiceError.decodingFailed
        }
        return price
    }

    // MARK: - Networking

    private func fetchData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw PriceServiceError.invalidResponse
        }

        let maxRetry = 2
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
                let (data, response) = try await fetchDataTask(with: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    if let http = response as? HTTPURLResponse {
                        debugLog("HTTP \(http.statusCode) for \(urlString)")
                    }
                    throw PriceServiceError.invalidResponse
                }
                debugLog("Success \(urlString), bytes=\(data.count)")
                return data
            } catch {
                if isCancelledError(error), attempt < maxRetry - 1 {
                    debugLog("Cancelled \(urlString), retrying")
                    continue
                }
                debugLog("Request failed \(urlString): \(error)")
                throw error
            }
        }
        throw PriceServiceError.invalidResponse
    }

    private func fetchDataTask(with request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let response else {
                    continuation.resume(throwing: PriceServiceError.invalidResponse)
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }

    // MARK: - Helpers

    private func cnPrefix(for symbol: String) -> String {
        if symbol.hasPrefix("6") { return "sh" }
        return "sz"
    }

    private func hkYahooSymbol(from symbol: String) -> String {
        let digits = symbol.filter(\.isNumber)
        if let number = Int(digits) {
            return String(format: "%04d.HK", number)
        }
        return "\(symbol).HK"
    }

    private func cnYahooSymbol(from symbol: String) -> String {
        let digits = symbol.filter(\.isNumber)
        let normalized = digits.isEmpty ? symbol : digits
        if normalized.hasPrefix("6") {
            return "\(normalized).SS"
        }
        return "\(normalized).SZ"
    }

    private func decodeTencentQuote(_ data: Data) -> String? {
        let gbEncoding = CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        )
        if let gbString = String(data: data, encoding: String.Encoding(rawValue: gbEncoding)) {
            return gbString
        }
        return String(data: data, encoding: .utf8)
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
        print("[PriceService] \(message)")
#endif
    }
}
