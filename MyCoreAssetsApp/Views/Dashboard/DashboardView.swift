import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Asset.sortOrder) private var assets: [Asset]
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]

    @State private var showingSortSheet = false
    @State private var selectedSortOption: DashboardSortOption = .defaultOrder

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
        case .defaultOrder:
            return assets.sorted { $0.sortOrder < $1.sortOrder }
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
                refreshAllPricesTimestamp()
            }
            .background(Color.pageBg)
            .navigationTitle("我的核心资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        refreshAllPricesTimestamp()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.themePrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showingSortSheet) {
                SortSheetView(selectedOption: $selectedSortOption)
                    .presentationDetents([.medium])
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
            Text("请先完成初始化向导添加资产。")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private func refreshAllPricesTimestamp() {
        let now = Date.now
        for asset in assets {
            asset.lastPriceUpdatedAt = now
        }
        portfolio?.lastGlobalRefreshAt = now
        try? modelContext.save()
    }
}

struct SortSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedOption: DashboardSortOption

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("关闭") { dismiss() }
                    .font(.bodyText)
                    .foregroundColor(.themePrimary)
                Spacer()
                Text("排序")
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button("应用") { dismiss() }
                    .font(.bodyText)
                    .foregroundColor(.themePrimary)
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
    DashboardView()
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
