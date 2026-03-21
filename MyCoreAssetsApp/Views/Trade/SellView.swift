import SwiftData
import SwiftUI

struct SellView: View {
    let asset: Asset

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]
    @Query(sort: \Asset.sortOrder) private var assets: [Asset]

    @State private var priceText = ""
    @State private var quantityText = ""
    @State private var occurredAt = Date.now
    @State private var showingOverLimitConfirm = false
    @State private var errorMessage: String?

    private var portfolio: Portfolio? {
        portfolios.first
    }

    private var tradePrice: Double {
        parseNumber(priceText) ?? 0
    }

    private var quantity: Double {
        parseNumber(quantityText) ?? 0
    }

    private var fxRate: Double {
        CurrencyConverter.fxRateToCNY(currency: asset.currency)
    }

    private var tradeAmountCNY: Double {
        tradePrice * quantity * fxRate
    }

    private var totalPortfolioValue: Double {
        assets.reduce(0) { $0 + $1.currentValueCNY } + (portfolio?.currentCashCNY ?? 0)
    }

    private var currentAssetValue: Double {
        asset.currentValueCNY
    }

    private var otherAssetValue: Double {
        totalPortfolioValue - (portfolio?.currentCashCNY ?? 0) - currentAssetValue
    }

    private var projectedQuantity: Double {
        asset.holdingQuantity - quantity
    }

    private var projectedCashCNY: Double {
        (portfolio?.currentCashCNY ?? 0) + tradeAmountCNY
    }

    private var projectedAssetValueCNY: Double {
        asset.currentPrice * Swift.max(projectedQuantity, 0) * fxRate
    }

    private var projectedTotalValueCNY: Double {
        projectedCashCNY + projectedAssetValueCNY + otherAssetValue
    }

    private var currentPosition: Double {
        asset.currentPositionRatio(totalPortfolioCNY: totalPortfolioValue)
    }

    private var projectedPosition: Double {
        guard projectedTotalValueCNY > 0 else { return 0 }
        return projectedAssetValueCNY / projectedTotalValueCNY * 100
    }

    private var exceedsMaxPosition: Bool {
        guard let maxPosition = asset.maxPositionRatio else { return false }
        return projectedPosition > maxPosition
    }

    private var hasEnoughHolding: Bool {
        quantity <= asset.holdingQuantity
    }

    private var canSubmit: Bool {
        portfolio != nil && tradePrice > 0 && quantity > 0 && hasEnoughHolding
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    inputCard
                    previewCard
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.valuationRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.sm)
                    }
                    submitButton
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.vertical, Spacing.md)
            }
            .background(Color.pageBg)
            .navigationTitle("卖出 \(asset.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                        .font(.bodyText)
                        .foregroundColor(.themePrimary)
                }
            }
            .onAppear {
                if priceText.isEmpty {
                    priceText = AppNumberFormat.twoDigitString(asset.currentPrice)
                }
            }
            .confirmationDialog("卖出后仓位仍超过上限，是否继续？", isPresented: $showingOverLimitConfirm) {
                Button("继续卖出", role: .destructive) {
                    executeSell()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("交易信息")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            tradeField(title: "卖出价格(\(asset.currency))", text: $priceText)
            tradeField(title: "卖出数量", text: $quantityText)

            HStack {
                Text("当前可卖数量")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text(AppNumberFormat.quantityString(asset.holdingQuantity))
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
            }

            DatePicker("交易时间", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                .font(.bodyText)
                .foregroundColor(.textPrimary)

            HStack {
                Text("预计增加现金")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("¥\(AppNumberFormat.wholeString(tradeAmountCNY))")
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("仓位变化预估")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            HStack {
                previewItem(title: "当前仓位", value: "\(String(format: "%.1f", currentPosition))%")
                Spacer()
                previewItem(title: "卖出后仓位", value: "\(String(format: "%.1f", projectedPosition))%")
            }

            PositionBar(
                current: projectedPosition,
                target: asset.targetPositionRatio,
                max: asset.maxPositionRatio
            )

            if exceedsMaxPosition {
                Text("警告：卖出后仓位仍高于上限")
                    .font(.caption)
                    .foregroundColor(.valuationRed)
            }

            if !hasEnoughHolding && quantity > 0 {
                Text("卖出数量超过当前持仓")
                    .font(.caption)
                    .foregroundColor(.valuationRed)
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private var submitButton: some View {
        Button {
            errorMessage = nil
            if exceedsMaxPosition {
                showingOverLimitConfirm = true
            } else {
                executeSell()
            }
        } label: {
            Text("确认卖出")
                .font(.bodyText)
                .foregroundColor(.cardBg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(canSubmit ? Color.lossRed : Color.textTertiary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func tradeField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.smallCaption)
                .foregroundColor(.textSecondary)
            TextField("", text: text)
                .font(.bodyText)
                .foregroundColor(.textPrimary)
                .keyboardType(.decimalPad)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.pageBg)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
    }

    private func previewItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.smallCaption)
                .foregroundColor(.textTertiary)
            Text(value)
                .font(.positionPercent)
                .foregroundColor(.themePrimary)
        }
    }

    private func executeSell() {
        guard canSubmit, let portfolio else {
            errorMessage = "输入有误，请检查后重试。"
            return
        }

        let newQuantity = asset.holdingQuantity - quantity
        let trade = Transaction(
            asset: asset,
            type: TradeType.sell.rawValue,
            price: tradePrice,
            quantity: quantity,
            occurredAt: occurredAt,
            fxRateUsed: fxRate,
            cnyAmount: tradeAmountCNY
        )

        asset.holdingQuantity = Swift.max(newQuantity, 0)
        portfolio.currentCashCNY += tradeAmountCNY

        modelContext.insert(trade)
        do {
            try modelContext.save()
        } catch {
            print("Sell save failed: \(error)")
        }
        dismiss()
    }

    private func parseNumber(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned)
    }
}

#Preview {
    SellView(
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
        )
    )
    .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
