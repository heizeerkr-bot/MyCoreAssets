import SwiftUI

struct PortfolioSummaryCard: View {
    let totalValue: Double
    let totalInvested: Double
    let remainingCash: Double

    private var profitLoss: Double { totalValue - totalInvested }
    private var profitLossPercent: Double {
        guard totalInvested > 0 else { return 0 }
        return profitLoss / totalInvested * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("总资产")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Text("¥ \(formatNumber(totalValue))")
                .font(.superLargeTitle)
                .foregroundColor(.white)

            HStack(spacing: Spacing.xs) {
                Image(systemName: profitLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12))
                Text("\(profitLoss >= 0 ? "+" : "")\(formatNumber(profitLoss))")
                    .font(.caption)
                Text("(\(String(format: "%+.1f%%", profitLossPercent)))")
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.9))

            Divider()
                .background(Color.white.opacity(0.3))

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("已投入")
                        .font(.smallCaption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("¥ \(formatNumber(totalInvested))")
                        .font(.bodyText)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("剩余现金")
                        .font(.smallCaption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("¥ \(formatNumber(remainingCash))")
                        .font(.bodyText)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

#Preview {
    PortfolioSummaryCard(
        totalValue: MockData.totalValueCNY,
        totalInvested: MockData.totalInvested,
        remainingCash: MockData.remainingCash
    )
    .padding()
    .background(Color.pageBg)
}
