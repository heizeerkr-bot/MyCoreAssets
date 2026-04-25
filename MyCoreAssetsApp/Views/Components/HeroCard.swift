import SwiftUI

// MARK: - Hero Card (V2.0)
// 通用 hero 容器：深蓝渐变 / 浅色双层渐变 + 右上角白色波纹装饰。
// 用于看板总资产、详情价格、设置 App 信息、资产管理目标配置。

struct HeroCard<Content: View>: View {
    enum Style {
        case deep   // 深蓝渐变（看板/详情）
        case light  // 浅色（资产管理目标配置/设置 App 信息）
    }

    let style: Style
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .topTrailing) {
            background
            HeroWaveDecor()
                .fill(waveColor)
                .frame(width: 200, height: 130)
                .offset(x: 30, y: -10)
                .clipped()

            content()
                .padding(Spacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl, style: .continuous))
        .cardShadow()
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .deep:
            LinearGradient.heroBlue
        case .light:
            LinearGradient.heroLight
        }
    }

    private var waveColor: Color {
        switch style {
        case .deep: return .heroWaveFill
        case .light: return .heroLightWave
        }
    }
}

// MARK: - 波纹装饰 Shape

struct HeroWaveDecor: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // 第一条波（更靠上的）
        path.move(to: CGPoint(x: 0, y: h * 0.55))
        path.addCurve(
            to: CGPoint(x: w * 0.6, y: h * 0.25),
            control1: CGPoint(x: w * 0.2, y: h * 0.7),
            control2: CGPoint(x: w * 0.4, y: h * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.5),
            control1: CGPoint(x: w * 0.8, y: h * 0.45),
            control2: CGPoint(x: w * 0.95, y: h * 0.6)
        )
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()

        // 第二条波叠加
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.75))
        path.addCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.5),
            control1: CGPoint(x: w * 0.4, y: h * 0.85),
            control2: CGPoint(x: w * 0.55, y: h * 0.3)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.85),
            control1: CGPoint(x: w * 0.85, y: h * 0.7),
            control2: CGPoint(x: w * 0.95, y: h * 0.95)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w * 0.2, y: h))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HeroCard(style: .deep) {
            VStack(alignment: .leading, spacing: 8) {
                Text("总资产")
                    .font(.bodyText)
                    .foregroundStyle(Color.white.opacity(0.85))
                Text("¥1,281,427")
                    .font(.heroAmount)
                    .foregroundStyle(.white)
                Text("↑ +31,427 (+2.5%)")
                    .font(.caption)
                    .foregroundStyle(Color.profitGreen)
            }
        }
        .frame(height: 200)

        HeroCard(style: .light) {
            VStack(alignment: .leading, spacing: 8) {
                Text("目标配置")
                    .font(.bodyText)
                    .foregroundStyle(Color.textSecondary)
                Text("100%")
                    .font(.heroAmount)
                    .foregroundStyle(Color.themePrimary)
                Text("总目标仓位")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(height: 140)
    }
    .padding()
    .background(Color.pageBg)
}
