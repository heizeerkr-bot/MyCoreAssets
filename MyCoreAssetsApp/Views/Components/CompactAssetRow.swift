import SwiftUI

// MARK: - Compact Asset Row (V2.0)
// 看板/资产管理用紧凑横向资产行。高度 ~110pt。
// 左侧：浅蓝色资产名首字 / 简称
// 右侧：资产名 + 市场 + 估值标签 + 当前价格 + 进度条 + 偏离 + 目标

struct CompactAssetRow: View {
    let asset: Asset
    /// 当前仓位百分比
    let positionPct: Double
    /// 估值档位
    let level: ValuationLevel
    /// 是否启用隐私模式（金额遮罩）
    let isPrivacy: Bool

    var body: some View {
        HStack(spacing: 0) {
            leftBadge
            rightContent
                .padding(.horizontal, Spacing.cardPadding)
                .padding(.vertical, Spacing.cardPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .cardShadow()
    }

    // MARK: - Left Badge

    private var leftBadge: some View {
        ZStack {
            Color.themeLight
            Text(badgeText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.themePrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(4)
        }
        .frame(width: 56)
        .frame(maxHeight: .infinity)
    }

    private var badgeText: String {
        // 资产名头 2 个字符（中文取前 2，英文取首单词或前几位）
        if asset.name.contains("Apple") { return "Apple" }
        if asset.name.contains("Tesla") { return "Tesla" }
        if asset.name.contains("BTC") || asset.name.contains("比特币") { return "BTC" }
        if asset.name.contains("Google") { return "Google" }
        return String(asset.name.prefix(2))
    }

    // MARK: - Right Content

    private var rightContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 第一行：名 + 市场标签 + 估值标签 + 价格
            HStack(alignment: .top, spacing: 6) {
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
                Text(level.rawValue)
                    .font(.smallCaption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(level.color.opacity(0.12))
                    .foregroundStyle(level.color)
                    .clipShape(Capsule())
                Spacer()
                Text(priceText.maskedIfPrivacy(isPrivacy))
                    .font(.bodyText)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
            }

            // 第二行：仓位标签 + 进度条 + 当前 %
            HStack(spacing: 8) {
                Text("仓位")
                    .font(.smallCaption)
                    .foregroundStyle(Color.textSecondary)
                PositionBar(current: positionPct, target: asset.targetPositionRatio,
                            max: asset.maxPositionRatio, height: 5)
                    .frame(maxWidth: .infinity)
                Text(formatPercent(positionPct))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .frame(minWidth: 48, alignment: .trailing)
            }

            // 第三行：偏离提示 + 目标
            HStack(spacing: 4) {
                Text(deviationText)
                    .font(.smallCaption)
                    .foregroundStyle(deviationColor)
                Spacer()
                if asset.hasTargetPosition {
                    Text("目标 \(formatPercent(asset.targetPositionRatio))")
                        .font(.smallCaption)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Text("未设目标")
                        .font(.smallCaption)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }

    // MARK: - Helpers

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

    private var priceText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = (asset.market == "BTC" && asset.currentPrice < 1) ? 4 : 2
        if asset.market == "BTC" && asset.currentPrice >= 10000 {
            formatter.maximumFractionDigits = 0
        }
        let num = formatter.string(from: NSNumber(value: asset.currentPrice)) ?? "0.00"
        return "\(currencySymbol)\(num)"
    }

    private var currencySymbol: String {
        switch asset.currency {
        case "CNY": return "¥"
        case "HKD": return "HK$"
        case "USD": return "$"
        default: return ""
        }
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    private var deviationText: String {
        guard asset.hasTargetPosition else { return "未设估值" }
        let dev = positionPct - asset.targetPositionRatio
        if dev >= 5 { return "高于目标 +\(String(format: "%.1f", dev))%" }
        if dev > 0 { return "略高 +\(String(format: "%.1f", dev))%" }
        if dev < -5 { return "低于目标 \(String(format: "%.1f", dev))%" }
        if dev < 0 { return "略低 \(String(format: "%.1f", dev))%" }
        return "已达目标"
    }

    private var deviationColor: Color {
        guard asset.hasTargetPosition else { return .textTertiary }
        let dev = positionPct - asset.targetPositionRatio
        if asset.maxPositionRatio.map({ positionPct >= $0 }) == true { return .lossRed }
        if dev >= 5 { return .valuationOrange }
        if abs(dev) <= 2 { return .profitGreen }
        return .themePrimary
    }
}
