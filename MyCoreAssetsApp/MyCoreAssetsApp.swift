import SwiftUI
import SwiftData

@main
struct MyCoreAssetsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentRootView()
        }
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self])
    }
}

struct ContentRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Portfolio.id) private var portfolios: [Portfolio]
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if let portfolio = portfolios.first {
                if portfolio.hasCompletedSetup {
                    MainTabView(selectedTab: $selectedTab)
                } else {
                    InitialSetupView(portfolio: portfolio)
                }
            } else {
                ProgressView()
                    .tint(.themePrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.pageBg)
            }
        }
        .onAppear {
            ensurePortfolioExists()
        }
        .onChange(of: portfolios.count) { _, _ in
            ensurePortfolioExists()
        }
    }

    private func ensurePortfolioExists() {
        guard portfolios.isEmpty else { return }
        modelContext.insert(Portfolio())
        try? modelContext.save()
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("看板")
                }
                .tag(0)

            PlaceholderTabView("资产管理", icon: "chart.pie.fill", description: "第一批先完成初始化、看板和详情页")
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("资产")
                }
                .tag(1)

            PlaceholderTabView("交易记录", icon: "list.bullet.rectangle", description: "第一批后续接入完整交易记录页")
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("记录")
                }
                .tag(2)

            PlaceholderTabView("设置", icon: "person.fill", description: "初始资金、刷新策略等")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(3)
        }
        .tint(.themePrimary)
    }
}

#Preview {
    ContentRootView()
        .modelContainer(for: [Portfolio.self, Asset.self, Transaction.self], inMemory: true)
}
