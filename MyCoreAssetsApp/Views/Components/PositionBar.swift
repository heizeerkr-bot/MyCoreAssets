import SwiftUI

// MARK: - Position Bar (V2.0)
// 横向进度条：底色轨道 + 当前仓位填充 + 目标位置橙色 marker。
// 用于看板紧凑卡片、详情仓位分析、资产管理目标列表。

struct PositionBar: View {
    /// 当前仓位百分比（0-100）
    let current: Double
    /// 目标仓位百分比（0-100，0 时不显示 marker）
    let target: Double
    /// 仓位上限百分比（可选，nil 时不显示）
    var max: Double? = nil
    /// 进度条高度
    var height: CGFloat = 6
    /// 当前仓位填充色（默认根据偏离度自动）
    var fillColor: Color? = nil

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let scale = effectiveScale  // 1% 对应多少 pt
            let currentWidth = Swift.min(totalWidth, totalWidth * CGFloat(current / scale))
            let targetX = totalWidth * CGFloat(target / scale)

            ZStack(alignment: .leading) {
                // 轨道
                Capsule()
                    .fill(Color.positionBarTrack)
                    .frame(height: height)

                // 当前仓位填充
                Capsule()
                    .fill(fillColor ?? autoFillColor)
                    .frame(width: currentWidth, height: height)

                // 目标 marker（橙色竖线）
                if target > 0 && targetX <= totalWidth {
                    Rectangle()
                        .fill(Color.targetMarker)
                        .frame(width: 2, height: height + 6)
                        .offset(x: targetX - 1, y: 0)
                }

                // 上限 marker（红色竖线，可选）
                if let maxVal = max, maxVal > 0 {
                    let maxX = totalWidth * CGFloat(maxVal / scale)
                    if maxX <= totalWidth {
                        Rectangle()
                            .fill(Color.lossRed.opacity(0.6))
                            .frame(width: 2, height: height + 6)
                            .offset(x: maxX - 1, y: 0)
                    }
                }
            }
        }
        .frame(height: height + 6)
    }

    /// 进度条总宽对应的"100%"基准。当目标或上限超过 50%（如 100%）时，让条以 100% 为满；常规情况下让条以 50% 为满（让 20-30% 仓位看起来不那么挤左边）。
    private var effectiveScale: Double {
        let maxVal = max ?? 0
        let limit = Swift.max(target, Swift.max(maxVal, current))
        if limit >= 60 { return 100 }
        return 50
    }

    private var autoFillColor: Color {
        guard target > 0 else { return .themePrimary }
        let deviation = current - target
        if let maxVal = max, current >= maxVal { return .lossRed }
        if deviation >= 5 { return .valuationOrange }
        if abs(deviation) <= 2 { return .profitGreen }
        return .themePrimary
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 4) {
            Text("当前 2.6% / 目标 20%")
                .font(.caption)
            PositionBar(current: 2.6, target: 20, max: 25)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("当前 28.1% / 目标 25%")
                .font(.caption)
            PositionBar(current: 28.1, target: 25, max: 35)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("当前 45% / 目标 30% / 上限 40%（超限）")
                .font(.caption)
            PositionBar(current: 45, target: 30, max: 40)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("无目标")
                .font(.caption)
            PositionBar(current: 12, target: 0, max: nil)
        }
    }
    .padding()
    .background(Color.pageBg)
}
