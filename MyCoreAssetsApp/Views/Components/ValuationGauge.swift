import SwiftUI

// MARK: - Valuation Gauge (V2.0)
// 5 档彩色色条 + 三角形当前 marker。展示估值状态。
// 段从左到右：极度低估 / 比较低估 / 合理 / 比较高估 / 极度高估

struct ValuationGauge: View {
    /// 当前估值档位
    let level: ValuationLevel
    /// 理想买入价 A（原币种，0 表示未设置）
    let idealBuy: Double
    /// 理想卖出价 B（原币种，0 表示未设置）
    let idealSell: Double
    /// 当前价格 P
    let currentPrice: Double

    private let barHeight: CGFloat = 10
    private let segments: [Color] = [
        .valuationDeepGreen,
        .valuationLightGreen,
        .valuationNeutral,
        .valuationOrange,
        .valuationRed
    ]

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let segWidth = geo.size.width / 5
                let markerX = markerOffset(totalWidth: geo.size.width)

                ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { i in
                            Rectangle().fill(segments[i])
                                .frame(width: segWidth, height: barHeight)
                        }
                    }
                    .clipShape(Capsule())

                    // 三角形当前 marker，向下指
                    Triangle()
                        .fill(Color.themePrimary)
                        .frame(width: 14, height: 10)
                        .offset(x: markerX - 7, y: -14)
                }
            }
            .frame(height: barHeight + 14)

            // 4 个分段标签
            HStack(spacing: 0) {
                segLabel("极低")
                segLabel("低估")
                segLabel("合理")
                segLabel("偏高")
                segLabel("高估")
            }
            .font(.smallCaption)
            .foregroundStyle(Color.textSecondary)
        }
    }

    /// 计算 marker 在条上的水平 offset
    private func markerOffset(totalWidth: CGFloat) -> CGFloat {
        guard idealBuy > 0, idealSell > 0, idealSell > idealBuy else {
            // 未配置：marker 居中
            return totalWidth / 2
        }
        let segWidth = totalWidth / 5
        let aLow = idealBuy * 0.85
        let bHigh = idealSell * 1.15

        switch level {
        case .deepUndervalued:
            // 0 ~ A*0.85，按比例映射到 segment 0
            let local = aLow > 0 ? Swift.min(currentPrice / aLow, 1) : 0.5
            return segWidth * CGFloat(local)
        case .undervalued:
            // A*0.85 ~ A，segment 1
            let local = (currentPrice - aLow) / Swift.max(idealBuy - aLow, 0.01)
            return segWidth * (1 + CGFloat(Swift.max(0, Swift.min(local, 1))))
        case .fair:
            // A ~ B，segment 2
            let local = (currentPrice - idealBuy) / Swift.max(idealSell - idealBuy, 0.01)
            return segWidth * (2 + CGFloat(Swift.max(0, Swift.min(local, 1))))
        case .overvalued:
            // B ~ B*1.15，segment 3
            let local = (currentPrice - idealSell) / Swift.max(bHigh - idealSell, 0.01)
            return segWidth * (3 + CGFloat(Swift.max(0, Swift.min(local, 1))))
        case .deepOvervalued:
            // > B*1.15，segment 4
            let extra = (currentPrice - bHigh) / Swift.max(bHigh * 0.5, 0.01)
            return segWidth * (4 + CGFloat(Swift.max(0, Swift.min(extra, 1))))
        }
    }

    private func segLabel(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - 三角形 Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ValuationGauge(level: .fair, idealBuy: 198, idealSell: 300, currentPrice: 255)
        ValuationGauge(level: .deepUndervalued, idealBuy: 198, idealSell: 300, currentPrice: 150)
        ValuationGauge(level: .deepOvervalued, idealBuy: 198, idealSell: 300, currentPrice: 380)
    }
    .padding()
    .background(Color.pageBg)
}
