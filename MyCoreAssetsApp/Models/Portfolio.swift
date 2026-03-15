import Foundation
import SwiftData

@Model
final class Portfolio {
    @Attribute(.unique) var id: UUID
    var initialCashCNY: Double
    var currentCashCNY: Double
    var lastGlobalRefreshAt: Date?
    var hasCompletedSetup: Bool

    init(
        id: UUID = UUID(),
        initialCashCNY: Double = 1_250_000,
        currentCashCNY: Double = 1_250_000,
        lastGlobalRefreshAt: Date? = nil,
        hasCompletedSetup: Bool = false
    ) {
        self.id = id
        self.initialCashCNY = initialCashCNY
        self.currentCashCNY = currentCashCNY
        self.lastGlobalRefreshAt = lastGlobalRefreshAt
        self.hasCompletedSetup = hasCompletedSetup
    }
}
