import SwiftUI

struct AssetCardView: View {
    let asset: Asset
    let totalPortfolioValueCNY: Double

    private var currentPositionPercent: Double {
        asset.currentPositionRatio(totalPortfolioCNY: totalPortfolioValueCNY)
    }

    private var targetPositionPercent: Double {
        asset.targetPositionRatio
    }

    private var maxPositionPercent: Double {
        asset.maxPositionRatio ?? 100
    }

    private var positionDeviation: Double {
        currentPositionPercent - targetPositionPercent
    }

    private var deviationText: String {
        let absValue = abs(positionDeviation)
        if !asset.hasTargetPosition {
            return "尚未设置目标仓位"
        }
        if currentPositionPercent >= maxPositionPercent {
            return "已超过仓位上限"
        }
        if positionDeviation > 1 {
            return "超出目标 +\(String(format: "%.1f", absValue))%"
        }
        if positionDeviation < -1 {
            return "低于目标 -\(String(format: "%.1f", absValue))%"
        }
        return "接近目标仓位"
    }

    private var deviationColor: Color {
        if !asset.hasTargetPosition { return .textTertiary }
        if currentPositionPercent >= maxPositionPercent { return .valuationRed }
        if positionDeviation > 3 { return .valuationOrange }
        if positionDeviation < -3 { return .themePrimary }
        return .valuationDeepGreen
    }

    private var needsConfigGuidance: Bool {
        !asset.hasValuationConfigured || !asset.hasTargetPosition
    }

    private var guidanceText: String {
        switch (asset.hasValuationConfigured, asset.hasTargetPosition) {
        case (false, false): return "设置理想买卖价与目标仓位，开启估值与仓位分析"
        case (false, true):  return "设置理想买卖价，查看估值状态"
        case (true, false):  return "设置目标仓位，查看仓位偏离"
        case (true, true):   return ""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(asset.name)
                        .font(.sectionTitle)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: Spacing.xs) {
                        Text(asset.marketDisplayName)
                            .font(.smallCaption)
                            .foregroundColor(.textSecondary)

                        if asset.hasValuationConfigured {
                            Text(asset.valuationLevel.rawValue)
                                .font(.smallCaption)
                                .foregroundColor(asset.valuationLevel.color)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(asset.valuationLevel.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        } else {
                            Text("估值未设置")
                                .font(.smallCaption)
                                .foregroundColor(.textTertiary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.divider.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        }
                    }
                }

                Spacer()

                Text("\(asset.currencySymbol)\(formatPrice(asset.currentPrice, currency: asset.currency))")
                    .font(.assetPrice)
                    .foregroundColor(.textPrimary)
            }

            Spacer().frame(height: Spacing.md)

            VStack(spacing: Spacing.sm) {
                HStack {
                    Text("仓位")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", currentPositionPercent))%")
                        .font(.positionPercent)
                        .foregroundColor(.themePrimary)
                }

                PositionBar(
                    current: currentPositionPercent,
                    target: targetPositionPercent,
                    max: asset.maxPositionRatio
                )

                HStack {
                    Text(deviationText)
                        .font(.smallCaption)
                        .foregroundColor(deviationColor)
                    Spacer()
                    Text(asset.hasTargetPosition
                         ? "目标 \(String(format: "%.0f", targetPositionPercent))%"
                         : "未设目标")
                        .font(.smallCaption)
                        .foregroundColor(.textTertiary)
                }
            }

            if needsConfigGuidance {
                Spacer().frame(height: Spacing.sm)
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.smallCaption)
                    Text(guidanceText)
                        .font(.smallCaption)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.smallCaption)
                }
                .foregroundColor(.themePrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeLight)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private func formatPrice(_ price: Double, currency: String) -> String {
        AppNumberFormat.priceString(price, currency: currency, market: asset.market)
    }
}

struct PositionBar: View {
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
