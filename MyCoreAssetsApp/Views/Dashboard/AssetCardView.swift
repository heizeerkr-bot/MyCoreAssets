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
        if !asset.hasTargetPosition {
            return "尚未设置目标仓位"
        }
        if currentPositionPercent >= maxPositionPercent {
            return "已超过仓位上限"
        }
        if positionDeviation > 1 {
            return "高于目标 +\(String(format: "%.1f", positionDeviation))%"
        }
        if positionDeviation < -1 {
            return "低于目标 \(String(format: "%.1f", positionDeviation))%"
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
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 顶部行：资产名 + 市场 + 估值标签 / 价格 + chevron
            HStack(alignment: .top, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(asset.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: Spacing.sm) {
                        Text(asset.marketDisplayName)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.textSecondary)

                        valuationBadge
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: Spacing.sm)

                HStack(alignment: .center, spacing: Spacing.xs) {
                    Text("\(asset.currencySymbol)\(formatPrice(asset.currentPrice, currency: asset.currency))")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textTertiary.opacity(0.7))
                }
            }

            // 仓位区
            VStack(spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text("仓位")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textBody)
                    Spacer()
                    Text("\(String(format: "%.1f", currentPositionPercent))%")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.themePrimary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                PositionBar(
                    current: currentPositionPercent,
                    target: targetPositionPercent,
                    max: asset.maxPositionRatio,
                    fillColor: deviationColor
                )

                HStack(alignment: .firstTextBaseline) {
                    Text(deviationText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(deviationColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    Text(asset.hasTargetPosition
                         ? "目标 \(String(format: "%.0f", targetPositionPercent))%"
                         : "未设目标")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            if needsConfigGuidance {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                    Text(guidanceText)
                        .font(.system(size: 12, weight: .regular))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
                .foregroundColor(.themePrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeLight.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, Spacing.lg)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private func formatPrice(_ price: Double, currency: String) -> String {
        AppNumberFormat.priceString(price, currency: currency, market: asset.market)
    }

    @ViewBuilder
    private var valuationBadge: some View {
        if asset.hasValuationConfigured {
            Text(asset.valuationLevel.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(valuationColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(valuationColor.opacity(0.1))
                .clipShape(Capsule(style: .continuous))
                .fixedSize(horizontal: true, vertical: false)
        } else {
            Text("估值未设置")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.textTertiary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color.divider.opacity(0.45))
                .clipShape(Capsule(style: .continuous))
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var valuationColor: Color {
        asset.valuationLevel == .fair ? .themePrimary : asset.valuationLevel.color
    }
}

struct PositionBar: View {
    let current: Double
    let target: Double
    let max: Double?
    let fillColor: Color

    init(current: Double, target: Double, max: Double?, fillColor: Color = .themePrimary) {
        self.current = current
        self.target = target
        self.max = max
        self.fillColor = fillColor
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let barHeight: CGFloat = 6
            let maxLimit = max ?? 0
            let ceiling = Swift.max(10.0, current, target, maxLimit) + 5
            let scale = width / CGFloat(ceiling)
            let currentWidth = Swift.min(CGFloat(current) * scale, width)
            let markerMaxOffset = Swift.max(width - 2, 0)
            let targetOffset = Swift.min(Swift.max(CGFloat(target) * scale - 1, 0), markerMaxOffset)
            let maxOffset = Swift.min(Swift.max(CGFloat(maxLimit) * scale - 1, 0), markerMaxOffset)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.divider.opacity(0.7))
                    .frame(height: barHeight)

                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(fillColor)
                    .frame(width: currentWidth, height: barHeight)

                if target > 0 {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.valuationOrange.opacity(0.8))
                        .frame(width: 2, height: 18)
                        .offset(x: targetOffset)
                }

                if maxLimit > 0 {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.valuationRed.opacity(0.75))
                        .frame(width: 2, height: 18)
                        .offset(x: maxOffset)
                }
            }
            .frame(height: 18)
        }
        .frame(height: 18)
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
