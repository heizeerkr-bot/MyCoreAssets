import SwiftUI

// MARK: - Privacy Eye Button (V2.0)
// 看板 / 详情 hero 卡的金额隐藏切换按钮。
// 内部读写 @AppStorage("privacyMode")，全 App 联动。

struct PrivacyEyeButton: View {
    /// 图标颜色（适配深蓝/浅色 hero 卡）
    var tint: Color = .white

    @AppStorage(PrivacyMode.storageKey) private var isPrivacy = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isPrivacy.toggle()
            }
        } label: {
            Image(systemName: isPrivacy ? "eye.slash" : "eye")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(tint.opacity(0.85))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        HStack {
            Text("总资产")
                .foregroundStyle(.white)
            PrivacyEyeButton(tint: .white)
        }
        .padding()
        .background(LinearGradient.heroBlue)

        HStack {
            Text("初始资金")
                .foregroundStyle(Color.textPrimary)
            PrivacyEyeButton(tint: Color.themePrimary)
        }
        .padding()
        .background(Color.cardBg)
    }
    .padding()
    .background(Color.pageBg)
}
