# UI 设计规范：静水（V2）

> 本文档对齐 2026-04 新效果图（[`静水提交材料/最新前端效果图/`](静水提交材料/最新前端效果图/) 共 12 张），是 SwiftUI 实现的视觉真理来源。
> 上一代（V1.x）的 ASCII wireframe 设计稿已归档，本版以"组件 + 页面 spec + 真实效果图引用"为主。

---

## 1. 设计立意

- **仓位优先**：用户每天打开 3 次以上，主要决策是"要不要调仓"，所以仓位百分比与目标对比是看板焦点
- **浅蓝主题，深蓝点睛**：清新专业 + 适合金融场景。背景接近纯白带一抹蓝调；hero 卡用深蓝渐变 + 白色波纹装饰拉视觉重心
- **清晰度 > 信息密度**：宁愿少看一点。卡片大留白、字号偏大、状态色块化
- **隐私感**：高频开 App 的人会在公共场合查看，提供金额隐藏功能（`@AppStorage("privacyMode")` 全 App 联动）
- **零第三方依赖**：纯 SwiftUI + SF Symbols + Path 手绘装饰

---

## 2. Design Tokens

> 全部已落到 [`MyCoreAssetsApp/Theme/AppTheme.swift`](MyCoreAssetsApp/Theme/AppTheme.swift)，禁止硬编码。

### 2.1 颜色

| Token | Hex | 用途 |
|---|---|---|
| `themePrimary` | #1E88E5 | 主题蓝（按钮 / Tab 选中 / 链接 / 进度条填充） |
| `themeDeep` | #1565C0 | 深蓝（hero 卡渐变起点） |
| `themeLight` | #E3F2FD | 浅蓝（次级背景 / 标签 / 进度条底色） |
| `pageBg` | #F8FBFF | 页面背景（极浅蓝白） |
| `cardBg` | #FFFFFF | 卡片背景 |
| `divider` | #E0E0E0 | 分隔线 |
| `textPrimary` / `textBody` / `textSecondary` / `textTertiary` | #212121 / #424242 / #757575 / #9E9E9E | 4 级文本 |
| `valuationDeepGreen` / `valuationLightGreen` / `valuationNeutral` / `valuationOrange` / `valuationRed` | #43A047 / #7CB342 / #78909C / #FB8C00 / #E53935 | 估值 5 档色 |
| `profitGreen` / `lossRed` | #43A047 / #E53935 | 涨跌色（涨绿跌红，与 A 股惯例反向，但与全球理财 App 一致） |
| `dividendGold` / `splitBlue` / `bonusPurple` / `rightsTeal` | #FFA726 / #1E88E5 / #8E24AA / #00897B | 4 种公司行动色 |
| `targetMarker` | #FFA726 | 进度条目标位置 marker（橙黄） |
| `positionBarTrack` | = themeLight | 进度条轨道底色 |
| `heroWaveFill` / `heroWaveStroke` | white α 0.12 / α 0.18 | 深色 hero 卡白色波纹装饰 |
| `heroLightWave` | themePrimary α 0.08 | 浅色 hero 卡蓝色装饰 |

### 2.2 渐变（V2 新增）

```swift
LinearGradient.heroBlue   // themeDeep → themePrimary，topLeading → bottomTrailing
LinearGradient.heroLight  // cardBg → themeLight α 0.55
```

### 2.3 字号

| Token | 大小 / 字重 / 设计 | 用途 |
|---|---|---|
| `heroAmount` | 36 bold rounded | 看板/详情/资产管理 hero 卡大数字 |
| `heroAmountLarge` | 44 bold rounded | 详情页价格 |
| `superLargeTitle` | 36 bold rounded | （旧值，保留兼容） |
| `assetPrice` | 26 semibold | 资产卡片当前价格 |
| `positionPctLg` | 32 semibold rounded | 详情页仓位百分比 |
| `positionPercent` | 22 bold rounded | 卡片仓位百分比 |
| `sectionTitle` | 18 semibold | 卡片标题 |
| `bodyText` / `caption` / `smallCaption` | 16 / 14 / 12 regular | 正文 / 次要 / 辅助 |

### 2.4 间距 / 圆角 / 阴影

```swift
Spacing  // xs=4, sm=8, md=16, lg=24, xl=32, cardPadding=16, screenPadding=20
CornerRadius  // sm=8, md=12, lg=16, xl=20, xxl=24 (hero), pill=999
```

阴影统一 helper：`.cardShadow()` → `Color.black.opacity(0.04), radius: 8, x:0, y:2`

### 2.5 隐私模式

```swift
@AppStorage(PrivacyMode.storageKey) var isPrivacy = false
"¥1,234".maskedIfPrivacy(isPrivacy)  // → "¥1,234" 或 "••••••"
```

---

## 3. 共用组件库

> 位置：[`MyCoreAssetsApp/Views/Components/`](MyCoreAssetsApp/Views/Components/)。每个组件附带 SwiftUI Preview。

### 3.1 `HeroCard`

深蓝/浅色 hero 容器，右上角白色波纹装饰（贝塞尔曲线 Path）。

```swift
HeroCard(style: .deep) {  // 看板/详情用
    VStack(alignment: .leading) { ... }
}

HeroCard(style: .light) { // 资产管理目标配置 / 设置 App 信息
    HStack { ... }
}
```

参考效果图：[`05`](静水提交材料/最新前端效果图/05-看板-核心资产.png) / [`07`](静水提交材料/最新前端效果图/07-资产管理.png) / [`08`](静水提交材料/最新前端效果图/08-资产详情-苹果.png) / [`11`](静水提交材料/最新前端效果图/11-我的.png)

### 3.2 `PositionBar`

横向进度条 + 当前填充 + 目标橙色 marker + 上限红色 marker（可选）。

```swift
PositionBar(current: 28.1, target: 25, max: 35, height: 6)
// 自动颜色：≥ max → 红，>+5% → 橙，±2% → 绿，正常 → 蓝
```

### 3.3 `ValuationGauge`

5 档彩色色条（绿→红渐变） + 三角形当前 marker + 段位文字。

```swift
ValuationGauge(level: .fair, idealBuy: 198, idealSell: 300, currentPrice: 255)
```

### 3.4 `SectionCard`

通用白底圆角分组容器，可选 title + trailing。

```swift
SectionCard(title: "持仓信息") {
    VStack { ... }
}
```

### 3.5 `CompactAssetRow`

紧凑横向资产卡片，左侧浅蓝色资产名色块 + 右侧多行信息（名+市场+估值+价格+进度条+偏离）。看板/资产管理通用。

参考效果图：[`05`](静水提交材料/最新前端效果图/05-看板-核心资产.png) / [`07`](静水提交材料/最新前端效果图/07-资产管理.png)

### 3.6 `BottomActionBar`

底部 sticky 按钮容器（白底 + 顶部 hairline）。配套两个按钮样式：

```swift
BottomActionBar {
    Button("上一步") {}.buttonStyle(SecondaryActionButtonStyle())
    Button("下一步") {}.buttonStyle(PrimaryActionButtonStyle())
}
```

### 3.7 `PrivacyEyeButton`

眼睛切换按钮，自动读写 `@AppStorage("privacyMode")`。`tint` 适配深底（white）/ 浅底（themePrimary）。

---

## 4. 页面规范

每页一节，给出效果图引用 + 关键尺寸 + 数据绑定。详细布局以效果图为视觉真理来源。

### 4.1 看板（DashboardView） — [`05`](静水提交材料/最新前端效果图/05-看板-核心资产.png) / [`06`](静水提交材料/最新前端效果图/06-看板-排序弹窗.png)

**结构（从上到下）：**
1. NavigationStack title「我的核心资产」
2. `HeroCard(style: .deep)`（PortfolioSummaryCard）
   - 第一行：「总资产」label + `PrivacyEyeButton(tint: .white)` + 右上「🔄」刷新
   - 第二行：`¥1,281,427`（`.heroAmount`，隐私态遮罩）
   - 第三行：「↗ +31,427 (+2.5%)」涨跌
   - 第四行：「已投入 ¥xxx / 剩余现金 ¥xxx」双列
   - 第五行：「更新时间 HH:mm」
3. Section header「核心资产 (N)」+ 右「排序」按钮
4. `CompactAssetRow` 列表（高度 ~110pt）
5. 底部空状态（无资产）：插图 + 「添加第一个核心资产」按钮跳资产 Tab

**排序弹窗：** `.sheet` 弹底部 BottomSheet（高度 ~280pt），3 选项 + 选中蓝色 ✓，点击即生效并 dismiss。

**刷新机制：** 进入立即刷新 + 每 10 秒自动 + 下拉/按钮手动（V1.0 已成）。

### 4.2 资产详情（AssetDetailView） — [`08`](静水提交材料/最新前端效果图/08-资产详情-苹果.png)

**导航栏：** 左 ← 返回，中资产名，右 `⋮` Menu（含：编辑 / 录入分红 / 录入拆股 / 录入送股 / 录入配股）。

**结构（从上到下）：**
1. `HeroCard(style: .deep)` 价格卡：
   - 「当前价格」+ `PrivacyEyeButton(tint: .white)`
   - `$255.92`（`.heroAmountLarge`）
   - 「AAPL · 美股」副标题
   - 「↗ 涨跌额 (涨跌%)」+ 「更新于 HH:mm 🔄」
2. `pendingEventsCard`（V1.3 候选事件，可见时金色 SectionCard）
3. `SectionCard(title: "仓位分析")`：
   - 「当前 X.X%」（`.positionPctLg`） + 右上「目标 X%」
   - `PositionBar` 单条进度条
   - 偏离提示行（蓝/绿/橙/红）
4. `SectionCard(title: "估值状态")`：
   - 标题 + 当前档位标签
   - `ValuationGauge`
   - 「理想买入 ¥A | 理想卖出 ¥B」
   - 未设估值时占位 + 「点击设置」链接
5. `SectionCard(title: "持仓信息")`：
   - 2x2 网格：持有数量 / 平均成本 / 当前市值 / 浮动盈亏
   - 浮动盈亏色 = profitGreen/lossRed
6. `SectionCard(title: "最近交易")`：5 条 + 「查看全部 N 条 →」
7. `BottomActionBar`：「买入」themePrimary / 「卖出」lossRed

### 4.3 初始化向导（InitialSetupView） — [`01`](静水提交材料/最新前端效果图/01-初始化向导-设置初始资金.png)-[`04`](静水提交材料/最新前端效果图/04-初始化向导-初始化持仓.png)

**通用容器：**
- 顶部：「← 初始化向导」+ 右「N/4」步数指示
- 进度圆点（4 实心/灰）下方
- 章节式标题：「N. 步骤名称」(24pt semibold)，可跳过的加「(可跳过)」
- 滚动正文
- `BottomActionBar`：「上一步 / 下一步」（最后一步「完成初始化」）

**Step 1 — 设置初始资金（[01](静水提交材料/最新前端效果图/01-初始化向导-设置初始资金.png)，必填）：**
- 「总资金（人民币）」label
- 大输入框白卡：「1,250,000」（`.heroAmount`，蓝色）
- 灰色提示「默认值：1,250,000」

**Step 2 — 添加核心资产（[02](静水提交材料/最新前端效果图/02-初始化向导-添加核心资产.png)，可零选）：**
- 「已选 N 个资产」+ 右「搜索添加」按钮（push AssetSearchView）
- 「常关注 15」标签
- 2 列卡片网格（每卡：资产名 + ⊕/✓ 切换）
- 零选时主按钮文案 → 「完成初始化」（V1.1.1 行为）

**Step 3 — 设置估值与仓位（[03](静水提交材料/最新前端效果图/03-初始化向导-设置估值与仓位.png)，可整步跳过）：**
- 副标题：「为每个核心资产设置估值区间和目标仓位」
- 单页白卡（**逐个资产翻页**，与用户决策一致）：
  - 资产名 · 代码
  - 4 字段：理想买入价 / 理想卖出价 / 目标仓位 % / 仓位上限 %
  - label 在左 / 输入框在右 / 单位（¥/%）后置
- 卡片下方：「上一个资产 / 下一个资产」翻页按钮

**Step 4 — 初始化持仓（[04](静水提交材料/最新前端效果图/04-初始化向导-初始化持仓.png)，可整步跳过）：**
- 副标题：「可直接跳过，后续也可在资产详情里继续录入」
- 单卡：资产名 + 持有数量 / 平均成本
- 「+ 添加资产」中途加入入口（push AssetSearchView）
- 主按钮：「完成初始化」

### 4.4 资产管理（AssetListManageView） — [`07`](静水提交材料/最新前端效果图/07-资产管理.png)

**结构：**
1. NavigationTitle「资产管理」+ 右上「+」toolbar
2. `HeroCard(style: .light)` 目标配置卡：
   - 「目标配置 ⓘ」标题 + 大数字 = `assets.map(\.targetPositionRatio).reduce(0, +)`
   - 100% → themePrimary，「总目标仓位 已配置完整」
   - <100% → textSecondary，「未配置 X%」
   - >100% → valuationOrange，「超配 X%」
3. `CompactAssetRow` 列表（同看板组件）
4. 左滑删除（含 confirmationDialog）
5. 「+」点击 → 弹 AssetSearchView sheet

### 4.5 资产编辑（AssetEditView） — [`09`](静水提交材料/最新前端效果图/09-资产编辑-苹果.png)

**结构：**
- 顶部「← 资产名」+ 右「完成」
- 4 个 SectionCard：
  1. **基本信息**：名称 / 代码 / 市场（只读，灰字右对齐）
  2. **估值设置**：理想买入价 / 理想卖出价（输入框右对齐 + 单位后置）
  3. **仓位设置**：目标仓位 % / 仓位上限 %
  4. **备注**：多行 TextEditor
- 完成 → `modelContext.save()` + 「已保存」toast + dismiss

### 4.6 交易记录（TransactionHistoryView） — [`10`](静水提交材料/最新前端效果图/10-交易记录.png)

**结构：**
1. NavigationTitle「交易记录」
2. 工具栏行：左「全部交易 ▼」类型筛选下拉（BUY/SELL/DIVIDEND/SPLIT/BONUS_SHARE/RIGHTS_ISSUE/全部）+ 右「N 笔」
3. 日期分组 section header（`textSecondary` 小字）
4. 每条交易卡片：
   - 第一行：资产名 + 交易类型标签（绿/红/金/蓝/紫/青）+ 金额（右）
   - 第二行：单价 × 数量 + 时间（HH:mm）
5. 空态：插图 + 「前往看板查看资产详情」按钮跳看板

### 4.7 设置（SettingsView） — [`11`](静水提交材料/最新前端效果图/11-我的.png)

**结构：**
1. NavigationTitle「我的」
2. `HeroCard(style: .light)` App 信息卡：
   - 左 56pt App icon + 「静水 / 长期资产管理」+ 右 `›`
   - 暂不点击进 About（V2.1 后）
3. `SectionCard("资金管理")`：「初始资金 ¥X,XXX,XXX」（点击 alert 修改）
4. `SectionCard("数据刷新")`：「刷新策略 / 开盘时段每 5 分钟，其他时段每 1 小时」（只读）
5. `SectionCard("通知")`（V1.2）：主开关 + footer 一段说明 + 测试通知按钮 + 系统未授权时的警告行
6. `SectionCard("关于")`：「版本 X.X.X (build)」

---

## 5. 交易录入 Sheet（Buy/Sell/Dividend/Split/Bonus/Rights）

6 个 sheet 共用模板：
- 顶部：✕ 关闭 + 标题 + 资产名
- 资产信息小卡：当前价 / 当前仓位 / 目标 / 警示提示（如已超目标）
- 输入区：大输入框（48pt 数字）若干字段
- 预览卡：成交金额 / 持仓变化 / 平均成本变化 / 现金变化 + 仓位变化 PositionBar
- 底部：「确认 X」`PrimaryActionButtonStyle()`（买/卖按色彩区分；分红=金；拆股=蓝；送股=紫；配股=青）

公式见 PRD 5.6.5。

---

## 6. 交互动效

- **隐私模式过渡**：`.transition(.opacity)` + `.animation(.easeInOut(duration: 0.18))`
- **卡片点击反馈**：`.scaleEffect(isPressed ? 0.98 : 1.0)` + spring
- **PositionBar 动画**：`.animation(.easeInOut(duration: 0.4), value: current)`
- **刷新按钮旋转**：`Image(systemName: "arrow.clockwise").rotationEffect(.degrees(isRotating ? 360 : 0)).animation(.linear(duration: 1).repeatCount(...), value: isRotating)`
- **页面转场**：`.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: ...)`

---

## 7. 关键流程

### 首次使用
启动 → 自动建 Portfolio → InitialSetupView Step 1（必填初始资金） → Step 2（可零选） → Step 3 (可跳过) → Step 4（可跳过）→ MainTabView 看板

### 日常使用
看板 → 排序按钮 → BottomSheet 选「仓位偏离从大到小」→ 点击需调仓的卡片 → 详情页看仓位/估值/持仓 → 决定操作 → 底部「买入/卖出」 → 确认 sheet → 返回看板

### 公司行动录入
进详情 → V1.3 自动检测候选 → 候选事件卡 → 单条点击预填 / 「全部记录」批量确认 → 落库  
或：详情页右上 ⋮ Menu → 选「录入分红/拆股/送股/配股」 → 手动 sheet → 确认

### 隐私模式
看板/详情 hero 卡眼睛 icon → 切换 `@AppStorage("privacyMode")` → 全 App 金额变 `••••••`，状态持久化

---

## 8. 实施进度

V2.0 UI 美化拆 5 个 PR：

| PR | 范围 |
|---|---|
| **V2.0.0** | AppTheme 扩展 + 7 共用组件 + 全局 PrivacyMode + UIDesign.md 重写（**当前 PR**） |
| V2.0.1 | DashboardView, PortfolioSummaryCard, AssetCardView→CompactAssetRow, AssetListManageView 加目标配置 hero, 排序底部 sheet |
| V2.0.2 | AssetDetailView 重做 + 6 个交易 sheet 视觉对齐 |
| V2.0.3 | InitialSetupView 4 步视觉重做（保留逐个翻页） |
| V2.0.4 | SettingsView + TransactionHistoryView + AssetEditView + PRD.md 更新 |

每版独立 commit + 模拟器烟测 + 效果图视觉 diff 后落地。

---

## 附：旧版 ASCII wireframe 处理

V1 旧 UIDesign.md 用了大量 ASCII box 描述布局（≈1600 行）。V2 重写后这些 wireframe 已被效果图 PNG 取代。如需回看 V1 设计意图，参考 git history 的 `cf3af78` 之前版本。
