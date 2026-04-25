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

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if assets.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                } else {
                    assetList
                        .background(Color.pageBg)
                }
            }
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

    private var assetList: some View {
        List {
            ForEach(assets) { asset in
                Button {
                    path.append(asset.id)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(asset.valuationLevel.color)
                            .frame(width: Spacing.sm, height: Spacing.sm)

                        Text(asset.name)
                            .font(.bodyText)
                            .foregroundColor(.textPrimary)

                        Text(asset.marketDisplayName)
                            .font(.smallCaption)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.pageBg)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

                        Spacer()

                        Text("目标 \(String(format: "%.0f", asset.targetPositionRatio))%")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, Spacing.xs)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteTargets = [asset]
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .listRowBackground(Color.cardBg)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

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
    }

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
            // Restore cash: reverse all transactions for this asset
            var cashToRestore: Double = 0
            for transaction in asset.transactions {
                let amount = transaction.cnyAmount ?? 0
                if transaction.tradeType == .buy {
                    cashToRestore += amount   // buy deducted cash, restore it
                } else {
                    cashToRestore -= amount   // sell added cash, take it back
                }
            }
            portfolio.currentCashCNY += cashToRestore
            modelContext.delete(asset)
        }
        try? modelContext.save()
        deleteTargets.removeAll()
    }
}

#Preview {
    @Previewable @State var autoSearch = false
    AssetListManageView(autoShowSearch: $autoSearch)
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
