import SwiftUI

// V2.0.1：看板资产卡片改成紧凑横向布局，wrapper 调用 CompactAssetRow。
// 旧的纵向大卡片（含仓位条+lightbulb 引导）已废弃；引导通过点击行进入详情页提供。

struct AssetCardView: View {
    let asset: Asset
    let totalPortfolioValueCNY: Double

    @AppStorage(PrivacyMode.storageKey) private var isPrivacy = false

    private var positionPct: Double {
        asset.currentPositionRatio(totalPortfolioCNY: totalPortfolioValueCNY)
    }

    var body: some View {
        CompactAssetRow(
            asset: asset,
            positionPct: positionPct,
            isPrivacy: isPrivacy
        )
    }
}

// MARK: - Legacy Position Bar (still used by AssetDetailView/Buy/Sell, will be migrated in PR 3)

struct LegacyPositionBar: View {
    let current: Double
    let target: Double
    let max: Double?

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let barHeight = Spacing.sm
            let maxLimit = max ?? 100
            let ceiling = Swift.max(maxLimit + 5, current + 5)
            let scale = width / CGFloat(ceiling)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.divider.opacity(0.5))
                    .frame(height: barHeight)

                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(
                        current >= maxLimit ? Color.valuationRed :
                        current > target ? Color.valuationOrange :
                        Color.themePrimary
                    )
                    .frame(width: Swift.min(CGFloat(current) * scale, width), height: barHeight)

                Rectangle()
                    .fill(Color.textTertiary)
                    .frame(width: Spacing.sm / Spacing.xs, height: Spacing.md)
                    .offset(x: CGFloat(target) * scale)

                if let max {
                    Rectangle()
                        .fill(Color.valuationRed.opacity(0.6))
                        .frame(width: Spacing.sm / Spacing.xs, height: Spacing.md)
                        .offset(x: CGFloat(max) * scale)
                }
            }
        }
        .frame(height: Spacing.md)
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        AssetCardView(
            asset: Asset(
                name: "贵州茅台",
                symbol: "600519",
                market: MarketCode.cn.rawValue,
                currency: "CNY",
                idealBuyPrice: 1500,
                idealSellPrice: 2200,
                currentPrice: 1680,
                holdingQuantity: 120,
                averageCost: 1550,
                targetPositionRatio: 25,
                maxPositionRatio: 35
            ),
            totalPortfolioValueCNY: 1_250_000
        )
    }
    .padding()
    .background(Color.pageBg)
}
