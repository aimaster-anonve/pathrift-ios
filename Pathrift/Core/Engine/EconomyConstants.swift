import Foundation

enum EconomyConstants {
    static let startingGold: Int = 300        // was 250 — better early placement options
    static let startingLives: Int = 8          // was 5 — more forgiving for new players

    static func goldRewardForWave(_ wave: Int) -> Int {
        let base = 55
        let waveBonus = min(wave * 3, 75)   // cap raised: 130 at wave 25+ (was 115 at wave 20+)
        return base + waveBonus
    }

    static func killGoldMultiplier(forCycle cycle: Int) -> Double {
        switch cycle {
        case 0, 1: return 1.00
        case 2:    return 0.90   // was 0.85
        case 3:    return 0.82   // was 0.75
        default:   return 0.72   // was 0.65
        }
    }

    enum TowerCost {
        static let bolt: Int    = 80           // cheaper to encourage building
        static let blast: Int   = 130
        static let frost: Int   = 100
        static let pierce: Int  = 130
        static let core: Int    = 180
        static let inferno: Int = 200
        static let tesla: Int   = 300
        static let nova: Int    = 500
    }

    enum EnemyGoldReward {
        static let runner: Int  = 6
        static let tank: Int    = 18
        static let healer: Int  = 14
        static let phantom: Int = 10
    }

    enum TowerSellRefund {
        static let manualPercent: Double   = 0.70
        static let riftForcedPercent: Double = 0.50
    }

    enum TowerUpgrade {
        static let baseCost: Int      = 80
        static let growthRate: Double = 1.45  // cost per level
    }
}
