import SwiftData
import SwiftUI

/// 送股录入：免费多得股票（A 股 "10送2" 类）。
/// 数量 += oldQ × ratio，平均成本按总市值守恒摊薄。现金不变。
struct BonusShareRecordView: View {
    let asset: Asset

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var ratioText = ""
    @State private var occurredAt = Date.now
    @State private var errorMessage: String?

    /// 用户输入"每 10 股送 X 股"中的 X，转成小数 ratio = X / 10
    private var perTenText: Binding<String> { $ratioText }

    private var bonusRatio: Double {
        let v = Double(ratioText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return v / 10
    }

    private var bonusShares: Double { asset.holdingQuantity * bonusRatio }
    private var newQuantity: Double { asset.holdingQuantity + bonusShares }
    private var newAvgCost: Double {
        guard newQuantity > 0 else { return asset.averageCost }
        return asset.averageCost * asset.holdingQuantity / newQuantity
    }

    private var canSubmit: Bool {
        bonusRatio > 0 && asset.holdingQuantity > 0
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
            .navigationTitle("送股 \(asset.name)")
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
            Text("送股信息")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("每 10 股送 X 股，填 X")
                    .font(.smallCaption)
                    .foregroundColor(.textSecondary)
                TextField("例：10送2 填 2", text: perTenText)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.pageBg)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            DatePicker("除权日", selection: $occurredAt, displayedComponents: [.date])
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
                Text("送出股数")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("+\(AppNumberFormat.quantityString(bonusShares))")
                    .font(.bodyText)
                    .foregroundColor(.bonusPurple)
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
            Text("现金不变；持仓总市值不变。")
                .font(.smallCaption)
                .foregroundColor(.textTertiary)
        }
        .padding(Spacing.cardPadding)
        .background(Color.bonusPurple.opacity(0.08))
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
                .background(canSubmit ? Color.bonusPurple : Color.textTertiary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func executeRecord() {
        guard canSubmit else {
            errorMessage = "需先有持仓，再填送股比率。"
            return
        }
        let oldQ = asset.holdingQuantity
        let bonus = bonusShares
        let newQ = oldQ + bonus

        let trade = Transaction(
            asset: asset,
            type: TradeType.bonusShare.rawValue,
            price: bonusRatio,
            quantity: bonus,
            occurredAt: occurredAt,
            fxRateUsed: nil,
            cnyAmount: 0
        )

        asset.holdingQuantity = newQ
        asset.averageCost = asset.averageCost * oldQ / newQ

        modelContext.insert(trade)
        do { try modelContext.save() } catch { print("Bonus save failed: \(error)") }
        dismiss()
    }
}

#Preview {
    BonusShareRecordView(
        asset: Asset(
            name: "贵州茅台", symbol: "600519",
            market: MarketCode.cn.rawValue, currency: "CNY",
            currentPrice: 1500, holdingQuantity: 100, averageCost: 1500
        )
    )
    .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
