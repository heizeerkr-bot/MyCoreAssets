import SwiftData
import SwiftUI

/// 现金分红录入：摄薄成本 + 现金入账。
/// 同时作为"自动检测候选"的确认 sheet — 通过 prefill 参数预填值。
struct DividendRecordView: View {
    let asset: Asset
    /// 候选项预填（来自 DividendDetector）；nil 表示用户从"更多"菜单手动录入
    var prefill: DividendEvent?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]

    @State private var perShareText = ""
    @State private var occurredAt = Date.now
    @State private var errorMessage: String?

    private var portfolio: Portfolio? { portfolios.first }
    private var fxRate: Double { CurrencyConverter.fxRateToCNY(currency: asset.currency) }

    private var perShare: Double {
        Double(perShareText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var totalCash: Double {
        perShare * asset.holdingQuantity
    }

    private var totalCashCNY: Double {
        totalCash * fxRate
    }

    private var newAvgCost: Double {
        Swift.max(asset.averageCost - perShare, 0)
    }

    private var canSubmit: Bool {
        portfolio != nil && perShare > 0 && asset.holdingQuantity > 0
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
            .navigationTitle("分红 \(asset.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                        .font(.bodyText)
                        .foregroundColor(.themePrimary)
                }
            }
            .onAppear {
                if let prefill {
                    perShareText = AppNumberFormat.twoDigitString(prefill.amountPerShare)
                    occurredAt = prefill.exDate
                }
            }
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("分红信息")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("每股股息(\(asset.currency))")
                    .font(.smallCaption)
                    .foregroundColor(.textSecondary)
                TextField("", text: $perShareText)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.pageBg)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            DatePicker("除权除息日", selection: $occurredAt, displayedComponents: [.date])
                .font(.bodyText)
                .foregroundColor(.textPrimary)

            HStack {
                Text("除息日持仓数")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text(AppNumberFormat.quantityString(asset.holdingQuantity))
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
            Text("入账预览")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            HStack {
                Text("到账现金")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(asset.currencySymbol)\(AppNumberFormat.twoDigitString(totalCash)) ≈ ¥\(AppNumberFormat.wholeString(totalCashCNY))")
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
            }

            HStack {
                Text("平均成本（摄薄）")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(asset.currencySymbol)\(AppNumberFormat.twoDigitString(asset.averageCost)) → \(asset.currencySymbol)\(AppNumberFormat.twoDigitString(newAvgCost))")
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
            }

            Text("应用后：现金 += \(asset.currencySymbol)\(AppNumberFormat.twoDigitString(totalCash))；平均成本 -= \(asset.currencySymbol)\(AppNumberFormat.twoDigitString(perShare))")
                .font(.smallCaption)
                .foregroundColor(.textTertiary)
        }
        .padding(Spacing.cardPadding)
        .background(Color.dividendGold.opacity(0.08))
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
                .background(canSubmit ? Color.dividendGold : Color.textTertiary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func executeRecord() {
        guard canSubmit, let portfolio else {
            errorMessage = "需先有持仓数量大于 0 才能记录分红。"
            return
        }

        let trade = Transaction(
            asset: asset,
            type: TradeType.dividend.rawValue,
            price: perShare,
            quantity: asset.holdingQuantity,
            occurredAt: occurredAt,
            fxRateUsed: fxRate,
            cnyAmount: totalCashCNY
        )

        asset.averageCost = Swift.max(asset.averageCost - perShare, 0)
        portfolio.currentCashCNY += totalCashCNY

        modelContext.insert(trade)
        do { try modelContext.save() } catch { print("Dividend save failed: \(error)") }
        dismiss()
    }
}

#Preview {
    DividendRecordView(
        asset: Asset(
            name: "苹果 Apple", symbol: "AAPL",
            market: MarketCode.us.rawValue, currency: "USD",
            currentPrice: 250, holdingQuantity: 100, averageCost: 180
        ),
        prefill: nil
    )
    .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
