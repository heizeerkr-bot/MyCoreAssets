import SwiftData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]

    @State private var showingCashAlert = false
    @State private var cashText = ""

    @State private var notificationsEnabled = NotificationPrefs.masterEnabled
    @State private var systemAuthStatus: UNAuthorizationStatus = .notDetermined

    private var portfolio: Portfolio? {
        portfolios.first
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    private var systemAuthGranted: Bool {
        systemAuthStatus == .authorized || systemAuthStatus == .provisional || systemAuthStatus == .ephemeral
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

                notificationsSection

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
            .task { await refreshAuthStatus() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await refreshAuthStatus() }
                }
            }
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section {
            Toggle("启用通知", isOn: $notificationsEnabled)
                .font(.bodyText)
                .foregroundColor(.textPrimary)
                .onChange(of: notificationsEnabled) { _, newValue in
                    handleMasterToggle(newValue)
                }

            if notificationsEnabled && !systemAuthGranted {
                Button {
                    openSystemSettings()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.valuationOrange)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("系统未授予通知权限")
                                .font(.caption)
                                .foregroundColor(.textPrimary)
                            Text("点击前往系统设置开启")
                                .font(.smallCaption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.smallCaption)
                            .foregroundColor(.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }

            if notificationsEnabled && systemAuthGranted {
                Button {
                    NotificationService.shared.sendTestNotification()
                } label: {
                    HStack {
                        Image(systemName: "bell.badge")
                            .font(.caption)
                            .foregroundColor(.themePrimary)
                        Text("发送测试通知")
                            .font(.bodyText)
                            .foregroundColor(.themePrimary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("通知")
        } footer: {
            Text("价格跌破理想买入价、突破理想卖出价，或估值进入极度低估/极度高估时会推送提醒；同一资产同类提醒 24 小时内只发一次。")
                .font(.smallCaption)
                .foregroundColor(.textTertiary)
        }
        .listRowBackground(Color.cardBg)
    }

    private func handleMasterToggle(_ newValue: Bool) {
        NotificationPrefs.setMaster(newValue)
        guard newValue else { return }
        Task {
            _ = await NotificationService.shared.requestAuthorization()
            await refreshAuthStatus()
        }
    }

    private func refreshAuthStatus() async {
        let status = await NotificationService.shared.currentAuthorizationStatus()
        await MainActor.run {
            systemAuthStatus = status
        }
        // 主开关代表用户意图，不强制根据系统状态翻回；
        // 系统拒绝时通过下方"系统未授予权限"警告行引导用户去系统设置。
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
