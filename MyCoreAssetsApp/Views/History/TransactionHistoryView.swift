import SwiftData
import SwiftUI

struct TransactionHistoryView: View {
    @Binding var selectedTab: Int
    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]

    private var groupedByDate: [(key: String, value: [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            AppDateFormat.dateOnlyString(transaction.occurredAt)
        }
        return grouped.keys.sorted(by: >).map { key in
            (key, grouped[key] ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                } else {
                    historyList
                        .background(Color.pageBg)
                }
            }
            .navigationTitle("交易记录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(groupedByDate, id: \.key) { section in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(section.key)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, Spacing.xs)

                        ForEach(section.value) { transaction in
                            transactionRow(transaction)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.vertical, Spacing.md)
        }
    }

    private func transactionRow(_ transaction: Transaction) -> some View {
        let tradeType = transaction.tradeType
        let currencySymbol = transaction.asset?.currencySymbol ?? ""
        let amountOriginal = transaction.tradeAmountInOriginalCurrency
        return VStack(spacing: Spacing.sm) {
            HStack {
                Text(transaction.asset?.name ?? "未知资产")
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
                Text(tradeType.displayName)
                    .font(.smallCaption)
                    .foregroundColor(tradeType.tintColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(tradeType.tintColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                Spacer()
                Text("\(currencySymbol)\(AppNumberFormat.wholeString(amountOriginal))")
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
            }

            HStack {
                Text("\(currencySymbol)\(AppNumberFormat.priceString(transaction.price, currency: transaction.asset?.currency ?? "CNY", market: transaction.asset?.market ?? MarketCode.cn.rawValue)) × \(AppNumberFormat.quantityString(transaction.quantity))")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text(AppDateFormat.timeString(transaction.occurredAt))
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "list.bullet.rectangle")
                .font(.superLargeTitle)
                .foregroundColor(.themePrimary.opacity(0.5))
            Text("暂无交易记录")
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)
            Button {
                selectedTab = 0
            } label: {
                Text("前往看板查看资产详情")
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
}

#Preview {
    @Previewable @State var selected = 2
    TransactionHistoryView(selectedTab: $selected)
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
