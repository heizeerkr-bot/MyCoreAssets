import Foundation
import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var selectedTab: Int
    @Binding var shouldAutoAddAsset: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Asset.sortOrder) private var assets: [Asset]
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]

    @State private var showingSortSheet = false
    @State private var selectedSortOption: DashboardSortOption = .deviationHighToLow
    @State private var isRefreshing = false
    @State private var refreshMessage: String?
    @State private var refreshTask: Task<Void, Never>?

    private var portfolio: Portfolio? {
        portfolios.first
    }

    private var totalAssetValueCNY: Double {
        assets.reduce(0) { $0 + $1.currentValueCNY }
    }

    private var totalPortfolioValueCNY: Double {
        totalAssetValueCNY + (portfolio?.currentCashCNY ?? 0)
    }

    private var sortedAssets: [Asset] {
        switch selectedSortOption {
        case .positionHighToLow:
            return assets.sorted {
                $0.currentPositionRatio(totalPortfolioCNY: totalPortfolioValueCNY)
                    > $1.currentPositionRatio(totalPortfolioCNY: totalPortfolioValueCNY)
            }
        case .deviationHighToLow:
            return assets.sorted {
                abs($0.currentPositionRatio(totalPortfolioCNY: totalPortfolioValueCNY) - $0.targetPositionRatio)
                    > abs($1.currentPositionRatio(totalPortfolioCNY: totalPortfolioValueCNY) - $1.targetPositionRatio)
            }
        case .undervaluedFirst:
            return assets.sorted {
                if $0.valuationLevel.sortRank == $1.valuationLevel.sortRank {
                    return $0.sortOrder < $1.sortOrder
                }
                return $0.valuationLevel.sortRank < $1.valuationLevel.sortRank
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    PortfolioSummaryCard(
                        totalValue: totalPortfolioValueCNY,
                        initialCash: portfolio?.initialCashCNY ?? 0,
                        totalInvested: totalAssetValueCNY,
                        remainingCash: portfolio?.currentCashCNY ?? 0,
                        lastUpdatedAt: portfolio?.lastGlobalRefreshAt
                    )

                    HStack {
                        Text("核心资产 (\(assets.count))")
                            .font(.sectionTitle)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Button {
                            showingSortSheet = true
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Text("排序")
                                    .font(.caption)
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.smallCaption)
                            }
                            .foregroundColor(.themePrimary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, Spacing.sm)

                    if sortedAssets.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(sortedAssets) { asset in
                            NavigationLink {
                                AssetDetailView(asset: asset, totalPortfolioValueCNY: totalPortfolioValueCNY)
                            } label: {
                                AssetCardView(
                                    asset: asset,
                                    totalPortfolioValueCNY: totalPortfolioValueCNY
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xl)
            }
            .refreshable {
                await MainActor.run {
                    triggerRefresh(source: "pull")
                }
            }
            .background(Color.pageBg)
            .navigationTitle("我的核心资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        triggerRefresh(source: "button")
                    } label: {
                        if isRefreshing {
                            ProgressView()
                                .tint(.themePrimary)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.themePrimary)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isRefreshing)
                }
            }
            .sheet(isPresented: $showingSortSheet) {
                SortSheetView(selectedOption: $selectedSortOption)
                    .presentationDetents([.medium])
            }
            .alert("提示", isPresented: Binding(
                get: { refreshMessage != nil },
                set: { if !$0 { refreshMessage = nil } }
            )) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(refreshMessage ?? "")
            }
            .task(id: selectedTab) {
                guard selectedTab == 0 else { return }
                await MainActor.run {
                    triggerRefresh(source: "auto-initial", showMessage: false)
                }
                while !Task.isCancelled, selectedTab == 0 {
                    try? await Task.sleep(nanoseconds: 10_000_000_000)
                    if Task.isCancelled || selectedTab != 0 { break }
                    await MainActor.run {
                        triggerRefresh(source: "auto-10s", showMessage: false)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.pie")
                .font(.superLargeTitle)
                .foregroundColor(.themePrimary.opacity(0.5))
            Text("还没有核心资产")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)
            Text("添加你想长期关注的核心资产，开始管理")
                .font(.caption)
                .foregroundColor(.textSecondary)
            Button {
                shouldAutoAddAsset = true
                selectedTab = 1
            } label: {
                Text("添加第一个核心资产")
                    .font(.bodyText)
                    .foregroundColor(.cardBg)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.themePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    @MainActor
    private func refreshPrices(showMessage: Bool) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        debugLog("Refresh started")
        defer { isRefreshing = false }

        guard !assets.isEmpty else {
            if showMessage {
                refreshMessage = "暂无资产可刷新。"
            }
            return
        }

        let prices: [UUID: Double]
        do {
            prices = try await RealPriceService().fetchPrices(for: assets)
        } catch {
            if isCancelledError(error) {
                debugLog("Refresh cancelled: \(error)")
                if showMessage {
                    refreshMessage = "刷新被取消，请重试"
                }
                return
            }
            do {
                prices = try await MockPriceService().fetchPrices(for: assets)
                if showMessage {
                    refreshMessage = "真实行情获取失败，已使用模拟价格。"
                }
                debugLog("Real price failed, fallback to mock")
            } catch {
                debugLog("Mock fallback failed: \(error)")
                if showMessage {
                    refreshMessage = "刷新失败，请稍后重试"
                }
                return
            }
        }

        let now = Date.now
        var updatedCount = 0
        for asset in assets {
            guard let newPrice = prices[asset.id], newPrice > 0 else { continue }
            let oldPrice = asset.currentPrice
            let oldLevel = asset.valuationLevel

            asset.currentPrice = newPrice
            asset.lastPriceUpdatedAt = now
            updatedCount += 1

            evaluateAlerts(
                asset: asset,
                oldPrice: oldPrice,
                newPrice: newPrice,
                oldLevel: oldLevel,
                newLevel: asset.valuationLevel
            )
        }
        if updatedCount == 0 {
            debugLog("Refresh completed but no asset was updated")
            if showMessage {
                refreshMessage = "刷新失败，请稍后重试"
            }
            return
        }
        portfolio?.lastGlobalRefreshAt = now
        try? modelContext.save()
        debugLog("Refresh completed, updated \(updatedCount) assets")
    }

    @MainActor
    private func triggerRefresh(source: String, showMessage: Bool = true) {
        guard refreshTask == nil else {
            debugLog("Skip refresh from \(source): task already running")
            return
        }
        refreshTask = Task { @MainActor in
            debugLog("Trigger refresh from \(source)")
            await refreshPrices(showMessage: showMessage)
            refreshTask = nil
        }
    }

    private func evaluateAlerts(
        asset: Asset,
        oldPrice: Double,
        newPrice: Double,
        oldLevel: ValuationLevel,
        newLevel: ValuationLevel
    ) {
        guard oldPrice > 0 else { return }
        guard asset.hasValuationConfigured else { return }

        let buy = asset.idealBuyPrice
        let sell = asset.idealSellPrice

        if oldPrice > buy && newPrice <= buy {
            NotificationService.shared.scheduleIfAllowed(asset: asset, type: .crossedIdealBuy)
        }
        if oldPrice < sell && newPrice >= sell {
            NotificationService.shared.scheduleIfAllowed(asset: asset, type: .crossedIdealSell)
        }
        if oldLevel != .deepUndervalued && newLevel == .deepUndervalued {
            NotificationService.shared.scheduleIfAllowed(asset: asset, type: .enteredDeepUnder)
        }
        if oldLevel != .deepOvervalued && newLevel == .deepOvervalued {
            NotificationService.shared.scheduleIfAllowed(asset: asset, type: .enteredDeepOver)
        }
    }

    private func isCancelledError(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled { return true }
        return false
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[Dashboard] \(message)")
#endif
    }
}

struct SortSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedOption: DashboardSortOption

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("排序")
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.bodyText)
                        .foregroundColor(.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.vertical, Spacing.md)

            Divider()

            VStack(spacing: 0) {
                Text("排序方式")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)

                let options = DashboardSortOption.allCases
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        selectedOption = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.rawValue)
                                .font(.bodyText)
                                .foregroundColor(.textPrimary)
                            if option == .deviationHighToLow {
                                Text("推荐")
                                    .font(.smallCaption)
                                    .foregroundColor(.themePrimary)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(Color.themeLight)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                            }
                            Spacer()
                            if selectedOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.themePrimary)
                                    .font(.bodyText)
                            }
                        }
                        .padding(.horizontal, Spacing.screenPadding)
                        .padding(.vertical, Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < options.count - 1 {
                        Divider()
                            .padding(.leading, Spacing.screenPadding)
                    }
                }
            }
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.sm)

            Spacer()
        }
        .background(Color.pageBg)
    }
}

#Preview {
    @Previewable @State var selected = 0
    @Previewable @State var autoAdd = false
    DashboardView(selectedTab: $selected, shouldAutoAddAsset: $autoAdd)
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
