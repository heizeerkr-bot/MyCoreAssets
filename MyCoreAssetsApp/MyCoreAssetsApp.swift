import SwiftUI

@main
struct MyCoreAssetsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("看板")
                }
                .tag(0)

            PlaceholderTabView("资产管理", icon: "chart.pie.fill", description: "添加和管理核心资产")
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("资产")
                }
                .tag(1)

            PlaceholderTabView("交易记录", icon: "list.bullet.rectangle", description: "查看所有买卖记录")
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
    ContentView()
}
