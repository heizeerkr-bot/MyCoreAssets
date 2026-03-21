import SwiftUI

struct PortfolioSummaryCard: View {
    let totalValue: Double
    let initialCash: Double
    let totalInvested: Double
    let remainingCash: Double
    let lastUpdatedAt: Date?

    private var profitLoss: Double { totalValue - initialCash }
    private var profitLossPercent: Double {
        guard initialCash > 0 else { return 0 }
        return profitLoss / initialCash * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("总资产")
                .font(.caption)
                .foregroundColor(.cardBg.opacity(0.8))

            Text("¥\(AppNumberFormat.wholeString(totalValue))")
                .font(.superLargeTitle)
                .foregroundColor(.cardBg)

            HStack(spacing: Spacing.xs) {
                Image(systemName: profitLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.smallCaption)
                Text("\(profitLoss >= 0 ? "+" : "")\(formatNumber(profitLoss))")
                    .font(.caption)
                Text("(\(String(format: "%+.1f%%", profitLossPercent)))")
                    .font(.caption)
            }
            .foregroundColor(.cardBg.opacity(0.9))

            Divider()
                .background(Color.cardBg.opacity(0.3))

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("已投入")
                        .font(.smallCaption)
                        .foregroundColor(.cardBg.opacity(0.7))
                    Text("¥\(formatNumber(totalInvested))")
                        .font(.bodyText)
                        .foregroundColor(.cardBg)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("剩余现金")
                        .font(.smallCaption)
                        .foregroundColor(.cardBg.opacity(0.7))
                    Text("¥\(formatNumber(remainingCash))")
                        .font(.bodyText)
                        .foregroundColor(.cardBg)
                }
            }

            if let lastUpdatedAt {
                HStack {
                    Spacer()
                    Text("更新时间 \(timeString(lastUpdatedAt))")
                        .font(.smallCaption)
                        .foregroundColor(.cardBg.opacity(0.8))
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: [.themePrimary, .themeDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
    }

    private func formatNumber(_ value: Double) -> String {
        AppNumberFormat.wholeString(value)
    }

    private func timeString(_ date: Date) -> String {
        AppDateFormat.timeString(date)
    }
}

#Preview {
    PortfolioSummaryCard(
        totalValue: 1_458_920,
        initialCash: 1_250_000,
        totalInvested: 987_500,
        remainingCash: 471_420,
        lastUpdatedAt: .now
    )
    .padding()
    .background(Color.pageBg)
}
