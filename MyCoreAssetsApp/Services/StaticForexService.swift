import Foundation

struct StaticForexService: ForexServiceProtocol {
    func fetchRates() async throws -> [String: Double] {
        [
            "CNY": 1,
            "HKD": 0.92,
            "USD": 7.20,
        ]
    }
}
