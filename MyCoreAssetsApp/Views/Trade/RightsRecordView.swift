import SwiftData
import SwiftUI

/// 配股录入：付钱多得股票（A 股 "10配2 @ 价格"）。
/// 数量 += newQ；现金 -= price × newQ × fxRate；
/// 平均成本 = (旧成本 × 旧数量 + 配股价 × 配股数) / 总数量
struct RightsRecordView: View {
    let asset: Asset

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]

    @State private var priceText = ""
    @State private var perTenText = ""   // "每10股配 X"
    @State private var occurredAt = Date.now
    @State private var errorMessage: String?

    private var portfolio: Portfolio? { portfolios.first }
    private var fxRate: Double { CurrencyConverter.fxRateToCNY(currency: asset.currency) }

    private var rightsPrice: Double {
        Double(priceText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
    private var rightsRatio: Double {
        let v = Double(perTenText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return v / 10
    }
    private var rightsShares: Double { asset.holdingQuantity * rightsRatio }
    private var newQuantity: Double { asset.holdingQuantity + rightsShares }
    private var cashOut: Double { rightsPrice * rightsShares }
    private var cashOutCNY: Double { cashOut * fxRate }

    private var newAvgCost: Double {
        guard newQuantity > 0 else { return asset.averageCost }
        return (asset.averageCost * asset.holdingQuantity + rightsPrice * rightsShares) / newQuantity
    }

    private var hasEnoughCash: Bool {
        (portfolio?.currentCashCNY ?? 0) >= cashOutCNY
    }

    private var canSubmit: Bool {
        portfolio != nil && rightsPrice > 0 && rightsRatio > 0 && asset.holdingQuantity > 0 && hasEnoughCash
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
                    }
                    submitButton
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.vertical, Spacing.md)
            }
            .background(Color.pageBg)
            .navigationTitle("配股 \(asset.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(.themePrimary)
                }
            }
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("配股信息")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("配股价(\(asset.currency))")
                    .font(.smallCaption)
                    .foregroundColor(.textSecondary)
                TextField("", text: $priceText)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.pageBg)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("每 10 股配 X 股，填 X")
                    .font(.smallCaption)
                    .foregroundColor(.textSecondary)
                TextField("例：10配2 填 2", text: $perTenText)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.pageBg)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            DatePicker("缴款日", selection: $occurredAt, displayedComponents: [.date])
                .font(.bodyText)
                .foregroundColor(.textPrimary)
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("应用预览")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            HStack {
                Text("配股数")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("+\(AppNumberFormat.quantityString(rightsShares))")
                    .font(.bodyText)
                    .foregroundColor(.rightsTeal)
            }
            HStack {
                Text("现金支出")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("-\(asset.currencySymbol)\(AppNumberFormat.twoDigitString(cashOut)) ≈ -¥\(AppNumberFormat.wholeString(cashOutCNY))")
                    .font(.bodyText)
                    .foregroundColor(.lossRed)
            }
            HStack {
                Text("持仓数量")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(AppNumberFormat.quantityString(asset.holdingQuantity)) → \(AppNumberFormat.quantityString(newQuantity))")
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
            }
            HStack {
                Text("平均成本")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(asset.currencySymbol)\(AppNumberFormat.twoDigitString(asset.averageCost)) → \(asset.currencySymbol)\(AppNumberFormat.twoDigitString(newAvgCost))")
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
            }

            if rightsRatio > 0 && rightsPrice > 0 && !hasEnoughCash {
                Text("现金不足，无法完成配股缴款。")
                    .font(.caption)
                    .foregroundColor(.valuationRed)
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.rightsTeal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private var submitButton: some View {
        Button {
            executeRecord()
        } label: {
            Text("确认记录")
                .font(.bodyText)
                .foregroundColor(.cardBg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(canSubmit ? Color.rightsTeal : Color.textTertiary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func executeRecord() {
        guard canSubmit, let portfolio else {
            errorMessage = "请检查配股价/比率/现金。"
            return
        }
        let oldQ = asset.holdingQuantity
        let newShares = rightsShares
        let totalCash = cashOut * fxRate

        let trade = Transaction(
            asset: asset,
            type: TradeType.rightsIssue.rawValue,
            price: rightsPrice,
            quantity: newShares,
            occurredAt: occurredAt,
            fxRateUsed: fxRate,
            cnyAmount: -totalCash   // 负数表示流出
        )

        asset.averageCost = (asset.averageCost * oldQ + rightsPrice * newShares) / (oldQ + newShares)
        asset.holdingQuantity = oldQ + newShares
        portfolio.currentCashCNY -= totalCash

        modelContext.insert(trade)
        do { try modelContext.save() } catch { print("Rights save failed: \(error)") }
        dismiss()
    }
}

#Preview {
    RightsRecordView(
        asset: Asset(
            name: "贵州茅台", symbol: "600519",
            market: MarketCode.cn.rawValue, currency: "CNY",
            currentPrice: 1500, holdingQuantity: 100, averageCost: 1500
        )
    )
    .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
