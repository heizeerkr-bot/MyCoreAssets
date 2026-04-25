import Foundation
import UserNotifications

enum AlertType: String, CaseIterable, Codable {
    case crossedIdealBuy   = "crossed_ideal_buy"
    case crossedIdealSell  = "crossed_ideal_sell"
    case enteredDeepUnder  = "entered_deep_under"
    case enteredDeepOver   = "entered_deep_over"

    var displayName: String {
        switch self {
        case .crossedIdealBuy:  return "跌破理想买入价"
        case .crossedIdealSell: return "突破理想卖出价"
        case .enteredDeepUnder: return "进入极度低估"
        case .enteredDeepOver:  return "进入极度高估"
        }
    }
}

enum NotificationPrefs {
    static let masterKey = "notifications.enabled"

    static func typeKey(_ type: AlertType) -> String {
        "notifications.type.\(type.rawValue)"
    }

    static var masterEnabled: Bool {
        UserDefaults.standard.object(forKey: masterKey) as? Bool ?? false
    }

    static func setMaster(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: masterKey)
    }

    static func isTypeEnabled(_ type: AlertType) -> Bool {
        UserDefaults.standard.object(forKey: typeKey(type)) as? Bool ?? true
    }

    static func setType(_ type: AlertType, enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: typeKey(type))
    }
}

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private override init() {
        super.init()
    }

    private let center = UNUserNotificationCenter.current()
    private let debounceInterval: TimeInterval = 24 * 60 * 60

    /// 在 App 启动时调用一次，确保前台收到通知也能显示 banner。
    func registerAsDelegate() {
        center.delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// 发送一条测试通知，用于验证完整链路。
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "静水 · 测试通知"
        content.body = "如果你看到这条通知，说明通知链路一切正常。实际触发时会附带资产名称、价格和跨越类型。"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-\(Int(Date.now.timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        center.add(request) { _ in }
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// 评估并触发通知，含 24h 同类防抖。
    /// - 调用方负责检测 oldPrice/newPrice + valuation level 跨越，再调用本方法。
    /// - 防抖记录写回 asset.alertStateJSON，调用方 save modelContext。
    func scheduleIfAllowed(asset: Asset, type: AlertType, now: Date = .now) {
        guard NotificationPrefs.masterEnabled else { return }
        guard NotificationPrefs.isTypeEnabled(type) else { return }

        var state = decodeState(asset.alertStateJSON)
        if let last = state[type.rawValue], now.timeIntervalSince(last) < debounceInterval {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title(for: type, asset: asset)
        content.body = body(for: type, asset: asset)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(asset.id.uuidString)-\(type.rawValue)-\(Int(now.timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        center.add(request) { _ in }

        state[type.rawValue] = now
        asset.alertStateJSON = encodeState(state)
    }

    private func title(for type: AlertType, asset: Asset) -> String {
        switch type {
        case .crossedIdealBuy:  return "\(asset.name) 已跌至理想买入价"
        case .crossedIdealSell: return "\(asset.name) 已涨至理想卖出价"
        case .enteredDeepUnder: return "\(asset.name) 进入极度低估"
        case .enteredDeepOver:  return "\(asset.name) 进入极度高估"
        }
    }

    private func body(for type: AlertType, asset: Asset) -> String {
        let priceText = "\(asset.currencySymbol)\(AppNumberFormat.priceString(asset.currentPrice, currency: asset.currency, market: asset.market))"
        switch type {
        case .crossedIdealBuy:
            return "当前 \(priceText)，已跌至或跌破你设置的理想买入价。"
        case .crossedIdealSell:
            return "当前 \(priceText)，已涨至或突破你设置的理想卖出价。"
        case .enteredDeepUnder:
            return "当前 \(priceText)，估值进入极度低估区间（≤ 理想买入价 × 0.85）。"
        case .enteredDeepOver:
            return "当前 \(priceText)，估值进入极度高估区间（≥ 理想卖出价 × 1.15）。"
        }
    }

    private func decodeState(_ json: String?) -> [String: Date] {
        guard let json, let data = json.data(using: .utf8) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return (try? decoder.decode([String: Date].self, from: data)) ?? [:]
    }

    private func encodeState(_ state: [String: Date]) -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(state) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
