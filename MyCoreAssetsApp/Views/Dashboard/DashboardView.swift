import SwiftUI

struct DashboardView: View {
    @State private var showingSortSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Portfolio Summary
                    PortfolioSummaryCard(
                        totalValue: MockData.totalValueCNY,
                        totalInvested: MockData.totalInvested,
                        remainingCash: MockData.remainingCash
                    )

                    // Asset List Header
                    HStack {
                        Text("核心资产 (\(MockData.assets.count))")
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
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.themePrimary)
                        }
                    }
                    .padding(.top, Spacing.sm)

                    // Asset Cards
                    ForEach(MockData.assets) { asset in
                        NavigationLink(destination: AssetDetailView(asset: asset)) {
                            AssetCardView(asset: asset)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.pageBg)
            .navigationTitle("我的核心资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Refresh action (demo only)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.themePrimary)
                    }
                }
            }
            .sheet(isPresented: $showingSortSheet) {
                SortSheetView()
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Sort Sheet

struct SortSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected = 0

    private let options = [
        "默认排序",
        "仓位从高到低",
        "仓位偏离目标从大到小",
        "估值低估优先",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("关闭") { dismiss() }
                    .foregroundColor(.themePrimary)
                Spacer()
                Text("排序")
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button("应用") { dismiss() }
                    .fontWeight(.semibold)
                    .foregroundColor(.themePrimary)
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.vertical, Spacing.md)

            Divider()

            // Options
            VStack(spacing: 0) {
                Text("排序方式")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)

                ForEach(options.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selected = index
                        }
                    } label: {
                        HStack {
                            Text(options[index])
                                .font(.bodyText)
                                .foregroundColor(.textPrimary)
                            if index == 2 {
                                Text("推荐")
                                    .font(.smallCaption)
                                    .foregroundColor(.themePrimary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.themeLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            Spacer()
                            if selected == index {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.themePrimary)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, Spacing.screenPadding)
                        .padding(.vertical, 14)
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
}
