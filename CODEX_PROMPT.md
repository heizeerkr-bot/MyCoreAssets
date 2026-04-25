# Codex 开发指引：我的核心资产 App (iOS)

## 项目概述

"我的核心资产"是一款 iOS 个人投资管理工具，核心理念：只关注少量核心资产，低估买入、极度高估卖出，纪律化仓位管理。

---

## 技术栈（严格遵守）

- **平台**: iOS 17.0+
- **语言**: Swift 5
- **UI**: SwiftUI（纯 SwiftUI，不用 UIKit）
- **存储**: SwiftData（@Model 宏）
- **网络**: URLSession（不用第三方库）
- **依赖**: 零第三方依赖，纯 Apple 框架

---

## 已有 Demo 代码

以下文件已存在且**风格已确认**，新代码必须与其保持一致：

| 文件 | 状态 | 说明 |
|------|------|------|
| `Theme/AppTheme.swift` | **必须复用** | Design Tokens，不可修改 |
| `Models/MockData.swift` | 重写 | 模型需改为 SwiftData @Model，枚举保留 |
| `Views/Dashboard/DashboardView.swift` | 重构 | 接 SwiftData 真实数据 |
| `Views/Dashboard/PortfolioSummaryCard.swift` | 重构 | 接真实数据 |
| `Views/Dashboard/AssetCardView.swift` | 重构 | 接真实数据 |
| `Views/Detail/AssetDetailView.swift` | 重构 | 接真实数据 |
| `Views/Placeholder/PlaceholderTabView.swift` | 替换 | 替换为真实页面 |
| `MyCoreAssetsApp.swift` | 重构 | 加入 SwiftData container + 初始化判断 |

---

## 编码规范（必须遵守）

### 颜色/字体/间距

**禁止硬编码**。所有视觉值必须使用 `AppTheme.swift` 中定义的 token：

```swift
// ✅ 正确
.foregroundColor(.textPrimary)
.font(.sectionTitle)
.padding(Spacing.md)
.clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))

// ❌ 错误
.foregroundColor(Color(hex: "212121"))
.font(.system(size: 18, weight: .semibold))
.padding(16)
.clipShape(RoundedRectangle(cornerRadius: 16))
```

### Design Tokens 速查

```swift
// 颜色
Color.themePrimary    // #1E88E5 主题蓝
Color.themeDeep       // #1565C0 深蓝
Color.themeLight      // #E3F2FD 浅蓝背景
Color.pageBg          // #F8FBFF 页面背景
Color.cardBg          // #FFFFFF 卡片白
Color.textPrimary     // #212121
Color.textBody        // #424242
Color.textSecondary   // #757575
Color.textTertiary    // #9E9E9E

// 估值色（绿=低估=好，红=高估=坏）
Color.valuationDeepGreen  // #43A047 极度低估
Color.valuationLightGreen // #7CB342 比较低估
Color.valuationNeutral    // #78909C 合理
Color.valuationOrange     // #FB8C00 比较高估
Color.valuationRed        // #E53935 极度高估

// 字体
Font.superLargeTitle  // 36pt bold rounded（总资产）
Font.assetPrice       // 26pt semibold（价格）
Font.positionPercent  // 22pt bold rounded（仓位%）
Font.sectionTitle     // 18pt semibold（卡片标题）
Font.bodyText         // 16pt regular
Font.caption          // 14pt regular
Font.smallCaption     // 12pt regular

// 间距
Spacing.xs / .sm / .md / .lg / .xl  // 4 / 8 / 16 / 24 / 32
Spacing.cardPadding   // 16
Spacing.screenPadding // 20

// 圆角
CornerRadius.sm / .md / .lg / .xl  // 8 / 12 / 16 / 20
```

### 文件组织

```
MyCoreAssetsApp/
├── MyCoreAssetsApp.swift
├── Theme/
│   └── AppTheme.swift              ← 不改
├── Models/
│   ├── Asset.swift                 ← SwiftData @Model
│   ├── Transaction.swift           ← SwiftData @Model
│   ├── Portfolio.swift             ← SwiftData @Model
│   └── PresetAssets.swift          ← Top100 + 常关注 15 个 JSON
├── Services/
│   ├── PriceServiceProtocol.swift
│   ├── RealPriceService.swift           ← 行情获取（多源）
│   ├── MockPriceService.swift           ← Mock 降级
│   ├── ForexServiceProtocol.swift
│   ├── StaticForexService.swift         ← 静态汇率
│   ├── NotificationService.swift        ← V1.2 本地通知（4 种 AlertType）
│   ├── DividendServiceProtocol.swift    ← V1.3 分红/拆股事件 Protocol
│   └── RealDividendService.swift        ← V1.3 多市场分红检测 + Detector
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── PortfolioSummaryCard.swift
│   │   └── AssetCardView.swift
│   ├── Detail/
│   │   └── AssetDetailView.swift        ← V1.3 加 pendingEventsCard + 3-button bar
│   ├── Setup/
│   │   ├── InitialSetupView.swift       ← 4步向导（V1.1 后两步可跳过、第 2 步可零选）
│   │   └── AssetSearchView.swift
│   ├── Trade/
│   │   ├── BuyView.swift
│   │   ├── SellView.swift
│   │   ├── DividendRecordView.swift     ← V1.3 现金分红录入
│   │   ├── SplitRecordView.swift        ← V1.3 拆股录入
│   │   ├── BonusShareRecordView.swift   ← V1.3 送股录入（仅手动）
│   │   └── RightsRecordView.swift       ← V1.3 配股录入（仅手动）
│   ├── Asset/
│   │   └── AssetEditView.swift
│   ├── History/
│   │   └── TransactionHistoryView.swift
│   └── Settings/
│       └── SettingsView.swift           ← V1.2 加"通知" section
└── Assets.xcassets
```

### SwiftUI 模式

- 用 `@Query` 读取 SwiftData 数据
- 用 `@Environment(\.modelContext)` 写入
- NavigationStack（不用 NavigationView）
- 卡片统一样式：白底 + `CornerRadius.lg` 圆角 + `.shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)`
- 按钮用 `.buttonStyle(.plain)` 避免默认高亮闪烁

---

## 功能模块（按实现优先级）

> **当前状态（2026-04-25）：模块 1-13 全部已完成。** 模块 1-10 是 V1.0 主体；模块 11 是 V1.2 通知；模块 12-13 是 V1.3 分红/拆股相关。所有变更已上 main 分支。下一步是 UI 美化整体 pass（不是新功能）。

### 模块 1：SwiftData 数据层 ✅ 已完成

**Asset Model:**
```swift
@Model
class Asset {
    var id: UUID
    var name: String
    var symbol: String
    var market: String          // "CN" / "HK" / "US" / "BTC" / "FUND"
    var currency: String        // "CNY" / "HKD" / "USD"
    var idealBuyPrice: Double   // 原币种（0 = 未设置，V1.1 不再强制）
    var idealSellPrice: Double  // 原币种（0 = 未设置）
    var currentPrice: Double    // 原币种，自动更新
    var lastPriceUpdatedAt: Date?
    var holdingQuantity: Double
    var averageCost: Double     // 原币种
    var targetPositionRatio: Double  // 目标仓位 %（0 = 未设置）
    var maxPositionRatio: Double?    // 仓位上限 %，可选
    var isWatched: Bool
    var notes: String?
    var sortOrder: Int          // 默认排序顺序
    var alertStateJSON: String? // V1.2 通知防抖：[AlertType.rawValue: Date] JSON
    var lastDividendCheckAt: Date?  // V1.3 上次分红检测时间，24h 缓存

    // V1.1 计算属性（统一空值判断）
    var hasValuationConfigured: Bool  // idealBuy > 0 && idealSell > 0 && sell > buy
    var hasTargetPosition: Bool       // targetPositionRatio > 0
}
```

**Transaction Model:**
```swift
@Model
class Transaction {
    var id: UUID
    var asset: Asset?           // 关联
    var type: String            // V1.3 起：BUY/SELL/DIVIDEND/SPLIT/BONUS_SHARE/RIGHTS_ISSUE
    var price: Double           // 原币种（语义按 type 复用）
    var quantity: Double        // （语义按 type 复用）
    var occurredAt: Date
    var fxRateUsed: Double?     // 交易时汇率
    var cnyAmount: Double?      // 折算人民币（DIVIDEND 入账正、RIGHTS_ISSUE 流出负）
}
```

**V1.3 Transaction 字段语义复用表：**

| Type | price | quantity | cnyAmount | occurredAt |
|---|---|---|---|---|
| BUY | 买入价 | 买入数量 | 总金额（正） | 交易时间 |
| SELL | 卖出价 | 卖出数量 | 总金额（正） | 交易时间 |
| DIVIDEND | 每股股息 | ex-date 持仓数 | 总现金（正） | ex-date |
| SPLIT | 拆股比率（2.0=1:2） | 拆出净增量 | 0 | ex-date |
| BONUS_SHARE | 送股比率（0.2=10送2） | 送出股数 | 0 | ex-date |
| RIGHTS_ISSUE | 配股价 | 配股数 | 总现金（负） | 缴款日 |

**Portfolio Model:**
```swift
@Model
class Portfolio {
    var id: UUID
    var initialCashCNY: Double  // 默认 1,250,000
    var currentCashCNY: Double
    var lastGlobalRefreshAt: Date?
    var hasCompletedSetup: Bool // 是否完成初始化
}
```

### 模块 2：初始化向导（4 步） ✅ 已完成（V1.1 / V1.1.1 弹性化）

条件：`Portfolio.hasCompletedSetup == false` 时显示

1. **设置初始资金** — 大输入框 48pt，默认 1,250,000；唯一**必填**步骤
2. **添加核心资产** — 搜索框 + 常关注 15 个快捷标签；**可零选**——若不选任何资产，主按钮文案变为"完成初始化"，点击直接结束向导（跳过 step 3、4 因无 per-asset 字段）
3. **设置估值与仓位（可跳过）** — 逐个资产设置理想买入/卖出价 + 目标仓位；**所有字段非必填**，"已填则需自洽（卖出 > 买入）"。顶部蓝色提示卡告知可整步跳过
4. **初始化持仓（可跳过）** — 逐个资产录入平均成本 + 持有数量；按钮文案"完成初始化"，点击即结束（无字段=空走）

完成后 `hasCompletedSetup = true`，进入看板。

**V1.1 配套：未设估值/目标仓位的资产在看板/详情页显示弱引导（蓝色提示卡），点击 push 到 AssetEditView 让用户随时补完。**

### 模块 3：Dashboard 看板 ✅ 已完成

已有 Demo 代码，需改为从 SwiftData 读真实数据：
- 总览卡片：总资产（所有资产 CNY 市值 + 剩余现金）、盈亏、已投入、剩余现金
- 资产卡片只显示：资产名称+市场、当前价格（26pt大字号）、仓位(%)+目标仓位(%)+偏离提示、估值状态
- 不显示：代码(symbol)、成本、市值、盈亏（这些在详情页展示）
- 点击卡片进入详情页
- 资产列表：@Query 获取所有 Asset
- 排序功能：3 种排序方式（选择即生效并关闭弹窗，无需确认按钮）
  - 仓位从高到低
  - 仓位偏离目标从大到小（推荐）
  - 估值低估优先
- 刷新：进入看板自动刷新 + 每 10 秒自动刷新（静默） + 下拉/按钮手动刷新（失败提示）

### 模块 4：资产详情页 ✅ 已完成

已有 Demo 代码，需接真实数据并补充：
- 最近交易列表（取该资产最近 5 条 Transaction）
- "查看全部记录"链接
- 底部固定的买入/卖出按钮

### 模块 5：买入/卖出交易 ⬅️ 第二批从这里开始

**买入效果：**
- 创建 Transaction 记录
- `asset.holdingQuantity += quantity`
- `asset.averageCost = (原成本 × 原数量 + 新价格 × 新数量) / 新总数量`
- `portfolio.currentCashCNY -= price × quantity × fxRate`

**卖出效果：**
- 创建 Transaction 记录
- `asset.holdingQuantity -= quantity`
- 平均成本不变
- `portfolio.currentCashCNY += price × quantity × fxRate`

**交易页核心：仓位变化预览**
- 实时计算买入/卖出后仓位变化
- 超出上限时红色警示 + 二次确认

**按钮颜色语义：**
- 买入确认按钮：`Color.themePrimary`（蓝色）
- 卖出确认按钮：`Color.lossRed`（红色，语义化：卖出=红色）

### 模块 6：交易记录页

Tab "记录" 的主页面。

**页面结构：**
- NavigationStack，navigationTitle("交易记录")
- `@Query(sort: \Transaction.occurredAt, order: .reverse)` 获取全部交易
- 按日期分组显示（Section header = "2026-03-18" 格式）

**每条记录行布局：**
```
┌─────────────────────────────────────┐
│ 贵州茅台  [买入]          ¥168,000  │  ← 第一行：名称+标签+金额
│ ¥1,680 × 100              14:35   │  ← 第二行：价格×数量+时间
└─────────────────────────────────────┘
```
- 第一行左：资产名（bodyText） + 买入(绿标签)/卖出(红标签)
- 第一行右：金额（bodyText，原币种，千分位格式）
- 第二行左：价格 × 数量（caption，textSecondary）
- 第二行右：时间 HH:mm（caption，textTertiary）
- 买入标签色 = `Color.valuationDeepGreen`，卖出 = `Color.valuationRed`

**交互：**
- 点击行不跳转（MVP 不做编辑/删除交易）
- 行样式参考 AssetDetailView 中 AssetTransactionListView 的设计

**空状态：**
- 无交易时显示居中插图 + "暂无交易记录" + "前往看板查看资产详情" 按钮
- 按钮跳转到看板 Tab（Tab 0，让用户从看板进入资产详情页交易）

### 模块 7：资产管理页

Tab "资产" 的主页面。

**页面结构：**
- NavigationStack，navigationTitle("资产管理")
- `@Query(sort: \Asset.sortOrder)` 获取全部资产
- 右上角 toolbar `.navigationBarTrailing` 添加 "+" 按钮

**列表每行布局：**
```
┌─────────────────────────────────────┐
│ 🟢 贵州茅台     A股    目标 30%     │
└─────────────────────────────────────┘
```
- 左侧：估值色点（6pt 圆形，用 asset.valuationLevel.color）+ 资产名（bodyText）
- 中间：市场标签（smallCaption，浅灰背景小圆角）
- 右侧："目标 X%"（caption，textSecondary）

**添加资产（V1.1 简化）：**
- "+" 按钮 → `.sheet` 弹出 AssetSearchView（**复用** `Views/Setup/AssetSearchView.swift`）
- 选中资产后创建 Asset 对象（默认值：idealBuyPrice=0, idealSellPrice=0, targetPositionRatio=0）
- dismiss 后**不再强制 push 到 AssetEditView**；改为底部 toast "已添加 N 个资产，可点击列表项完善估值与仓位"
- 用户主动点列表行才进入 AssetEditView

**编辑资产：**
- 点击列表行 → NavigationLink push 到 AssetEditView

**AssetEditView**（新建 `Views/Asset/AssetEditView.swift`）：
- 接收 `Asset` 对象
- Form 布局，Section 分组：
  - Section "基本信息"：名称(只读 Text)、代码(只读)、市场(只读)
  - Section "估值设置"：理想买入价 TextField(.decimalPad)、理想卖出价 TextField(.decimalPad)
  - Section "仓位设置"：目标仓位% TextField(.decimalPad)、仓位上限% TextField(.decimalPad，可选）
  - Section "备注"：TextEditor 多行输入
- `navigationBarTitleDisplayMode(.inline)`，title = asset.name
- 修改直接写入 @Model（SwiftData 实时绑定）
- toolbar 右上角 "完成" 按钮：点击后 `modelContext.save()` + 显示 "已保存" toast + 1 秒后 dismiss
- toast 样式：底部居中，深色半透明背景圆角标签，带淡入淡出动画
- 所有 Section 加 `.listRowBackground(Color.cardBg)` 统一行背景

**删除资产：**
- 列表支持左滑删除 `.onDelete`
- 删除前弹出 `.confirmationDialog` 确认
- 删除后关联 Transaction 自动级联删除（@Relationship deleteRule .cascade）

### 模块 8：设置页

Tab "我的" 的主页面。

**页面结构：**
- NavigationStack，navigationTitle("我的")
- Form 布局，4 个 Section（资金管理 / 数据刷新 / 通知 / 关于）

**Section "资金管理"：**
- "初始资金" 行：左侧标题，右侧显示当前值（千分位格式）
- 点击弹出 `.alert` + TextField 修改 `portfolio.initialCashCNY`
- 修改后同步调整 `currentCashCNY`：`currentCashCNY += (新初始资金 - 旧初始资金)`

**Section "数据刷新"：**
- "刷新策略" 行：左侧标题，右侧 caption 灰色文字
- 显示说明："开盘时段每 5 分钟，其他时段每 1 小时"
- MVP 仅展示，不可修改

**Section "通知"（V1.2）：**
- "启用通知" 主开关：`@State` 直接绑定 `notificationsEnabled` + `.onChange` 触发 `handleMasterToggle`
- 首次开启时调 `NotificationService.requestAuthorization()` 请求系统权限
- 系统层未授予且主开关 ON 时显示警告行 "系统未授予通知权限 / 点击前往系统设置开启" → `UIApplication.openSettingsURLString`
- 已授予时显示 "发送测试通知" 按钮（调 `sendTestNotification()` 发一条预设通知验链路）
- footer 一段话说明：「价格跌破理想买入价、突破理想卖出价，或估值进入极度低估/极度高估时会推送提醒；同一资产同类提醒 24 小时内只发一次。」
- 4 种 AlertType 的子开关 UI **不暴露**（NotificationPrefs.isTypeEnabled 默认 true，底层保留以便未来恢复）

**Section "关于"：**
- "版本" 行：左侧 "版本"，右侧显示 `Bundle.main.infoDictionary` 中的 version + build
- 样式：右侧文字用 textSecondary

### 模块 9：价格刷新（真实 API + Mock 降级）✅ 已完成

接入免费行情 API 获取真实价格，单个失败时跳过，全部失败时降级 Mock。

**Services/ 目录文件：**

| 文件 | 说明 |
|------|------|
| `PriceServiceProtocol.swift` | Protocol 接口 + PriceServiceError 枚举 |
| `RealPriceService.swift` | 真实 API 实现（腾讯/Yahoo/Binance/天天基金） |
| `MockPriceService.swift` | Mock 降级备用（随机 ±2%） |
| `ForexServiceProtocol.swift` | 汇率 Protocol |
| `StaticForexService.swift` | 静态汇率（MVP 够用） |

**RealPriceService 按 market 分发到不同 API：**

| Market | 主源 | 兜底 | 价格提取 |
|--------|------|------|----------|
| CN | 腾讯行情 web.sqt.gtimg.cn | Yahoo（000333.SZ / 600519.SS） | 波浪号分隔 index 3，GB18030 优先解码 |
| HK | 腾讯行情 web.sqt.gtimg.cn | Yahoo（0700.HK） | 波浪号分隔 index 3，GB18030 优先解码 |
| US | Yahoo Finance v8 | — | JSON: `chart.result[0].meta.regularMarketPrice` |
| BTC | Binance data-api | — | JSON: `price` (string→Double) |
| FUND | 天天基金 fundgz | — | JSONP 提取 `gsz` |

**关键实现细节：**

1. **CN 市场 prefix 规则**：symbol 以 `6` 开头 → `"sh"`，以 `0` 或 `3` 开头 → `"sz"`
2. **腾讯行情编码**：返回内容按 GB18030 优先解码，回退 UTF-8，解决 A 股中文乱码导致价格解析失败
3. **HK 市场符号**：直接拼 `hk` 前缀，如 `00700` → `hk00700`
4. **Binance 加密货币**：symbol 自动拼接 `USDT` 后缀，如 `BTC` → `BTCUSDT`

**网络稳健性：**
- 统一请求配置：`timeout = 10s`、`cachePolicy = reloadIgnoringLocalAndRemoteCacheData`、`User-Agent`
- 重试：最多 2 次（取消场景重试一次）
- 请求执行方式：`dataTask + continuation`，减少 UI 任务取消对网络请求的连带中断
- URLSession 使用 static 单例，避免临时实例被 ARC 释放

**降级策略：**
- 单个资产 API 调用失败 → 跳过该资产，不更新价格，`print()` 记录错误
- 不阻塞其他资产更新（用 `TaskGroup` 并发请求）
- A 股/港股主源（腾讯）失败时自动尝试兜底源（Yahoo）
- 全部资产都失败 → 降级为 MockPriceService
- 手动刷新降级时弹提示"真实行情获取失败，已使用模拟价格"
- 自动刷新降级时静默，不打扰用户

**刷新触发机制（DashboardView）：**
- 统一入口：`triggerRefresh(source:showMessage:)` 管理所有刷新请求
- `@State refreshTask` 防重入，同一时刻只允许一个刷新任务
- `.refreshable` 不直接 await 网络，而是触发独立 Task，避免被 SwiftUI 取消
- 手动刷新（button/pull）：`showMessage=true`，失败时弹提示
- 自动刷新（auto-initial/auto-10s）：`showMessage=false`，静默执行
- 自动刷新通过 `.task(id: selectedTab)` 实现，仅在 `selectedTab == 0` 时运行

**取消错误识别（-999）：**
- `CancellationError`、`URLError.cancelled`、`NSError(NSURLErrorDomain, -999)` 统一识别为"请求被取消"
- 取消不按 API 失败处理，不触发 Mock 降级

**调试日志（DEBUG 模式）：**
- `[Dashboard]` 日志：刷新触发来源（button/pull/auto-initial/auto-10s）、刷新结果、更新资产数量
- `[PriceService]` 日志：请求 URL、HTTP 状态、取消/失败原因、解析结果

### 模块 10：空状态

- Dashboard 无资产时：插图 + "添加第一个核心资产" 按钮（跳转资产 Tab）
- 交易记录无数据时：插图 + "前往看板查看资产详情" 按钮（跳转看板 Tab 0）
- 资产管理无资产时：插图 + "添加第一个核心资产" 按钮（打开搜索 Sheet）

### 模块 11：本地通知 ✅ 已完成（V1.2）

价格刷新成功后判断是否跨越关键阈值，跨越则发本地通知。**无需后台刷新**，依赖前台/进看板 10s 自动刷新触发。

**Services/NotificationService.swift：**
- `final class NotificationService: NSObject, UNUserNotificationCenterDelegate`，单例 `.shared`
- 实现 `userNotificationCenter(_:willPresent:)` 返回 `[.banner, .list, .sound]` — 让前台也显示 banner
- 在 `App.init()` 中调 `NotificationService.shared.registerAsDelegate()` 注册 delegate
- API：`requestAuthorization() async -> Bool`、`scheduleIfAllowed(asset:type:)`、`sendTestNotification()`、`currentAuthorizationStatus()`

**AlertType（4 种）：**
- `crossedIdealBuy` — `oldPrice > A && newPrice <= A`
- `crossedIdealSell` — `oldPrice < B && newPrice >= B`
- `enteredDeepUnder` — `oldLevel != .deepUndervalued && newLevel == .deepUndervalued`
- `enteredDeepOver` — `oldLevel != .deepOvervalued && newLevel == .deepOvervalued`

**24h 防抖：** `Asset.alertStateJSON` 存 `[AlertType.rawValue: lastSentDate]`，同类 24h 内不重复触发。

**触发位置：** [DashboardView.swift](MyCoreAssetsApp/Views/Dashboard/DashboardView.swift) 的 `refreshPrices()` 在写入新 price 前后捕获 oldPrice/oldLevel，调 `evaluateAlerts(asset:oldPrice:newPrice:oldLevel:newLevel:)` 判断 4 种跨越。

**通知文案：** 见 [NotificationService.swift](MyCoreAssetsApp/Services/NotificationService.swift) 的 `title(for:asset:)` / `body(for:asset:)`。

### 模块 12：分红/拆股自动检测 ✅ 已完成（V1.3）

App 自动拉取每个资产的派息/拆股事件，与本地 Transaction 比对，将未录入的事件作为**候选**显示在资产详情页，用户一键确认才落库。**送股/配股不自动检测**，只通过详情页底部"更多"菜单手动录入。

**Services/DividendServiceProtocol.swift：**
- `struct DividendEvent { exDate, kind: .cashDividend/.split, amountPerShare, splitRatio }`
- `protocol DividendServiceProtocol { func fetchEvents(asset:since:) async throws -> [DividendEvent] }`

**Services/RealDividendService.swift（多市场分发 + Detector）：**

| Market | 主源 | 兜底 | 解析 |
|---|---|---|---|
| US | Yahoo `chart/{symbol}?events=div%2Csplit&range=5y` | — | `events.dividends`/`events.splits` |
| HK | Yahoo（symbol → `0000.HK`） | — | 同 US |
| CN | 东方财富 `datacenter-web/api/data/v1/get?reportName=RPT_LICO_FN_CPD` | 新浪 `CompanyBonusService.getCompanyBonus` | JSON 解析 EX_DIVIDEND_DATE / PRETAX_BONUS_RMB |
| FUND | 东方财富 `api.fund.eastmoney.com/f10/lsfh/?fundCode=...` | — | LSFHList 数组 |
| BTC | — | — | 返回空数组 |

复用 RealPriceService 的网络模板（10s timeout、UA 头、dataTask + continuation、-999 取消识别、最多 2 次重试）。

**DividendDetector.detectUnrecorded(asset:)：**
- 取 asset.transactions 里所有 BUY 的最早 occurredAt 作为 `since`（无 BUY 时用 `.distantPast`）
- 拉取该 since 起的事件
- 用 dayKey（YYYY-MM-DD UTC）与本地已记录的 DIVIDEND/SPLIT 交易去重
- 失败时返回 nil（UI 静默处理）

### 模块 13：分红/拆股/送股/配股录入 ✅ 已完成（V1.3）

**TradeType 扩展（[Models/MockData.swift](MyCoreAssetsApp/Models/MockData.swift)）：**

```swift
case dividend     = "DIVIDEND"      // 现金分红 → tintColor = .dividendGold
case split        = "SPLIT"         // 拆股       → tintColor = .splitBlue
case bonusShare   = "BONUS_SHARE"   // 送股       → tintColor = .bonusPurple
case rightsIssue  = "RIGHTS_ISSUE"  // 配股       → tintColor = .rightsTeal
```

**AppTheme 新增颜色：** `dividendGold (#FFA726)`、`splitBlue (#1E88E5)`、`bonusPurple (#8E24AA)`、`rightsTeal (#00897B)`。

**资产详情页改造（[AssetDetailView.swift](MyCoreAssetsApp/Views/Detail/AssetDetailView.swift)）：**

1. **`pendingEventsCard`**（位置：priceCard 之后、positionCard 之前）：
   - 金色边框 + 浅金背景；标题 "✨ 检测到 N 笔未记录事件"
   - 列出最多 3 条预览（"现金分红 YYYY-MM-DD / 每股 ¥X.XX"）；超过则显示 "还有 X 笔..."
   - 单条点击 → 弹对应 sheet 预填值（DividendRecordView / SplitRecordView）
   - "全部记录" 按钮 → 弹 `.alert` confirm dialog 显示**摘要**（事件数 / 现金净变化 / avgCost 模拟值 / qty 模拟值）→ 用户确认才批量写入
   - 检测时机：`.task(id: asset.id)` 进入页面时跑 `DividendDetector.detectUnrecorded`

2. **`bottomActionBar` 三按钮：** 买入 / 卖出 / 更多 Menu
   - 更多 Menu 项：分红 / 拆股 / 送股 / 配股 → 弹对应 sheet（无预填值，纯手动输入）

**4 个新录入 sheet（[Views/Trade/](MyCoreAssetsApp/Views/Trade/)）的应用公式：**

| Sheet | 公式 |
|---|---|
| DividendRecordView | `cash += perShare × shares × fxRate`；`averageCost -= perShare`（"摄薄成本"语义） |
| SplitRecordView | `holdingQuantity *= ratio`；`averageCost /= ratio`；现金不变 |
| BonusShareRecordView | `bonus = oldQ × ratio`；`newQ = oldQ + bonus`；`averageCost = oldCost × oldQ / newQ`；现金不变 |
| RightsRecordView | `averageCost = (oldCost × oldQ + price × newQ) / (oldQ + newQ)`；`holdingQuantity += newQ`；`cash -= price × newQ × fxRate` |

每 sheet 的 UI 风格：复用 BuyView 的 inputCard/previewCard/submitButton 模板，预览卡背景色用各自的金/蓝/紫/青 `.opacity(0.08)` 区分。

---

## 关键业务逻辑

### 估值 5 档计算

用户设定理想买入价 A 和理想卖出价 B，当前价 P，缓冲系数 15%：

```swift
func valuationLevel(currentPrice P: Double, idealBuy A: Double, idealSell B: Double) -> ValuationLevel {
    if P <= A * 0.85 { return .deepUndervalued }      // 极度低估
    if P <= A        { return .undervalued }            // 比较低估
    if P < B         { return .fair }                   // 合理
    if P < B * 1.15  { return .overvalued }             // 比较高估
    return .deepOvervalued                              // 极度高估
}
```

### 仓位计算

```swift
// 单资产仓位 = 该资产人民币市值 / 总资产人民币市值
let position = assetValueCNY / totalPortfolioValueCNY * 100

// 总资产 = 所有资产CNY市值之和 + 剩余现金
let totalValue = assets.map { $0.currentValueCNY }.reduce(0, +) + portfolio.currentCashCNY

// 单资产CNY市值 = currentPrice × holdingQuantity × fxRate
```

### 多币种处理

- 存储和展示用原币种（CNY/HKD/USD）
- 汇总统计统一换算为 CNY
- 汇率缓存 + 失败回退上次有效值

---

## 预置数据

### 常关注资产（15 个，初始化向导第 2 步快捷显示）

| 资产名称 | 市场 | 代码 | 币种 |
|---------|------|------|------|
| 贵州茅台 | A股 | 600519 | CNY |
| 美的集团 | A股 | 000333 | CNY |
| 腾讯控股 | 港股 | 00700 | HKD |
| 阿里巴巴-W | 港股 | 09988 | HKD |
| 比亚迪 | 港股 | 01211 | HKD |
| 苹果 Apple | 美股 | AAPL | USD |
| 特斯拉 Tesla | 美股 | TSLA | USD |
| 拼多多 | 美股 | PDD | USD |
| Google | 美股 | GOOGL | USD |
| 比特币 BTC | 虚拟货币 | BTC | USD |
| 富国沪深300指数增强A | 基金 | 100038 | CNY |
| 富国中证红利指数增强A | 基金 | 000478 | CNY |
| 华夏恒生ETF联接A | 基金 | 000071 | CNY |
| 博时标普500ETF联接A | 基金 | 050025 | CNY |
| 华安黄金ETF联接C | 基金 | 000217 | CNY |

另需预置 Top100 常用资产 JSON（搜索用）。

---

## 导航结构

Tab Bar 4 栏：
- **看板** (house.fill) → DashboardView
- **资产** (chart.pie.fill) → 资产管理列表
- **记录** (list.bullet.rectangle) → TransactionHistoryView
- **我的** (person.fill) → SettingsView

Tab 选中色：`Color.themePrimary`

---

## 注意事项

1. **AssetDetailView 底部已有买入/卖出按钮占位**（`// 模块 5 实现交易逻辑`），第二批需要接入真实交易 Sheet
2. **DashboardView 卡片点击已有 NavigationLink 到 AssetDetailView**，无需再改
3. **属性名避免与 Swift 关键字/全局函数冲突**（如 `max`，已踩坑，需用 `Swift.max()` 或换名）
2. **Sheet 弹窗不要用系统 List**（在半屏 sheet 里背景透明不可读），用自定义 VStack 布局
3. **Button 在自定义卡片里用 `.buttonStyle(.plain)`**，避免点击闪烁
4. **SwiftData @Model 类的属性不要用 let**，必须用 var
5. **金额格式化**统一用 NumberFormatter（千分位分隔）
6. **当前不做的事**（V2 边界）：智能操作建议（只显示仓位偏离数值）、云同步、筛选功能、Widget/锁屏、第三方导入（雪球等）、后台定期刷新（V1.2 依赖前台触发，覆盖日常场景）。**分红与摊薄成本** V1.3 已实现（自动检测 + 手动入口）
7. **Form 页面统一加 `.listRowBackground(Color.cardBg)`**（AssetEditView、SettingsView、AssetListManageView 的 List 行都需要），配合 `.scrollContentBackground(.hidden)` + `.background(Color.pageBg)` 保持主题一致
8. **BTC 价格格式化**：价格 < 1 时用 4 位小数，≥ 10000 时用整数，其余用 2 位小数（不按币种判断，按 market == BTC 判断）
