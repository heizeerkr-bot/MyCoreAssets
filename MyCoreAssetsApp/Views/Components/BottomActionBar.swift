import SwiftUI

// MARK: - Bottom Action Bar (V2.0)
// 详情页 / 向导页 底部固定按钮容器。白底 + hairline 顶分隔。
// 按钮内容用 ViewBuilder 自由排版（通常 2 等分按钮）。

struct BottomActionBar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.divider)
            HStack(spacing: Spacing.md) {
                content()
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
        }
        .background(Color.cardBg)
    }
}

// MARK: - 底部按钮样式（标准）

struct PrimaryActionButtonStyle: ButtonStyle {
    var tint: Color = .themePrimary
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyText)
            .fontWeight(.semibold)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tint.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    var tint: Color = .themePrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyText)
            .fontWeight(.medium)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tint.opacity(configuration.isPressed ? 0.16 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        BottomActionBar {
            Button("上一步") {}
                .buttonStyle(SecondaryActionButtonStyle())
            Button("下一步") {}
                .buttonStyle(PrimaryActionButtonStyle())
        }
    }
    .background(Color.pageBg)
}
