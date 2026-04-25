import SwiftUI

// MARK: - Compact Asset Row (V2.0)
// 看板/资产管理用紧凑横向资产行。高度 ~110pt。
// 左侧：浅蓝色资产名首字 / 简称
// 右侧：资产名 + 市场 + 估值标签 + 当前价格 + 进度条 + 偏离 + 目标

struct CompactAssetRow: View {
    let asset: Asset
    let positionPct: Double
    let isPrivacy: Bool
    /// 是否显示当前价格（资产管理页可关掉）
    var showsPrice: Bool = true

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
                .minimumScaleFactor(0.55)
                .padding(4)
        }
        .frame(width: 56)
        .frame(maxHeight: .infinity)
    }

    private var badgeText: String {
        let name = asset.name
        if name.contains("Apple") { return "Apple" }
        if name.contains("Tesla") { return "Tesla" }
        if name.contains("BTC") || name.contains("比特币") { return "BTC" }
        if name.contains("Google") { return "Google" }
        return String(name.prefix(2))
    }

    // MARK: - Right Content

    private var rightContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            firstRow
            secondRow
            thirdRow
        }
    }

    private var firstRow: some View {
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
            valuationTag
            Spacer(minLength: 4)
            if showsPrice {
                Text(priceText.maskedIfPrivacy(isPrivacy))
                    .font(.bodyText)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var valuationTag: some View {
        if asset.hasValuationConfigured {
            let lvl = asset.valuationLevel
            Text(lvl.rawValue)
                .font(.smallCaption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(lvl.color.opacity(0.12))
                .foregroundStyle(lvl.color)
                .clipShape(Capsule())
        } else {
            Text("估值未设置")
                .font(.smallCaption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.divider.opacity(0.5))
                .foregroundStyle(Color.textTertiary)
                .clipShape(Capsule())
        }
    }

    private var secondRow: some View {
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
    }

    private var thirdRow: some View {
        HStack(spacing: 4) {
            Text(deviationText)
                .font(.smallCaption)
                .foregroundStyle(deviationColor)
                .lineLimit(1)
            Spacer()
            Text(asset.hasTargetPosition
                 ? "目标 \(formatPercent(asset.targetPositionRatio))"
                 : "未设目标")
                .font(.smallCaption)
                .foregroundStyle(Color.textTertiary)
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
        let body = AppNumberFormat.priceString(asset.currentPrice, currency: asset.currency, market: asset.market)
        return "\(currencySymbol)\(body)"
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
        guard asset.hasTargetPosition else { return "尚未设置目标仓位" }
        let dev = positionPct - asset.targetPositionRatio
        if let maxV = asset.maxPositionRatio, positionPct >= maxV { return "已超过仓位上限" }
        if dev >= 5 { return "高于目标 +\(String(format: "%.1f", dev))%" }
        if dev > 1 { return "略高于目标 +\(String(format: "%.1f", dev))%" }
        if dev <= -5 { return "低于目标 \(String(format: "%.1f", dev))%" }
        if dev < -1 { return "略低于目标 \(String(format: "%.1f", dev))%" }
        return "接近目标仓位"
    }

    private var deviationColor: Color {
        guard asset.hasTargetPosition else { return .textTertiary }
        let dev = positionPct - asset.targetPositionRatio
        if let maxV = asset.maxPositionRatio, positionPct >= maxV { return .lossRed }
        if dev >= 5 { return .valuationOrange }
        if abs(dev) <= 2 { return .profitGreen }
        return .themePrimary
    }
}

