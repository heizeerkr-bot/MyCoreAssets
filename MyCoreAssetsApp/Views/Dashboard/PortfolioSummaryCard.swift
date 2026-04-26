import SwiftUI

struct PortfolioSummaryCard: View {
    let totalValue: Double
    let initialCash: Double
    let totalInvested: Double
    let remainingCash: Double
    let lastUpdatedAt: Date?

    @AppStorage("privacyMode") private var isPrivacy = false

    private var profitLoss: Double { totalValue - initialCash }
    private var profitLossPercent: Double {
        guard initialCash > 0 else { return 0 }
        return profitLoss / initialCash * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 第一行：标题 + 眼睛
            HStack(spacing: Spacing.sm) {
                Text("总资产")
                    .font(.system(size: 15, weight: .medium))
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isPrivacy.toggle()
                    }
                } label: {
                    Image(systemName: isPrivacy ? "eye.slash" : "eye")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPrivacy ? "显示金额" : "隐藏金额")
            }
            .foregroundColor(.white.opacity(0.78))

            // 总资产
            Text(maskedAmount("¥\(formatNumber(totalValue))"))
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 6)

            // 涨跌
            HStack(spacing: 6) {
                Image(systemName: profitLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(profitLoss >= 0 ? "+" : "")\(maskedAmount(formatNumber(profitLoss))) (\(String(format: "%+.1f%%", profitLossPercent)))")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundColor(.white.opacity(0.88))
            .padding(.top, 6)

            // hairline 分隔
            Rectangle()
                .fill(Color.white.opacity(0.22))
                .frame(height: 1)
                .padding(.top, 18)

            // 双列：已投入 / 剩余现金（等宽对齐）
            HStack(alignment: .top, spacing: Spacing.md) {
                metric(title: "已投入", value: totalInvested, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                metric(title: "剩余现金", value: remainingCash, alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.top, 14)

            // 更新时间（独占一行，右下角）
            if let lastUpdatedAt {
                Text("更新于 \(timeString(lastUpdatedAt))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Image("DashboardTotalAssetsCard")
                .resizable()
                .scaledToFill()
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        .shadow(color: Color.themeDeep.opacity(0.22), radius: 14, x: 0, y: 10)
    }

    // MARK: - Helpers

    private func metric(title: String, value: Double, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.68))
            Text(maskedAmount("¥\(formatNumber(value))"))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.66)
        }
    }

    private func maskedAmount(_ text: String) -> String {
        isPrivacy ? "••••••" : text
    }

    private func formatNumber(_ value: Double) -> String {
        AppNumberFormat.wholeString(value)
    }

    private func timeString(_ date: Date) -> String {
        AppDateFormat.timeString(date)
    }
}

#Preview {
    VStack(spacing: 16) {
        PortfolioSummaryCard(
            totalValue: 1_281_427,
            initialCash: 1_250_000,
            totalInvested: 532_408,
            remainingCash: 749_019,
            lastUpdatedAt: .now
        )
        PortfolioSummaryCard(
            totalValue: 1_250_000,
            initialCash: 1_250_000,
            totalInvested: 0,
            remainingCash: 1_250_000,
            lastUpdatedAt: .now
        )
    }
    .padding()
    .background(Color.pageBg)
}
