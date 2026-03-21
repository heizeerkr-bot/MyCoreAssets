import SwiftData
import SwiftUI

struct AssetEditView: View {
    @Bindable var asset: Asset
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var idealBuyPriceText = ""
    @State private var idealSellPriceText = ""
    @State private var targetPositionText = ""
    @State private var maxPositionText = ""
    @State private var notesText = ""
    @State private var showingSavedToast = false

    var body: some View {
        Form {
            Section("基本信息") {
                readonlyRow(title: "名称", value: asset.name)
                readonlyRow(title: "代码", value: asset.symbol)
                readonlyRow(title: "市场", value: asset.marketDisplayName)
            }
            .listRowBackground(Color.cardBg)

            Section("估值设置") {
                editableNumberField(title: "理想买入价", text: $idealBuyPriceText) { value in
                    asset.idealBuyPrice = value
                }
                editableNumberField(title: "理想卖出价", text: $idealSellPriceText) { value in
                    asset.idealSellPrice = value
                }
            }
            .listRowBackground(Color.cardBg)

            Section("仓位设置") {
                editableNumberField(title: "目标仓位(%)", text: $targetPositionText) { value in
                    asset.targetPositionRatio = value
                }
                editableOptionalNumberField(title: "仓位上限(%)", text: $maxPositionText) { value in
                    asset.maxPositionRatio = value
                }
            }
            .listRowBackground(Color.cardBg)

            Section("备注") {
                TextEditor(text: $notesText)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
                    .frame(minHeight: Spacing.xl * 3)
                    .scrollContentBackground(.hidden)
                    .background(Color.cardBg)
                    .onChange(of: notesText) { _, newValue in
                        asset.notes = newValue.isEmpty ? nil : newValue
                    }
            }
            .listRowBackground(Color.cardBg)
        }
        .scrollContentBackground(.hidden)
        .background(Color.pageBg)
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    try? modelContext.save()
                    showingSavedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                } label: {
                    Text("完成")
                        .font(.bodyText)
                        .foregroundColor(.themePrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            if showingSavedToast {
                Text("已保存")
                    .font(.caption)
                    .foregroundColor(.cardBg)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.textPrimary.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .padding(.bottom, Spacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingSavedToast)
        .onAppear {
            idealBuyPriceText = textValue(for: asset.idealBuyPrice)
            idealSellPriceText = textValue(for: asset.idealSellPrice)
            targetPositionText = textValue(for: asset.targetPositionRatio)
            maxPositionText = asset.maxPositionRatio.map(textValue(for:)) ?? ""
            notesText = asset.notes ?? ""
        }
    }

    private func readonlyRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.bodyText)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.bodyText)
                .foregroundColor(.textPrimary)
        }
    }

    private func editableNumberField(
        title: String,
        text: Binding<String>,
        onUpdate: @escaping (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.smallCaption)
                .foregroundColor(.textSecondary)
            TextField("", text: text)
                .font(.bodyText)
                .foregroundColor(.textPrimary)
                .keyboardType(.decimalPad)
                .onChange(of: text.wrappedValue) { _, newValue in
                    if let number = parseNumber(newValue) {
                        onUpdate(number)
                    }
                }
        }
    }

    private func editableOptionalNumberField(
        title: String,
        text: Binding<String>,
        onUpdate: @escaping (Double?) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.smallCaption)
                .foregroundColor(.textSecondary)
            TextField("", text: text)
                .font(.bodyText)
                .foregroundColor(.textPrimary)
                .keyboardType(.decimalPad)
                .onChange(of: text.wrappedValue) { _, newValue in
                    if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onUpdate(nil)
                    } else if let number = parseNumber(newValue) {
                        onUpdate(number)
                    }
                }
        }
    }

    private func parseNumber(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned)
    }

    private func textValue(for value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

#Preview {
    NavigationStack {
        AssetEditView(
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
    }
    .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
