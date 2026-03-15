import SwiftUI

struct AssetCardView: View {
    let asset: Asset

    var body: some View {
        VStack(spacing: 0) {
            // Top row: name + price
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Text(asset.name)
                            .font(.sectionTitle)
                            .foregroundColor(.textPrimary)

                        Text(asset.symbol)
                            .font(.smallCaption)
                            .foregroundColor(.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.pageBg)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    }

                    HStack(spacing: Spacing.xs) {
                        Text(asset.market.rawValue)
                            .font(.smallCaption)
                            .foregroundColor(.textSecondary)

                        // Valuation badge
                        Text(asset.valuation.label)
                            .font(.smallCaption)
                            .fontWeight(.medium)
                            .foregroundColor(asset.valuation.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(asset.valuation.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("\(asset.currencySymbol)\(formatPrice(asset.currentPrice))")
                        .font(.sectionTitle)
                        .foregroundColor(.textPrimary)

                    Text("\(asset.priceChange >= 0 ? "+" : "")\(String(format: "%.2f%%", asset.priceChange))")
                        .font(.smallCaption)
                        .foregroundColor(asset.priceChange >= 0 ? .profitGreen : .lossRed)
                }
            }

            Spacer().frame(height: Spacing.md)

            // Position bar
            VStack(spacing: Spacing.sm) {
                HStack {
                    Text("仓位")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", asset.currentPositionPercent))%")
                        .font(.positionPercent)
                        .foregroundColor(.themePrimary)
                }

                PositionBar(
                    current: asset.currentPositionPercent,
                    target: asset.targetPositionPercent,
                    max: asset.maxPositionPercent
                )

                // Deviation hint
                HStack {
                    Text(asset.deviationText)
                        .font(.smallCaption)
                        .foregroundColor(asset.deviationColor)
                    Spacer()
                    Text("目标 \(String(format: "%.0f", asset.targetPositionPercent))%")
                        .font(.smallCaption)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func formatPrice(_ price: Double) -> String {
        if price >= 10000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: price)) ?? "0"
        } else if price >= 1 {
            return String(format: "%.2f", price)
        } else {
            return String(format: "%.4f", price)
        }
    }
}

// MARK: - Position Bar

struct PositionBar: View {
    let current: Double
    let target: Double
    let max: Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let barHeight: CGFloat = 8
            let ceiling = Swift.max(self.max + 5, current + 5)
            let scale = width / ceiling

            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.divider.opacity(0.5))
                    .frame(height: barHeight)

                // Current fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        current >= max ? Color.valuationRed :
                        current > target ? Color.valuationOrange :
                        Color.themePrimary
                    )
                    .frame(width: current * scale, height: barHeight)

                // Target line
                Rectangle()
                    .fill(Color.textTertiary)
                    .frame(width: 1.5, height: 14)
                    .offset(x: target * scale)

                // Max line
                Rectangle()
                    .fill(Color.valuationRed.opacity(0.6))
                    .frame(width: 1.5, height: 14)
                    .offset(x: max * scale)
            }
        }
        .frame(height: 14)
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(MockData.assets) { asset in
            AssetCardView(asset: asset)
        }
    }
    .padding()
    .background(Color.pageBg)
}
