import SwiftUI

// MARK: - Privacy Mode (V2.0)
// 全 App 金额隐藏开关。看板 hero 卡眼睛图标切换，状态持久化。
// 任何 View 内部使用：`@AppStorage(PrivacyMode.storageKey) var isPrivacy = false`

enum PrivacyMode {
    static let storageKey = "privacyMode"
    static let mask = "••••••"

    /// 切换全局隐私状态
    static func toggle() {
        let current = UserDefaults.standard.bool(forKey: storageKey)
        UserDefaults.standard.set(!current, forKey: storageKey)
    }

    /// 当前是否启用
    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: storageKey)
    }
}

extension String {
    /// 隐私模式下用 •••••• 替换，否则原样返回
    func maskedIfPrivacy(_ enabled: Bool) -> String {
        enabled ? PrivacyMode.mask : self
    }
}
