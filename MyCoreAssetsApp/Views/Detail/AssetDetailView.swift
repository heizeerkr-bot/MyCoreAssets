import SwiftData
import SwiftUI

struct AssetDetailView: View {
    let asset: Asset
    let totalPortfolioValueCNY: Double

    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]

    private var assetTransactions: [Transaction] {
        transactions.filter { $0.asset?.id == asset.id }
    }

    private var recentTransactions: [Transaction] {
        Array(assetTransactions.prefix(5))
    }

    private var currentPositionPercent: Double {
        asset.currentPositionRatio(totalPortfolioCNY: totalPortfolioValueCNY)
    }

    private var targetPositionPercent: Double {
        asset.targetPositionRatio
    }

    private var maxPositionPercent: Double? {
        asset.maxPositionRatio
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                priceCard
                positionCard
                valuationCard
                holdingCard
                transactionCard
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.pageBg)
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("当前价格")
                .font(.caption)
                .foregroundColor(.textSecondary)

            Text("\(asset.currencySymbol)\(formatPrice(asset.currentPrice, currency: asset.currency, market: asset.market))")
                .font(.assetPrice)
                .foregroundColor(.textPrimary)

            HStack(spacing: Spacing.xs) {
                Text(asset.symbol)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                Text("·")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                Text(asset.marketDisplayName)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private var positionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("仓位分析")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            HStack {
                Text("\(String(format: "%.1f", currentPositionPercent))%")
                    .font(.positionPercent)
                    .foregroundColor(.themePrimary)
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("目标 \(String(format: "%.0f%%", targetPositionPercent))")
                        .font(.smallCaption)
                        .foregroundColor(.textSecondary)
                    if let maxPositionPercent {
                        Text("上限 \(String(format: "%.0f%%", maxPositionPercent))")
                            .font(.smallCaption)
                            .foregroundColor(.textTertiary)
                    }
                }
            }

            PositionBar(
                current: currentPositionPercent,
                target: targetPositionPercent,
                max: maxPositionPercent
            )
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private var valuationCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("估值状态")
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(asset.valuationLevel.rawValue)
                    .font(.caption)
                    .foregroundColor(asset.valuationLevel.color)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(asset.valuationLevel.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            }

            ValuationScaleView(level: asset.valuationLevel)

            HStack {
                priceItem(title: "理想买入", value: "\(asset.currencySymbol)\(formatPrice(asset.idealBuyPrice, currency: asset.currency, market: asset.market))")
                Spacer()
                priceItem(title: "理想卖出", value: "\(asset.currencySymbol)\(formatPrice(asset.idealSellPrice, currency: asset.currency, market: asset.market))")
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private func priceItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.smallCaption)
                .foregroundColor(.textTertiary)
            Text(value)
                .font(.bodyText)
                .foregroundColor(.textPrimary)
        }
    }

    private var holdingCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("持仓信息")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            HStack {
                holdingItem(title: "持有数量", value: formatQuantity(asset.holdingQuantity))
                Spacer()
                holdingItem(title: "平均成本", value: "\(asset.currencySymbol)\(formatPrice(asset.averageCost, currency: asset.currency, market: asset.market))")
            }
            HStack {
                holdingItem(title: "当前市值", value: "¥\(AppNumberFormat.wholeString(asset.currentValueCNY))")
                Spacer()
                holdingItem(
                    title: "浮动盈亏",
                    value: "\(String(format: "%+.1f%%", asset.profitLossPercent))",
                    tint: asset.profitLossPercent >= 0 ? .profitGreen : .lossRed
                )
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private func holdingItem(title: String, value: String, tint: Color = .textPrimary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.smallCaption)
                .foregroundColor(.textTertiary)
            Text(value)
                .font(.bodyText)
                .foregroundColor(tint)
        }
    }

    private var transactionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("最近交易")
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                Spacer()
                NavigationLink {
                    AssetTransactionListView(asset: asset)
                } label: {
                    Text("查看全部记录")
                        .font(.caption)
                        .foregroundColor(.themePrimary)
                }
                .buttonStyle(.plain)
            }

            if recentTransactions.isEmpty {
                Text("暂无交易记录")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            } else {
                ForEach(recentTransactions) { transaction in
                    transactionRow(transaction)
                }
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(transaction.tradeType.displayName)
                .font(.smallCaption)
                .foregroundColor(transaction.tradeType.tintColor)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(transaction.tradeType.tintColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("价格 \(asset.currencySymbol)\(formatPrice(transaction.price, currency: asset.currency, market: asset.market)) · 数量 \(formatQuantity(transaction.quantity))")
                    .font(.caption)
                    .foregroundColor(.textPrimary)
                Text(dateTimeText(transaction.occurredAt))
                    .font(.smallCaption)
                    .foregroundColor(.textTertiary)
            }
            Spacer()
            Text("¥\(AppNumberFormat.wholeString(transaction.cnyAmount ?? transaction.tradeAmountInOriginalCurrency * asset.fxRateToCNY))")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }

    private var bottomActionBar: some View {
        HStack(spacing: Spacing.md) {
            Button {
                // 模块 5 实现交易逻辑
            } label: {
                Text("买入")
                    .font(.bodyText)
                    .foregroundColor(.profitGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.profitGreen.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .buttonStyle(.plain)

            Button {
                // 模块 5 实现交易逻辑
            } label: {
                Text("卖出")
                    .font(.bodyText)
                    .foregroundColor(.lossRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.lossRed.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.vertical, Spacing.md)
        .background(Color.pageBg)
    }

    private func formatPrice(_ price: Double, currency: String, market: String) -> String {
        AppNumberFormat.priceString(price, currency: currency, market: market)
    }

    private func formatQuantity(_ quantity: Double) -> String {
        AppNumberFormat.quantityString(quantity)
    }

    private func dateTimeText(_ date: Date) -> String {
        AppDateFormat.dateTimeString(date)
    }
}

struct AssetTransactionListView: View {
    let asset: Asset

    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]

    private var assetTransactions: [Transaction] {
        transactions.filter { $0.asset?.id == asset.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                if assetTransactions.isEmpty {
                    Text("暂无交易记录")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(Spacing.xl)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                } else {
                    ForEach(assetTransactions) { transaction in
                        HStack(spacing: Spacing.md) {
                            Text(transaction.tradeType.displayName)
                                .font(.smallCaption)
                                .foregroundColor(transaction.tradeType.tintColor)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(transaction.tradeType.tintColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("\(asset.currencySymbol)\(AppNumberFormat.twoDigitString(transaction.price)) × \(AppNumberFormat.twoDigitString(transaction.quantity))")
                                    .font(.caption)
                                    .foregroundColor(.textPrimary)
                                Text(dateText(transaction.occurredAt))
                                    .font(.smallCaption)
                                    .foregroundColor(.textTertiary)
                            }
                            Spacer()
                            Text("¥\(AppNumberFormat.wholeString(transaction.cnyAmount ?? 0))")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(Spacing.cardPadding)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.pageBg)
        .navigationTitle("全部交易记录")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dateText(_ date: Date) -> String {
        AppDateFormat.dateTimeString(date)
    }
}

struct ValuationScaleView: View {
    let level: ValuationLevel

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(ValuationLevel.allCases, id: \.self) { item in
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(item.color.opacity(item == level ? 1 : 0.35))
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.sm)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AssetDetailView(
            asset: Asset(
                name: "腾讯控股",
                symbol: "00700",
                market: MarketCode.hk.rawValue,
                currency: "HKD",
                idealBuyPrice: 290,
                idealSellPrice: 470,
                currentPrice: 362,
                holdingQuantity: 500,
                averageCost: 338,
                targetPositionRatio: 25,
                maxPositionRatio: 35
            ),
            totalPortfolioValueCNY: 1_300_000
        )
    }
    .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
