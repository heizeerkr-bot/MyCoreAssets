import Foundation

protocol ForexServiceProtocol {
    func fetchRates() async throws -> [String: Double]
}
