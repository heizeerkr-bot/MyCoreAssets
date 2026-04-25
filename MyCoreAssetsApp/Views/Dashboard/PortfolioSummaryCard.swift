import SwiftUI

struct PortfolioSummaryCard: View {
    let totalValue: Double
    let initialCash: Double
    let totalInvested: Double
    let remainingCash: Double
    let lastUpdatedAt: Date?

    @AppStorage(PrivacyMode.storageKey) private var isPrivacy = false

    private var profitLoss: Double { totalValue - initialCash }
    private var profitLossPercent: Double {
        guard initialCash > 0 else { return 0 }
        return profitLoss / initialCash * 100
    }

    var body: some View {
        HeroCard(style: .deep) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: 6) {
                    Text("总资产")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.85))
                    PrivacyEyeButton(tint: .white)
                    Spacer()
                }

                Text("¥\(formatNumber(totalValue))".maskedIfPrivacy(isPrivacy))
                    .font(.heroAmount)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: Spacing.xs) {
                    Image(systemName: profitLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.smallCaption)
                    Text("\(profitLoss >= 0 ? "+" : "")\(formatNumber(profitLoss))".maskedIfPrivacy(isPrivacy))
                        .font(.caption)
                    Text("(\(String(format: "%+.1f%%", profitLossPercent)))")
                        .font(.caption)
                }
                .foregroundStyle(profitLoss >= 0
                                 ? Color.profitGreen.opacity(0.95)
                                 : Color.lossRed.opacity(0.95))

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("已投入")
                            .font(.smallCaption)
                            .foregroundStyle(Color.white.opacity(0.7))
                        Text("¥\(formatNumber(totalInvested))".maskedIfPrivacy(isPrivacy))
                            .font(.bodyText)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("剩余现金")
                            .font(.smallCaption)
                            .foregroundStyle(Color.white.opacity(0.7))
                        Text("¥\(formatNumber(remainingCash))".maskedIfPrivacy(isPrivacy))
                            .font(.bodyText)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, Spacing.xs)

                if let lastUpdatedAt {
                    Text("更新时间 \(timeString(lastUpdatedAt))")
                        .font(.smallCaption)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
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
        totalValue: 1_281_427,
        initialCash: 1_250_000,
        totalInvested: 532_408,
        remainingCash: 749_019,
        lastUpdatedAt: .now
    )
    .padding()
    .background(Color.pageBg)
}
