import SwiftUI

struct AssetSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAssetIDs: Set<String>
    @State private var keyword = ""

    private var filteredAssets: [PresetAsset] {
        guard !keyword.isEmpty else { return PresetAssets.searchPool }
        return PresetAssets.searchPool.filter { asset in
            asset.name.localizedCaseInsensitiveContains(keyword)
                || asset.symbol.localizedCaseInsensitiveContains(keyword)
                || "\(asset.name)\(asset.symbol)".localizedCaseInsensitiveContains(keyword)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                TextField("搜索名称 / 代码", text: $keyword)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
                    .padding(Spacing.md)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(filteredAssets) { asset in
                            row(asset: asset)
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.md)
            .background(Color.pageBg)
            .navigationTitle("添加核心资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.bodyText)
                    .foregroundColor(.themePrimary)
                }
            }
        }
    }

    @ViewBuilder
    private func row(asset: PresetAsset) -> some View {
        let isSelected = selectedAssetIDs.contains(asset.id)
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(asset.name)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)
                HStack(spacing: Spacing.xs) {
                    Text(asset.symbol)
                        .font(.smallCaption)
                        .foregroundColor(.textSecondary)
                    Text("·")
                        .font(.smallCaption)
                        .foregroundColor(.textTertiary)
                    Text(MarketCode(rawValue: asset.market)?.displayName ?? asset.market)
                        .font(.smallCaption)
                        .foregroundColor(.textSecondary)
                }
            }
            Spacer()
            Button {
                toggle(asset: asset)
            } label: {
                Text(isSelected ? "已选择" : "添加")
                    .font(.caption)
                    .foregroundColor(isSelected ? .textSecondary : .themePrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(isSelected ? Color.themeLight : Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: Spacing.sm, x: 0, y: Spacing.xs)
    }

    private func toggle(asset: PresetAsset) {
        if selectedAssetIDs.contains(asset.id) {
            selectedAssetIDs.remove(asset.id)
        } else {
            selectedAssetIDs.insert(asset.id)
        }
    }
}

#Preview {
    @Previewable @State var ids: Set<String> = []
    AssetSearchView(selectedAssetIDs: $ids)
}
