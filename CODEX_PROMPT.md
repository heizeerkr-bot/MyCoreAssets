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
Font.assetPrice       // 28pt semibold（价格）
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
│   ├── PriceService.swift          ← 行情获取
│   └── ForexService.swift          ← 汇率获取
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── PortfolioSummaryCard.swift
│   │   └── AssetCardView.swift
│   ├── Detail/
│   │   └── AssetDetailView.swift
│   ├── Setup/
│   │   ├── InitialSetupView.swift  ← 4步向导
│   │   └── AssetSearchView.swift
│   ├── Trade/
│   │   ├── BuyView.swift
│   │   └── SellView.swift
│   ├── Asset/
│   │   └── AssetEditView.swift
│   ├── History/
│   │   └── TransactionHistoryView.swift
│   └── Settings/
│       └── SettingsView.swift
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

### 模块 1：SwiftData 数据层

**Asset Model:**
```swift
@Model
class Asset {
    var id: UUID
    var name: String
    var symbol: String
    var market: String          // "CN" / "HK" / "US" / "BTC" / "FUND"
    var currency: String        // "CNY" / "HKD" / "USD"
    var idealBuyPrice: Double   // 原币种
    var idealSellPrice: Double  // 原币种
    var currentPrice: Double    // 原币种，自动更新
    var lastPriceUpdatedAt: Date?
    var holdingQuantity: Double
    var averageCost: Double     // 原币种
    var targetPositionRatio: Double  // 目标仓位 %
    var maxPositionRatio: Double?    // 仓位上限 %，可选
    var isWatched: Bool
    var notes: String?
    var sortOrder: Int          // 默认排序顺序
}
```

**Transaction Model:**
```swift
@Model
class Transaction {
    var id: UUID
    var asset: Asset?           // 关联
    var type: String            // "BUY" / "SELL"
    var price: Double           // 原币种
    var quantity: Double
    var occurredAt: Date
    var fxRateUsed: Double?     // 交易时汇率
    var cnyAmount: Double?      // 折算人民币
}
```

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

### 模块 2：初始化向导（4 步）

条件：`Portfolio.hasCompletedSetup == false` 时显示

1. **设置初始资金** — 大输入框 48pt，默认 1,250,000
2. **添加核心资产** — 搜索框 + 常关注 15 个快捷标签
3. **设置估值与仓位** — 逐个资产设置理想买入/卖出价 + 目标仓位
4. **初始化持仓**（可跳过）— 逐个资产录入平均成本 + 持有数量

完成后 `hasCompletedSetup = true`，进入看板。

### 模块 3：Dashboard 看板

已有 Demo 代码，需改为从 SwiftData 读真实数据：
- 总览卡片：总资产（所有资产 CNY 市值 + 剩余现金）
- 资产列表：@Query 获取所有 Asset
- 排序功能：4 种排序方式
- 下拉/按钮刷新价格

### 模块 4：资产详情页

已有 Demo 代码，需接真实数据并补充：
- 最近交易列表（取该资产最近 5 条 Transaction）
- "查看全部记录"链接
- 底部固定的买入/卖出按钮

### 模块 5：买入/卖出交易

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

### 模块 6：交易记录页

- 全部交易按时间倒序
- 区分买入（绿色标签）/ 卖出（红色标签）
- 展示：时间、资产名、价格、数量、金额

### 模块 7：资产管理页

- 资产列表（可添加/编辑/删除）
- 添加资产：搜索 + 常关注列表
- 编辑资产：理想买入/卖出价、目标仓位、仓位上限、备注

### 模块 8：设置页

- 修改初始资金
- 刷新策略（开盘 5 分钟 / 其他 1 小时）
- App 版本信息

### 模块 9：价格刷新

- URLSession 获取行情（先实现 1-2 个数据源适配器）
- 汇率服务（CNY/HKD/USD）
- 刷新策略：开盘每 5 分钟，非开盘每 1 小时
- 失败时提示错误 + 重试

### 模块 10：空状态

- Dashboard 无资产时：插图 + "添加第一个核心资产" 按钮
- 交易记录无数据时：插图 + "记录第一笔交易" 按钮

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

1. **属性名避免与 Swift 关键字/全局函数冲突**（如 `max`，已踩坑，需用 `Swift.max()` 或换名）
2. **Sheet 弹窗不要用系统 List**（在半屏 sheet 里背景透明不可读），用自定义 VStack 布局
3. **Button 在自定义卡片里用 `.buttonStyle(.plain)`**，避免点击闪烁
4. **SwiftData @Model 类的属性不要用 let**，必须用 var
5. **金额格式化**统一用 NumberFormatter（千分位分隔）
6. **MVP 阶段不做**：分红/摊薄成本、智能操作建议（只显示仓位偏离数值）、云同步、筛选功能
