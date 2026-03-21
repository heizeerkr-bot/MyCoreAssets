import Foundation

protocol PriceServiceProtocol {
    func fetchPrices(for assets: [Asset]) async throws -> [UUID: Double]
}

enum PriceServiceError: Error {
    case invalidResponse
    case decodingFailed
    case allFailed
}
