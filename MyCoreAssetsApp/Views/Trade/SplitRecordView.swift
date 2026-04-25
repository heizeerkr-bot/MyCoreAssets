import SwiftData
import SwiftUI

/// 拆股录入：持仓数量 ×= ratio，平均成本 /= ratio，现金不变。
struct SplitRecordView: View {
    let asset: Asset
    var prefill: DividendEvent?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var ratioText = ""
    @State private var occurredAt = Date.now
    @State private var errorMessage: String?

    private var ratio: Double {
        Double(ratioText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var newQuantity: Double {
        asset.holdingQuantity * ratio
    }

    private var newAvgCost: Double {
        guard ratio > 0 else { return asset.averageCost }
        return asset.averageCost / ratio
    }

    private var canSubmit: Bool {
        ratio > 0 && asset.holdingQuantity > 0
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
            .navigationTitle("拆股 \(asset.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(.themePrimary)
                }
            }
            .onAppear {
                if let prefill {
                    ratioText = AppNumberFormat.twoDigitString(prefill.splitRatio)
                    occurredAt = prefill.exDate
                }
            }
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("拆股信息")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("拆股比率（如 1股拆2股填 2）")
                    .font(.smallCaption)
                    .foregroundColor(.textSecondary)
                TextField("", text: $ratioText)
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

            Text("现金不变；持仓总市值不变（数量×成本守恒）。")
                .font(.smallCaption)
                .foregroundColor(.textTertiary)
        }
        .padding(Spacing.cardPadding)
        .background(Color.splitBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private var submitButton: some View {
        Button {
            errorMessage = nil
            executeRecord()
        } label: {
            Text("确认记录")
                .font(.bodyText)
                .foregroundColor(.cardBg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(canSubmit ? Color.splitBlue : Color.textTertiary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func executeRecord() {
        guard canSubmit else { return }
        let oldQ = asset.holdingQuantity
        let newQ = oldQ * ratio
        let oldCost = asset.averageCost

        let trade = Transaction(
            asset: asset,
            type: TradeType.split.rawValue,
            price: ratio,
            quantity: newQ - oldQ,
            occurredAt: occurredAt,
            fxRateUsed: nil,
            cnyAmount: 0
        )

        asset.holdingQuantity = newQ
        asset.averageCost = oldCost / ratio

        modelContext.insert(trade)
        do { try modelContext.save() } catch { print("Split save failed: \(error)") }
        dismiss()
    }
}

#Preview {
    SplitRecordView(
        asset: Asset(
            name: "苹果 Apple", symbol: "AAPL",
            market: MarketCode.us.rawValue, currency: "USD",
            currentPrice: 50, holdingQuantity: 25, averageCost: 200
        ),
        prefill: nil
    )
    .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
