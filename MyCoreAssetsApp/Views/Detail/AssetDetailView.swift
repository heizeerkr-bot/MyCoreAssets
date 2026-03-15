import SwiftUI

struct AssetDetailView: View {
    let asset: Asset

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Price Header
                priceSection

                // Position Analysis
                positionCard

                // Valuation Status
                valuationCard

                // Holding Info
                holdingCard

                // Deviation Alert
                if abs(asset.positionDeviation) > 1 || asset.isOverMax {
                    deviationAlert
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.pageBg)
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(asset.currencySymbol)\(formatPrice(asset.currentPrice))")
                    .font(.assetPrice)
                    .foregroundColor(.textPrimary)

                Spacer()

                HStack(spacing: Spacing.xs) {
                    Image(systemName: asset.priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11))
                    Text("\(asset.priceChange >= 0 ? "+" : "")\(String(format: "%.2f%%", asset.priceChange))")
                        .font(.caption)
                }
                .foregroundColor(asset.priceChange >= 0 ? .profitGreen : .lossRed)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    (asset.priceChange >= 0 ? Color.profitGreen : Color.lossRed).opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            }

            HStack {
                Text(asset.symbol)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                Text("·")
                    .foregroundColor(.textTertiary)
                Text(asset.market.rawValue)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                Spacer()
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Position Card

    private var positionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("仓位分析")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            // Large position number
            HStack(alignment: .firstTextBaseline) {
                Text("\(String(format: "%.1f", asset.currentPositionPercent))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.themePrimary)
                Text("%")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.themePrimary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("目标 \(String(format: "%.0f%%", asset.targetPositionPercent))")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("上限 \(String(format: "%.0f%%", asset.maxPositionPercent))")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }

            // Position bar (larger version)
            DetailPositionBar(
                current: asset.currentPositionPercent,
                target: asset.targetPositionPercent,
                max: asset.maxPositionPercent
            )

            // Legend
            HStack(spacing: Spacing.md) {
                legendItem(color: .themePrimary, label: "当前仓位")
                legendItem(color: .textTertiary, label: "目标")
                legendItem(color: .valuationRed.opacity(0.6), label: "上限")
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 3)
            Text(label)
                .font(.smallCaption)
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Valuation Card

    private var valuationCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("估值状态")
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(asset.valuation.label)
                    .font(.bodyText)
                    .fontWeight(.semibold)
                    .foregroundColor(asset.valuation.color)
            }

            // 5-level color bar
            ValuationBar(valuation: asset.valuation)

            // Price range
            HStack {
                VStack(alignment: .leading) {
                    Text("理想买入")
                        .font(.smallCaption)
                        .foregroundColor(.textTertiary)
                    Text("\(asset.currencySymbol)\(formatPrice(asset.idealBuyPrice))")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                VStack {
                    Text("当前价")
                        .font(.smallCaption)
                        .foregroundColor(.textTertiary)
                    Text("\(asset.currencySymbol)\(formatPrice(asset.currentPrice))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("理想卖出")
                        .font(.smallCaption)
                        .foregroundColor(.textTertiary)
                    Text("\(asset.currencySymbol)\(formatPrice(asset.idealSellPrice))")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Holding Card

    private var holdingCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("持仓信息")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            HStack {
                holdingRow(label: "持有数量", value: formatQuantity(asset.holdingQuantity))
                Spacer()
                holdingRow(label: "平均成本", value: "\(asset.currencySymbol)\(formatPrice(asset.averageCost))")
            }

            HStack {
                holdingRow(label: "当前市值", value: "¥\(formatNumber(asset.currentValueCNY))")
                Spacer()
                holdingRow(
                    label: "浮动盈亏",
                    value: "\(String(format: "%+.1f%%", asset.profitLossPercent))",
                    valueColor: asset.profitLossPercent >= 0 ? .profitGreen : .lossRed
                )
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func holdingRow(label: String, value: String, valueColor: Color = .textPrimary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.smallCaption)
                .foregroundColor(.textTertiary)
            Text(value)
                .font(.bodyText)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }

    // MARK: - Deviation Alert

    private var deviationAlert: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: asset.isOverMax ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundColor(asset.deviationColor)
            Text(asset.deviationText)
                .font(.caption)
                .foregroundColor(asset.deviationColor)
            Spacer()
        }
        .padding(Spacing.cardPadding)
        .background(asset.deviationColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Helpers

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

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    private func formatQuantity(_ qty: Double) -> String {
        if qty == floor(qty) {
            return String(format: "%.0f", qty)
        } else {
            return String(format: "%.4f", qty)
        }
    }
}

// MARK: - Detail Position Bar

struct DetailPositionBar: View {
    let current: Double
    let target: Double
    let max: Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let scale = width / (max + 10)
            let barHeight: CGFloat = 12

            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.divider.opacity(0.4))
                    .frame(height: barHeight)

                // Current fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        current >= max ? Color.valuationRed :
                        current > target ? Color.valuationOrange :
                        Color.themePrimary
                    )
                    .frame(width: min(current * scale, width), height: barHeight)

                // Target marker
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.textTertiary)
                        .frame(width: 2, height: 20)
                }
                .offset(x: target * scale - 1)

                // Max marker
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.valuationRed.opacity(0.6))
                        .frame(width: 2, height: 20)
                }
                .offset(x: max * scale - 1)
            }
        }
        .frame(height: 20)
    }
}

// MARK: - Valuation Bar

struct ValuationBar: View {
    let valuation: ValuationLevel

    private let levels: [ValuationLevel] = ValuationLevel.allCases

    var body: some View {
        VStack(spacing: Spacing.sm) {
            GeometryReader { geo in
                let segmentWidth = geo.size.width / CGFloat(levels.count)

                ZStack(alignment: .leading) {
                    // Color segments
                    HStack(spacing: 2) {
                        ForEach(levels.indices, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(levels[i].color)
                                .frame(height: 8)
                                .opacity(levels[i] == valuation ? 1 : 0.3)
                        }
                    }

                    // Current indicator
                    let index = CGFloat(levels.firstIndex(of: valuation) ?? 0)
                    Circle()
                        .fill(valuation.color)
                        .frame(width: 14, height: 14)
                        .shadow(color: valuation.color.opacity(0.4), radius: 3)
                        .offset(x: (index + 0.5) * segmentWidth - 7)
                        .offset(y: -3)
                }
            }
            .frame(height: 14)

            // Labels
            HStack {
                Text("低估")
                    .font(.system(size: 10))
                    .foregroundColor(.valuationDeepGreen)
                Spacer()
                Text("合理")
                    .font(.system(size: 10))
                    .foregroundColor(.valuationNeutral)
                Spacer()
                Text("高估")
                    .font(.system(size: 10))
                    .foregroundColor(.valuationRed)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AssetDetailView(asset: MockData.assets[1])
    }
}
