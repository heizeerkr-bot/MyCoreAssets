import Foundation

struct PresetAsset: Identifiable, Hashable {
    let name: String
    let symbol: String
    let market: String
    let currency: String

    var id: String { "\(market)-\(symbol)" }
}

enum PresetAssets {
    static let watched15: [PresetAsset] = [
        PresetAsset(name: "贵州茅台", symbol: "600519", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "美的集团", symbol: "000333", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "腾讯控股", symbol: "00700", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "阿里巴巴-W", symbol: "09988", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "比亚迪", symbol: "01211", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "苹果 Apple", symbol: "AAPL", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "特斯拉 Tesla", symbol: "TSLA", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "拼多多", symbol: "PDD", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "Google", symbol: "GOOGL", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "比特币 BTC", symbol: "BTC", market: MarketCode.btc.rawValue, currency: "USD"),
        PresetAsset(name: "富国沪深300指数增强A", symbol: "100038", market: MarketCode.fund.rawValue, currency: "CNY"),
        PresetAsset(name: "富国中证红利指数增强A", symbol: "000478", market: MarketCode.fund.rawValue, currency: "CNY"),
        PresetAsset(name: "华夏恒生ETF联接A", symbol: "000071", market: MarketCode.fund.rawValue, currency: "CNY"),
        PresetAsset(name: "博时标普500ETF联接A", symbol: "050025", market: MarketCode.fund.rawValue, currency: "CNY"),
        PresetAsset(name: "华安黄金ETF联接C", symbol: "000217", market: MarketCode.fund.rawValue, currency: "CNY"),
    ]

    static let topAssets: [PresetAsset] = [
        PresetAsset(name: "宁德时代", symbol: "300750", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "招商银行", symbol: "600036", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "中国平安", symbol: "601318", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "五粮液", symbol: "000858", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "隆基绿能", symbol: "601012", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "药明康德", symbol: "603259", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "中国中免", symbol: "601888", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "海天味业", symbol: "603288", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "中国移动", symbol: "600941", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "中国海油", symbol: "600938", market: MarketCode.cn.rawValue, currency: "CNY"),
        PresetAsset(name: "建设银行", symbol: "00939", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "中国平安(港股)", symbol: "02318", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "小米集团-W", symbol: "01810", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "中国海洋石油", symbol: "00883", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "中国神华", symbol: "01088", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "中国移动(港股)", symbol: "00941", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "中芯国际", symbol: "00981", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "京东集团-SW", symbol: "09618", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "网易-S", symbol: "09999", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "微软 Microsoft", symbol: "MSFT", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "亚马逊 Amazon", symbol: "AMZN", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "英伟达 NVIDIA", symbol: "NVDA", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "Meta", symbol: "META", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "伯克希尔B", symbol: "BRK.B", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "可口可乐", symbol: "KO", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "强生", symbol: "JNJ", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "联合健康", symbol: "UNH", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "台积电ADR", symbol: "TSM", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "百度", symbol: "BIDU", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "理想汽车", symbol: "LI", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "以太坊 ETH", symbol: "ETH", market: MarketCode.btc.rawValue, currency: "USD"),
        PresetAsset(name: "纳斯达克100ETF", symbol: "QQQ", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "标普500ETF", symbol: "SPY", market: MarketCode.us.rawValue, currency: "USD"),
        PresetAsset(name: "恒生科技ETF", symbol: "3033", market: MarketCode.hk.rawValue, currency: "HKD"),
        PresetAsset(name: "易方达沪深300ETF联接A", symbol: "110020", market: MarketCode.fund.rawValue, currency: "CNY"),
        PresetAsset(name: "天弘中证红利低波动100", symbol: "008114", market: MarketCode.fund.rawValue, currency: "CNY"),
        PresetAsset(name: "易方达黄金ETF联接A", symbol: "000307", market: MarketCode.fund.rawValue, currency: "CNY"),
        PresetAsset(name: "华夏上证50ETF联接A", symbol: "001051", market: MarketCode.fund.rawValue, currency: "CNY"),
    ]

    static var searchPool: [PresetAsset] {
        Array(Set(watched15 + topAssets)).sorted { lhs, rhs in
            if lhs.market == rhs.market {
                return lhs.symbol < rhs.symbol
            }
            return lhs.market < rhs.market
        }
    }
}
