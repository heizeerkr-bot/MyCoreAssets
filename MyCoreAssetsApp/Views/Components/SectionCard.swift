import SwiftUI

// MARK: - Section Card (V2.0)
// 通用白底圆角分组卡片，用于详情页 / 资产编辑 / 设置 等。
// 标题可选，正文用 ViewBuilder 任意排版。

struct SectionCard<Content: View>: View {
    let title: String?
    var trailing: AnyView? = nil
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        trailing: AnyView? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if title != nil || trailing != nil {
                HStack {
                    if let title = title {
                        Text(title)
                            .font(.sectionTitle)
                            .foregroundStyle(Color.textPrimary)
                    }
                    Spacer()
                    if let trailing = trailing { trailing }
                }
            }
            content()
        }
        .padding(Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .cardShadow()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SectionCard(title: "基本信息") {
            VStack(spacing: 12) {
                HStack {
                    Text("名称").foregroundStyle(Color.textSecondary)
                    Spacer()
                    Text("苹果 Apple")
                }
                HStack {
                    Text("代码").foregroundStyle(Color.textSecondary)
                    Spacer()
                    Text("AAPL")
                }
            }
        }

        SectionCard {
            Text("无标题的卡片，正文随便排")
        }
    }
    .padding()
    .background(Color.pageBg)
}
