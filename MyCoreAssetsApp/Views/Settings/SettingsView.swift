import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]

    @State private var showingCashAlert = false
    @State private var cashText = ""

    private var portfolio: Portfolio? {
        portfolios.first
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("资金管理") {
                    Button {
                        cashText = AppNumberFormat.wholeString(portfolio?.initialCashCNY ?? 0)
                        showingCashAlert = true
                    } label: {
                        HStack {
                            Text("初始资金")
                                .font(.bodyText)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("¥\(AppNumberFormat.wholeString(portfolio?.initialCashCNY ?? 0))")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.cardBg)

                Section("数据刷新") {
                    HStack {
                        Text("刷新策略")
                            .font(.bodyText)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("开盘时段每 5 分钟，其他时段每 1 小时")
                            .font(.smallCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .listRowBackground(Color.cardBg)

                Section("关于") {
                    HStack {
                        Text("版本")
                            .font(.bodyText)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text(versionText)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .listRowBackground(Color.cardBg)
            }
            .scrollContentBackground(.hidden)
            .background(Color.pageBg)
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .alert("修改初始资金", isPresented: $showingCashAlert) {
                TextField("请输入金额", text: $cashText)
                    .keyboardType(.decimalPad)
                Button("取消", role: .cancel) {}
                Button("确定") {
                    applyNewInitialCash()
                }
            } message: {
                Text("修改后会同步调整当前现金余额。")
            }
        }
    }

    private func applyNewInitialCash() {
        guard let portfolio, let newValue = parseNumber(cashText), newValue > 0 else { return }
        let oldInitial = portfolio.initialCashCNY
        let delta = newValue - oldInitial
        portfolio.initialCashCNY = newValue
        portfolio.currentCashCNY += delta
        try? modelContext.save()
    }

    private func parseNumber(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
