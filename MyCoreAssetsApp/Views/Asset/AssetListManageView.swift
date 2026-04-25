import SwiftData
import SwiftUI

struct AssetListManageView: View {
    @Binding var autoShowSearch: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Asset.sortOrder) private var assets: [Asset]
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]

    @State private var path: [UUID] = []
    @State private var showingSearch = false
    @State private var selectedAssetIDs: Set<String> = []
    @State private var deleteTargets: [Asset] = []
    @State private var showingDeleteConfirm = false
    @State private var toastMessage: String?
    @State private var toastTask: Task<Void, Never>?

    private var portfolio: Portfolio? { portfolios.first }

    private var totalPortfolioValueCNY: Double {
        let assetsValue = assets.reduce(0) { $0 + $1.currentValueCNY }
        return assetsValue + (portfolio?.currentCashCNY ?? 0)
    }

    private var totalTargetRatio: Double {
        assets.reduce(0) { $0 + $1.targetPositionRatio }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if assets.isEmpty {
                    emptyState
                } else {
                    contentScrollView
                }
            }
            .background(Color.pageBg)
            .navigationTitle("资产管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.bodyText)
                            .foregroundColor(.themePrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showingSearch, onDismiss: addAssetsFromSearchSelection) {
                AssetSearchView(selectedAssetIDs: $selectedAssetIDs)
            }
            .navigationDestination(for: UUID.self) { id in
                if let asset = assets.first(where: { $0.id == id }) {
                    AssetEditView(asset: asset)
                }
            }
            .alert("确认删除", isPresented: $showingDeleteConfirm) {
                Button("删除", role: .destructive) {
                    deleteSelectedAssets()
                }
                Button("取消", role: .cancel) {}
            } message: {
                if let name = deleteTargets.first?.name {
                    Text("确定删除「\(name)」吗？关联的交易记录将一并删除。")
                }
            }
            .onChange(of: autoShowSearch) { _, newValue in
                if newValue {
                    showingSearch = true
                    autoShowSearch = false
                }
            }
            .overlay(alignment: .bottom) {
                if let toastMessage {
                    Text(toastMessage)
                        .font(.caption)
                        .foregroundColor(.cardBg)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.textPrimary.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        .padding(.bottom, Spacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: toastMessage)
        }
    }

    // MARK: - Content

    private var contentScrollView: some View {
        List {
            Section {
                targetConfigHero
                    .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenPadding, bottom: Spacing.md, trailing: Spacing.screenPadding))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                ForEach(assets) { asset in
                    AssetManageRow(
                        asset: asset,
                        currentPositionPct: asset.currentPositionRatio(totalPortfolioCNY: totalPortfolioValueCNY)
                    ) {
                        path.append(asset.id)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenPadding, bottom: Spacing.sm, trailing: Spacing.screenPadding))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteTargets = [asset]
                            showingDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var targetConfigHero: some View {
        HeroCard(style: .light) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("目标配置")
                            .font(.bodyText)
                            .foregroundStyle(Color.textSecondary)
                        Image(systemName: "info.circle")
                            .font(.smallCaption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    Text("\(String(format: "%.0f", totalTargetRatio))%")
                        .font(.heroAmount)
                        .foregroundStyle(targetTotalColor)
                    Text(targetTotalSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
            }
        }
        .frame(height: 140)
    }

    private var targetTotalColor: Color {
        if totalTargetRatio > 100 + 0.5 { return .valuationOrange }
        if totalTargetRatio < 100 - 0.5 { return .textSecondary }
        return .themePrimary
    }

    private var targetTotalSubtitle: String {
        if totalTargetRatio > 100 + 0.5 {
            return "已超配 \(String(format: "%.0f", totalTargetRatio - 100))%"
        }
        if totalTargetRatio < 100 - 0.5 {
            return "未配置 \(String(format: "%.0f", 100 - totalTargetRatio))%"
        }
        return "总目标仓位"
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "chart.pie")
                .font(.superLargeTitle)
                .foregroundColor(.themePrimary.opacity(0.5))
            Text("暂无资产")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)
            Button {
                showingSearch = true
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
            Spacer()
        }
        .padding(.horizontal, Spacing.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func addAssetsFromSearchSelection() {
        guard !selectedAssetIDs.isEmpty else { return }

        let existingKeys = Set(assets.map { "\($0.market)-\($0.symbol)" })
        let selectedPresets = PresetAssets.searchPool.filter { selectedAssetIDs.contains($0.id) }
        let newPresets = selectedPresets.filter { !existingKeys.contains($0.id) }
        guard !newPresets.isEmpty else {
            selectedAssetIDs.removeAll()
            return
        }

        let currentMaxOrder = assets.map(\.sortOrder).max() ?? -1
        for (index, preset) in newPresets.enumerated() {
            let newAsset = Asset(
                name: preset.name,
                symbol: preset.symbol,
                market: preset.market,
                currency: preset.currency,
                idealBuyPrice: 0,
                idealSellPrice: 0,
                currentPrice: 0,
                lastPriceUpdatedAt: nil,
                holdingQuantity: 0,
                averageCost: 0,
                targetPositionRatio: 0,
                maxPositionRatio: nil,
                isWatched: true,
                notes: nil,
                sortOrder: currentMaxOrder + index + 1
            )
            modelContext.insert(newAsset)
        }
        try? modelContext.save()
        selectedAssetIDs.removeAll()

        showToast("已添加 \(newPresets.count) 个资产，可点击列表项完善估值与仓位")
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if !Task.isCancelled {
                await MainActor.run { toastMessage = nil }
            }
        }
    }

    private func deleteSelectedAssets() {
        guard let portfolio else { return }
        for asset in deleteTargets {
            var cashToRestore: Double = 0
            for transaction in asset.transactions {
                let amount = transaction.cnyAmount ?? 0
                if transaction.tradeType == .buy {
                    cashToRestore += amount
                } else {
                    cashToRestore -= amount
                }
            }
            portfolio.currentCashCNY += cashToRestore
            modelContext.delete(asset)
        }
        try? modelContext.save()
        deleteTargets.removeAll()
    }
}

// MARK: - Manage Row（资产管理用紧凑行）

private struct AssetManageRow: View {
    let asset: Asset
    let currentPositionPct: Double
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                badge
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: 6) {
                        Text(asset.name)
                            .font(.bodyText)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)
                        Text(marketLabel)
                            .font(.smallCaption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.themeLight)
                            .foregroundStyle(Color.themePrimary)
                            .clipShape(Capsule())
                        Spacer()
                    }
                    PositionBar(
                        current: currentPositionPct,
                        target: asset.targetPositionRatio,
                        max: asset.maxPositionRatio,
                        height: 5
                    )
                }
                .padding(.horizontal, Spacing.cardPadding)
                .padding(.vertical, Spacing.cardPadding)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(asset.hasTargetPosition
                         ? "目标 \(String(format: "%.0f", asset.targetPositionRatio))%"
                         : "未设目标")
                        .font(.smallCaption)
                        .foregroundStyle(asset.hasTargetPosition ? Color.textSecondary : Color.textTertiary)
                    Image(systemName: "chevron.right")
                        .font(.smallCaption)
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.trailing, Spacing.cardPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            .cardShadow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var badge: some View {
        ZStack {
            Color.themeLight
            Text(badgeText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.themePrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.55)
                .padding(4)
        }
        .frame(width: 56)
        .frame(maxHeight: .infinity)
    }

    private var badgeText: String {
        let name = asset.name
        if name.contains("Apple") { return "Apple" }
        if name.contains("Tesla") { return "Tesla" }
        if name.contains("BTC") || name.contains("比特币") { return "BTC" }
        if name.contains("Google") { return "Google" }
        return String(name.prefix(2))
    }

    private var marketLabel: String {
        switch asset.market {
        case "CN": return "A股"
        case "HK": return "港股"
        case "US": return "美股"
        case "BTC": return "加密"
        case "FUND": return "基金"
        default: return asset.market
        }
    }
}

#Preview {
    @Previewable @State var autoSearch = false
    AssetListManageView(autoShowSearch: $autoSearch)
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
