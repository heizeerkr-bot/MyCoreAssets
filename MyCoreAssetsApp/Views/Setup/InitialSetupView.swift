import SwiftData
import SwiftUI

struct SetupAssetDraft: Identifiable {
    let id: String
    var name: String
    var symbol: String
    var market: String
    var currency: String
    var idealBuyPrice: String
    var idealSellPrice: String
    var targetPositionRatio: String
    var maxPositionRatio: String
    var holdingQuantity: String
    var averageCost: String
    var sortOrder: Int
}

struct InitialSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Asset.sortOrder) private var existingAssets: [Asset]

    let portfolio: Portfolio
    var onCompleted: (() -> Void)? = nil

    @State private var stepIndex = 0
    @State private var initialCashText = "1,250,000"
    @State private var selectedAssetIDs: Set<String> = []
    @State private var setupDrafts: [SetupAssetDraft] = []
    @State private var showingAssetSearch = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let stepTitles = [
        "1. 设置初始资金",
        "2. 添加核心资产",
        "3. 设置估值与仓位（可跳过）",
        "4. 初始化持仓（可跳过）",
    ]

    private var selectedAssets: [PresetAsset] {
        PresetAssets.searchPool.filter { selectedAssetIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                stepHeader
                stepContent
                bottomActionBar
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.vertical, Spacing.md)
            .background(Color.pageBg)
            .navigationTitle("初始化向导")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAssetSearch) {
                AssetSearchView(selectedAssetIDs: $selectedAssetIDs)
            }
            .onChange(of: selectedAssetIDs) { _, _ in
                syncDraftsWithSelection()
            }
        }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                ForEach(stepTitles.indices, id: \.self) { idx in
                    Circle()
                        .fill(idx <= stepIndex ? Color.themePrimary : Color.divider)
                        .frame(width: Spacing.md, height: Spacing.md)
                }
                Spacer()
                Text("\(stepIndex + 1)/\(stepTitles.count)")
                    .font(.smallCaption)
                    .foregroundColor(.textSecondary)
            }

            Text(stepTitles[stepIndex])
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.valuationRed)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch stepIndex {
        case 0:
            stepOneInitialCash
        case 1:
            stepTwoSelectAssets
        case 2:
            stepThreeValuationAndPosition
        default:
            stepFourInitialHoldings
        }
    }

    private var stepOneInitialCash: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("总资金（人民币）")
                .font(.caption)
                .foregroundColor(.textSecondary)

            TextField("输入金额", text: $initialCashText)
                .font(.superLargeTitle)
                .foregroundColor(.textPrimary)
                .keyboardType(.decimalPad)
                .padding(Spacing.cardPadding)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)

            Text("默认值：1,250,000")
                .font(.smallCaption)
                .foregroundColor(.textTertiary)

            Spacer()
        }
    }

    private var stepTwoSelectAssets: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("已选 \(selectedAssetIDs.count) 个资产")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Button {
                    showingAssetSearch = true
                } label: {
                    Text("搜索添加")
                        .font(.caption)
                        .foregroundColor(.themePrimary)
                }
                .buttonStyle(.plain)
            }

            Text("常关注 15 个")
                .font(.caption)
                .foregroundColor(.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(PresetAssets.watched15) { asset in
                    quickAssetTag(asset: asset)
                }
            }

            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(selectedAssets) { asset in
                        selectedRow(asset: asset)
                    }
                }
                .padding(.bottom, Spacing.md)
            }
        }
    }

    private func quickAssetTag(asset: PresetAsset) -> some View {
        let isSelected = selectedAssetIDs.contains(asset.id)
        return Button {
            toggleAssetSelection(asset)
        } label: {
            HStack {
                Text(asset.name)
                    .font(.smallCaption)
                    .foregroundColor(isSelected ? .themePrimary : .textBody)
                    .lineLimit(1)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.caption)
                    .foregroundColor(isSelected ? .themePrimary : .textTertiary)
            }
            .padding(Spacing.sm)
            .background(isSelected ? Color.themeLight : Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    private func selectedRow(asset: PresetAsset) -> some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(asset.name)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
                Text("\(asset.symbol) · \(MarketCode(rawValue: asset.market)?.displayName ?? asset.market)")
                    .font(.smallCaption)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Button {
                toggleAssetSelection(asset)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private var totalTargetRatio: Double {
        setupDrafts.compactMap { parseNumber($0.targetPositionRatio) }.reduce(0, +)
    }

    private var stepThreeValuationAndPosition: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("尚不确定理想买卖价或目标仓位？可整步跳过，之后在资产详情里随时填写。")
                        .font(.caption)
                }
                .foregroundColor(.themePrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.cardPadding)
                .background(Color.themeLight)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                if totalTargetRatio > 100 {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("目标仓位合计 \(String(format: "%.0f", totalTargetRatio))%，超过 100%，请检查")
                            .font(.caption)
                    }
                    .foregroundColor(.valuationOrange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.cardPadding)
                    .background(Color.valuationOrange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }

                ForEach($setupDrafts) { $draft in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("\(draft.name) · \(draft.symbol)")
                            .font(.bodyText)
                            .foregroundColor(.textPrimary)

                        setupTextField(title: "理想买入价", text: $draft.idealBuyPrice)
                        setupTextField(title: "理想卖出价", text: $draft.idealSellPrice)
                        setupTextField(title: "目标仓位(%)", text: $draft.targetPositionRatio)
                        setupTextField(title: "仓位上限(%) 可选", text: $draft.maxPositionRatio)
                    }
                    .padding(Spacing.cardPadding)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
                }
            }
            .padding(.bottom, Spacing.md)
        }
    }

    private var stepFourInitialHoldings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("可直接跳过，后续也可在资产详情继续录入。")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                ForEach($setupDrafts) { $draft in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("\(draft.name) · \(draft.symbol)")
                            .font(.bodyText)
                            .foregroundColor(.textPrimary)

                        setupTextField(title: "持有数量", text: $draft.holdingQuantity)
                        setupTextField(title: "平均成本", text: $draft.averageCost)
                    }
                    .padding(Spacing.cardPadding)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
                }
            }
            .padding(.bottom, Spacing.md)
        }
    }

    private var bottomActionBar: some View {
        HStack(spacing: Spacing.md) {
            Button {
                if stepIndex > 0 {
                    stepIndex -= 1
                }
            } label: {
                Text("上一步")
                    .font(.bodyText)
                    .foregroundColor(stepIndex > 0 ? .themePrimary : .textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .buttonStyle(.plain)
            .disabled(stepIndex == 0)

            Button {
                goNextStep()
            } label: {
                Text(primaryButtonTitle)
                    .font(.bodyText)
                    .foregroundColor(.cardBg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(canProceedCurrentStep && !isSaving ? Color.themePrimary : Color.textTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .buttonStyle(.plain)
            .disabled(!canProceedCurrentStep || isSaving)
        }
    }

    private func setupTextField(title: String, text: Binding<String>) -> some View {
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

    private var primaryButtonTitle: String {
        if stepIndex == stepTitles.count - 1 { return "完成初始化" }
        if stepIndex == 1 && selectedAssetIDs.isEmpty { return "完成初始化" }
        return "下一步"
    }

    private var canProceedCurrentStep: Bool {
        switch stepIndex {
        case 0:
            return (parseNumber(initialCashText) ?? 0) > 0
        case 1:
            return true
        case 2:
            // V1.1: 估值与仓位整步可跳过，所有字段非必填，但已填写的需自洽（卖出 > 买入）
            return setupDrafts.allSatisfy { draft in
                let buy = parseNumber(draft.idealBuyPrice) ?? 0
                let sell = parseNumber(draft.idealSellPrice) ?? 0
                if buy > 0 && sell > 0 { return sell > buy }
                return true
            }
        default:
            return true
        }
    }

    private func toggleAssetSelection(_ asset: PresetAsset) {
        if selectedAssetIDs.contains(asset.id) {
            selectedAssetIDs.remove(asset.id)
        } else {
            selectedAssetIDs.insert(asset.id)
        }
    }

    private func syncDraftsWithSelection() {
        let oldMap = Dictionary(uniqueKeysWithValues: setupDrafts.map { ($0.id, $0) })
        var newDrafts: [SetupAssetDraft] = []
        for (index, asset) in selectedAssets.enumerated() {
            if var old = oldMap[asset.id] {
                old.sortOrder = index
                newDrafts.append(old)
            } else {
                newDrafts.append(
                    SetupAssetDraft(
                        id: asset.id,
                        name: asset.name,
                        symbol: asset.symbol,
                        market: asset.market,
                        currency: asset.currency,
                        idealBuyPrice: "",
                        idealSellPrice: "",
                        targetPositionRatio: "",
                        maxPositionRatio: "",
                        holdingQuantity: "",
                        averageCost: "",
                        sortOrder: index
                    )
                )
            }
        }
        setupDrafts = newDrafts
    }

    private func goNextStep() {
        errorMessage = nil
        // step 2 选了 0 个资产时，后两步（per-asset 估值/持仓）无意义，直接完成初始化
        if stepIndex == 1 && selectedAssetIDs.isEmpty {
            persistSetup()
            return
        }
        if stepIndex < stepTitles.count - 1 {
            if stepIndex == 1 {
                syncDraftsWithSelection()
            }
            stepIndex += 1
            return
        }
        persistSetup()
    }

    private func persistSetup() {
        isSaving = true
        defer { isSaving = false }

        let initialCash = parseNumber(initialCashText) ?? 1_250_000
        portfolio.initialCashCNY = initialCash
        portfolio.currentCashCNY = initialCash
        portfolio.lastGlobalRefreshAt = .now

        for asset in existingAssets {
            modelContext.delete(asset)
        }

        var initializedCashCost = 0.0
        for (index, draft) in setupDrafts.enumerated() {
            let idealBuy = parseNumber(draft.idealBuyPrice) ?? 0
            let idealSell = parseNumber(draft.idealSellPrice) ?? 0
            let targetRatio = parseNumber(draft.targetPositionRatio) ?? 0
            let maxRatio = parseNumber(draft.maxPositionRatio)
            let quantity = parseNumber(draft.holdingQuantity) ?? 0
            let avgCost = parseNumber(draft.averageCost) ?? 0
            let initialPrice = idealBuy > 0 ? idealBuy : avgCost

            let newAsset = Asset(
                name: draft.name,
                symbol: draft.symbol,
                market: draft.market,
                currency: draft.currency,
                idealBuyPrice: idealBuy,
                idealSellPrice: idealSell,
                currentPrice: initialPrice,
                lastPriceUpdatedAt: .now,
                holdingQuantity: quantity,
                averageCost: avgCost,
                targetPositionRatio: targetRatio,
                maxPositionRatio: maxRatio,
                isWatched: true,
                notes: nil,
                sortOrder: index
            )
            modelContext.insert(newAsset)

            guard quantity > 0 else { continue }
            let transactionPrice = avgCost > 0 ? avgCost : initialPrice
            let fxRate = CurrencyConverter.fxRateToCNY(currency: draft.currency)
            let cnyAmount = transactionPrice * quantity * fxRate
            initializedCashCost += cnyAmount

            let transaction = Transaction(
                asset: newAsset,
                type: TradeType.buy.rawValue,
                price: transactionPrice,
                quantity: quantity,
                occurredAt: .now,
                fxRateUsed: fxRate,
                cnyAmount: cnyAmount
            )
            modelContext.insert(transaction)
        }

        portfolio.currentCashCNY = Swift.max(portfolio.initialCashCNY - initializedCashCost, 0)
        portfolio.hasCompletedSetup = true

        do {
            try modelContext.save()
            onCompleted?()
        } catch {
            errorMessage = "初始化保存失败，请重试。"
        }
    }

    private func parseNumber(_ text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned)
    }
}

#Preview {
    InitialSetupView(portfolio: Portfolio())
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
