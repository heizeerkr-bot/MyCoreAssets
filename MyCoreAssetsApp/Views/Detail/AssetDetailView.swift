import SwiftData
import SwiftUI

struct AssetDetailView: View {
    let asset: Asset
    let totalPortfolioValueCNY: Double

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]
    @State private var showingBuySheet = false
    @State private var showingSellSheet = false
    @State private var showingDividendSheet = false
    @State private var showingSplitSheet = false
    @State private var showingBonusSheet = false
    @State private var showingRightsSheet = false
    @State private var pendingEvents: [DividendEvent] = []
    @State private var dividendDetectTask: Task<Void, Never>?
    @State private var prefillDividend: DividendEvent?
    @State private var prefillSplit: DividendEvent?
    @State private var showingApplyAllConfirm = false

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
                if !asset.hasValuationConfigured || !asset.hasTargetPosition {
                    configGuidanceCard
                }
                priceCard
                if !pendingEvents.isEmpty {
                    pendingEventsCard
                }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AssetEditView(asset: asset)
                } label: {
                    Text("编辑")
                        .font(.bodyText)
                        .foregroundColor(.themePrimary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .sheet(isPresented: $showingBuySheet) {
            BuyView(asset: asset)
        }
        .sheet(isPresented: $showingSellSheet) {
            SellView(asset: asset)
        }
        .sheet(isPresented: $showingDividendSheet, onDismiss: { prefillDividend = nil; refreshPendingEvents() }) {
            DividendRecordView(asset: asset, prefill: prefillDividend)
        }
        .sheet(isPresented: $showingSplitSheet, onDismiss: { prefillSplit = nil; refreshPendingEvents() }) {
            SplitRecordView(asset: asset, prefill: prefillSplit)
        }
        .sheet(isPresented: $showingBonusSheet) {
            BonusShareRecordView(asset: asset)
        }
        .sheet(isPresented: $showingRightsSheet) {
            RightsRecordView(asset: asset)
        }
        .task(id: asset.id) {
            await detectPendingEvents()
        }
        .alert("批量记录确认", isPresented: $showingApplyAllConfirm) {
            Button("确认记录", role: .destructive) {
                applyAllPendingEvents()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(applyAllSummaryText)
        }
    }

    private var configGuidanceCard: some View {
        let guidance: String = {
            switch (asset.hasValuationConfigured, asset.hasTargetPosition) {
            case (false, false): return "设置理想买卖价与目标仓位，开启完整的估值与仓位分析"
            case (false, true):  return "设置理想买卖价，查看估值状态与买卖建议"
            case (true, false):  return "设置目标仓位，查看仓位偏离与调仓提示"
            case (true, true):   return ""
            }
        }()

        return NavigationLink {
            AssetEditView(asset: asset)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.bodyText)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("完善资产信息")
                        .font(.bodyText)
                        .foregroundColor(.textPrimary)
                    Text(guidance)
                        .font(.smallCaption)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .foregroundColor(.themePrimary)
            .padding(Spacing.cardPadding)
            .background(Color.themeLight)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
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
                    Text(asset.hasTargetPosition
                         ? "目标 \(String(format: "%.0f%%", targetPositionPercent))"
                         : "目标 未设置")
                        .font(.smallCaption)
                        .foregroundColor(.textSecondary)
                    if let maxPositionPercent {
                        Text("上限 \(String(format: "%.0f%%", maxPositionPercent))")
                            .font(.smallCaption)
                            .foregroundColor(.textTertiary)
                    }
                }
            }

            LegacyPositionBar(
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
                if asset.hasValuationConfigured {
                    Text(asset.valuationLevel.rawValue)
                        .font(.caption)
                        .foregroundColor(asset.valuationLevel.color)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(asset.valuationLevel.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                } else {
                    Text("未设置")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.divider.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
            }

            if asset.hasValuationConfigured {
                ValuationScaleView(level: asset.valuationLevel)

                HStack {
                    priceItem(title: "理想买入", value: "\(asset.currencySymbol)\(formatPrice(asset.idealBuyPrice, currency: asset.currency, market: asset.market))")
                    Spacer()
                    priceItem(title: "理想卖出", value: "\(asset.currencySymbol)\(formatPrice(asset.idealSellPrice, currency: asset.currency, market: asset.market))")
                }
            } else {
                Text("暂未设置估值区间，可在右上角「编辑」中填写理想买入价和理想卖出价。")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack(spacing: Spacing.sm) {
            Button {
                showingBuySheet = true
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
                showingSellSheet = true
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

            Menu {
                Button {
                    prefillDividend = nil
                    showingDividendSheet = true
                } label: { Label("分红", systemImage: "dollarsign.circle") }
                Button {
                    prefillSplit = nil
                    showingSplitSheet = true
                } label: { Label("拆股", systemImage: "arrow.triangle.branch") }
                Button {
                    showingBonusSheet = true
                } label: { Label("送股", systemImage: "gift") }
                Button {
                    showingRightsSheet = true
                } label: { Label("配股", systemImage: "plus.rectangle.on.rectangle") }
            } label: {
                Text("更多")
                    .font(.bodyText)
                    .foregroundColor(.themePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.themePrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.vertical, Spacing.md)
        .background(Color.pageBg)
    }

    // MARK: - Pending events (auto-detected dividends/splits)

    private var pendingEventsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.bodyText)
                    .foregroundColor(.dividendGold)
                Text("检测到 \(pendingEvents.count) 笔未记录事件")
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button("全部记录") {
                    showingApplyAllConfirm = true
                }
                .font(.caption)
                .foregroundColor(.dividendGold)
            }

            ForEach(pendingEvents.prefix(3)) { event in
                Button {
                    openEvent(event)
                } label: {
                    HStack {
                        Text(eventTitle(event))
                            .font(.caption)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text(eventDetail(event))
                            .font(.smallCaption)
                            .foregroundColor(.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.smallCaption)
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.vertical, Spacing.xs)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider()
            }

            if pendingEvents.count > 3 {
                Text("还有 \(pendingEvents.count - 3) 笔，可点击「全部记录」一键应用")
                    .font(.smallCaption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.dividendGold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.dividendGold.opacity(0.5), lineWidth: 1)
        )
    }

    private func eventTitle(_ event: DividendEvent) -> String {
        switch event.kind {
        case .cashDividend: return "现金分红 \(AppDateFormat.dateOnlyString(event.exDate))"
        case .split:        return "拆股 \(AppDateFormat.dateOnlyString(event.exDate))"
        }
    }

    private func eventDetail(_ event: DividendEvent) -> String {
        switch event.kind {
        case .cashDividend:
            return "每股 \(asset.currencySymbol)\(AppNumberFormat.twoDigitString(event.amountPerShare))"
        case .split:
            return "1 → \(AppNumberFormat.twoDigitString(event.splitRatio))"
        }
    }

    private func openEvent(_ event: DividendEvent) {
        switch event.kind {
        case .cashDividend:
            prefillDividend = event
            showingDividendSheet = true
        case .split:
            prefillSplit = event
            showingSplitSheet = true
        }
    }

    /// 批量记录前的摘要文案（给 confirm alert 显示）。
    /// 模拟按事件顺序应用一遍，得出现金净影响和最终成本。
    private var applyAllSummaryText: String {
        let sorted = pendingEvents.sorted { $0.exDate < $1.exDate }
        var divCount = 0
        var splitCount = 0
        var simulatedCost = asset.averageCost
        var simulatedQty = asset.holdingQuantity
        var cashDeltaCNY: Double = 0
        let fxRate = asset.fxRateToCNY

        for event in sorted {
            switch event.kind {
            case .cashDividend:
                divCount += 1
                cashDeltaCNY += event.amountPerShare * simulatedQty * fxRate
                simulatedCost = Swift.max(simulatedCost - event.amountPerShare, 0)
            case .split:
                splitCount += 1
                guard event.splitRatio > 0 else { continue }
                simulatedQty *= event.splitRatio
                simulatedCost /= event.splitRatio
            }
        }

        var lines: [String] = []
        if divCount > 0 { lines.append("\(divCount) 笔现金分红") }
        if splitCount > 0 { lines.append("\(splitCount) 笔拆股") }
        let typeSummary = lines.isEmpty ? "0 笔事件" : lines.joined(separator: "、")

        return """
        将记录：\(typeSummary)
        现金变化：+¥\(AppNumberFormat.wholeString(cashDeltaCNY))
        平均成本：\(asset.currencySymbol)\(AppNumberFormat.twoDigitString(asset.averageCost)) → \(asset.currencySymbol)\(AppNumberFormat.twoDigitString(simulatedCost))
        持仓数量：\(AppNumberFormat.quantityString(asset.holdingQuantity)) → \(AppNumberFormat.quantityString(simulatedQty))
        """
    }

    private func applyAllPendingEvents() {
        // 按 exDate 升序应用（先发生的先入账，公式独立无冲突）
        let sorted = pendingEvents.sorted { $0.exDate < $1.exDate }
        for event in sorted {
            applyEventDirectly(event)
        }
        pendingEvents = []
        try? modelContext.save()
    }

    private func applyEventDirectly(_ event: DividendEvent) {
        let portfolio = portfolios.first
        switch event.kind {
        case .cashDividend:
            guard asset.holdingQuantity > 0 else { return }
            let perShare = event.amountPerShare
            let fxRate = asset.fxRateToCNY
            let totalCashCNY = perShare * asset.holdingQuantity * fxRate
            let trade = Transaction(
                asset: asset,
                type: TradeType.dividend.rawValue,
                price: perShare,
                quantity: asset.holdingQuantity,
                occurredAt: event.exDate,
                fxRateUsed: fxRate,
                cnyAmount: totalCashCNY
            )
            asset.averageCost = Swift.max(asset.averageCost - perShare, 0)
            portfolio?.currentCashCNY += totalCashCNY
            modelContext.insert(trade)
        case .split:
            let ratio = event.splitRatio
            guard ratio > 0, asset.holdingQuantity > 0 else { return }
            let oldQ = asset.holdingQuantity
            let newQ = oldQ * ratio
            let trade = Transaction(
                asset: asset,
                type: TradeType.split.rawValue,
                price: ratio,
                quantity: newQ - oldQ,
                occurredAt: event.exDate,
                fxRateUsed: nil,
                cnyAmount: 0
            )
            asset.holdingQuantity = newQ
            asset.averageCost = asset.averageCost / ratio
            modelContext.insert(trade)
        }
    }

    @MainActor
    private func detectPendingEvents() async {
        let detector = DividendDetector()
        if let events = await detector.detectUnrecorded(asset: asset) {
            pendingEvents = events
            asset.lastDividendCheckAt = .now
            try? modelContext.save()
        }
    }

    private func refreshPendingEvents() {
        Task { await detectPendingEvents() }
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
