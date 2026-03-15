import SwiftUI

struct PlaceholderTabView: View {
    let title: String
    let icon: String
    let description: String

    init(_ title: String, icon: String = "hammer.fill", description: String = "功能开发中...") {
        self.title = title
        self.icon = icon
        self.description = description
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(.themePrimary.opacity(0.4))

                Text(title)
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.textTertiary)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.pageBg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PlaceholderTabView("资产管理", icon: "chart.pie.fill")
}
