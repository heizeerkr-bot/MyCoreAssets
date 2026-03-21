import SwiftData
import SwiftUI

struct AssetListManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Asset.sortOrder) private var assets: [Asset]

    @State private var path: [UUID] = []
    @State private var showingSearch = false
    @State private var selectedAssetIDs: Set<String> = []
    @State private var deleteTargets: [Asset] = []
    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if assets.isEmpty {
                    emptyState
                } else {
                    assetList
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
            .confirmationDialog("确认删除所选资产？", isPresented: $showingDeleteConfirm) {
                Button("删除", role: .destructive) {
                    deleteSelectedAssets()
                }
                Button("取消", role: .cancel) {}
            }
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
                }
                .buttonStyle(.plain)
            .listRowBackground(Color.cardBg)
            }
            .onDelete { offsets in
                deleteTargets = offsets.map { assets[$0] }
                showingDeleteConfirm = !deleteTargets.isEmpty
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
        var firstInsertedID: UUID?
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
            if firstInsertedID == nil {
                firstInsertedID = newAsset.id
            }
        }
        try? modelContext.save()
        selectedAssetIDs.removeAll()

        if let firstInsertedID {
            path.append(firstInsertedID)
        }
    }

    private func deleteSelectedAssets() {
        for asset in deleteTargets {
            modelContext.delete(asset)
        }
        try? modelContext.save()
        deleteTargets.removeAll()
    }
}

#Preview {
    AssetListManageView()
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
