import Foundation

struct MockPriceService: PriceServiceProtocol {
    func fetchPrices(for assets: [Asset]) async throws -> [UUID: Double] {
        guard !assets.isEmpty else { return [:] }
        var prices: [UUID: Double] = [:]
        for asset in assets {
            let baseline = baselinePrice(for: asset)
            let factor = Double.random(in: 0.98...1.02)
            prices[asset.id] = baseline * factor
        }
        return prices
    }

    private func baselinePrice(for asset: Asset) -> Double {
        if asset.currentPrice > 0 { return asset.currentPrice }
        if asset.averageCost > 0 { return asset.averageCost }
        if asset.idealBuyPrice > 0 { return asset.idealBuyPrice }
        return 1
    }
}
